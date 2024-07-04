# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'live'

class FlappyView < Live::View
	WIDTH = 420
	HEIGHT = 640
	GRAVITY = -9.8 * 50.0
	
	class BoundingBox
		def initialize(x, y, width, height)
			@x = x
			@y = y
			@width = width
			@height = height
		end
		
		attr :x
		attr :y
		
		attr :width
		attr :height
		
		def right
			@x + @width
		end
		
		def top
			@y + @height
		end
		
		def center
			[@x + @width/2, @y + @height/2]
		end
		
		def intersect?(other)
			!(
				self.right < other.x ||
				self.x > other.right ||
				self.top < other.y ||
				self.y > other.top
			)
		end
		
		def to_s
			"#<#{self.class} (#{@x}, #{@y}, #{@width}, #{@height}>"
		end
	end
	
	class Bird < BoundingBox
		def initialize(x = 30, y = HEIGHT / 2, width: 34, height: 24)
			super(x, y, width, height)
			@velocity = 0.0
			@jumping = false
		end
		
		def step(dt)
			@velocity += GRAVITY * dt
			@y += @velocity * dt
			
			if @y > HEIGHT
				@y = HEIGHT
				@velocity = 0.0
			end
			
			if @jumping
				@jumping -= dt
				if @jumping < 0
					@jumping = false
				end
			end
		end
		
		def jump(extreme = false)
			@velocity = 300.0
			
			if extreme
				@jumping = 0.5
			end
		end
		
		def render(builder)
			rotation = (@velocity / 20.0).clamp(-40.0, 40.0)
			rotate = "rotate(#{-rotation}deg)";
			
			builder.inline_tag(:div, class: 'bird', style: "left: #{@x}px; bottom: #{@y}px; width: #{@width}px; height: #{@height}px; transform: #{rotate};")
			
			if @jumping
				center = self.center
				
				10.times do |i|
					angle = (360 / 10) * i
					id = "bird-#{self.__id__}-particle-#{i}"
					
					builder.inline_tag(:div, id: id, class: 'particle jump', style: "left: #{center[0]}px; bottom: #{center[1]}px; --rotation-angle: #{angle}deg;")
				end
			end
		end
	end

	class Gemstone < BoundingBox
		COLLECTED_AGE = 1.0
		
		def initialize(x, y, width: 148/2, height: 116/2)
			super(x - width/2, y - height/2, width, height)
			
			@collected = false
		end
		
		def collected?
			@collected != false
		end
		
		def step(dt)
			@x -= 100 * dt
			
			if @collected
				@collected -= dt
				
				if @collected < 0
					@collected = false
					yield if block_given?
				end
			end
		end
		
		def collect!
			@collected = COLLECTED_AGE
		end
		
		def render(builder)
			if @collected
				opacity = @collected / COLLECTED_AGE
			else
				opacity = 1.0
			end
			
			builder.inline_tag(:div, class: 'gemstone', style: "left: #{@x}px; bottom: #{@y}px; width: #{@width}px; height: #{@height}px; opacity: #{opacity};")
			
			# Add some particles:
			if @collected
				center = self.center
				
				10.times do |i|
					angle = (360 / 10) * i
					id = "gemstone-#{self.__id__}-particle-#{i}"
					
					builder.inline_tag(:div, id: id, class: 'particle bonus', style: "left: #{center[0]}px; bottom: #{center[1]}px; --rotation-angle: #{angle}deg;")
				end
			end
		end
	end

	class Pipe
		def initialize(x, y, offset = 100, random: 0, width: 44, height: 700)
			@x = x
			@y = y
			@offset = offset
			
			@width = width
			@height = height
			@difficulty = 0.0
			@scored = false
			
			@random = random
		end
		
		attr :x
		attr :y
		attr :offset
		
		# Whether the bird has passed through the pipe.
		attr_accessor :scored
		
		def scaled_random
			@random.rand(-1.0..1.0) * [@difficulty, 1.0].min
		end
		
		def reset!
			@x = WIDTH + (@random.rand * 10)
			@y = HEIGHT/2 + (HEIGHT/2 * scaled_random)
			
			if @offset > 50
				@offset -= (@difficulty * 10)
			end
			
			@difficulty += 0.1
			@scored = false
		end
		
		def step(dt)
			@x -= 100 * dt
			
			if self.right < 0
				reset!
				
				yield if block_given?
			end
		end
		
		def right
			@x + @width
		end
		
		def top
			@y + @offset
		end
		
		def bottom
			(@y - @offset) - @height
		end
		
		def center
			[@x + @width/2, @y]
		end
		
		def lower_bounding_box
			BoundingBox.new(@x, self.bottom, @width, @height)
		end
		
		def upper_bounding_box
			BoundingBox.new(@x, self.top, @width, @height)
		end
		
		def intersect?(other)
			lower_bounding_box.intersect?(other) || upper_bounding_box.intersect?(other)
		end
		
		def render(builder)
			display = "display: none;" if @x > WIDTH
			
			builder.inline_tag(:div, class: 'pipe', style: "left: #{@x}px; bottom: #{self.bottom}px; width: #{@width}px; height: #{@height}px; #{display}")
			builder.inline_tag(:div, class: 'pipe', style: "left: #{@x}px; bottom: #{self.top}px; width: #{@width}px; height: #{@height}px; #{display}")
		end
	end
	
	def initialize(*arguments, **options)
		super(*arguments, **options)
		
		@game = nil
		@bird = nil
		@pipes = nil
		@bonus = nil
		
		# Defaults:
		@score = 0
		@count = 0
		@prompt = "Press space or tap to start :)"
		
		@random = nil
	end
	
	attr :bird
	
	def close
		if @game
			@game.stop
			@game = nil
		end
		
		super
	end
	
	def jump
		if (extreme = rand > 0.5)
			play_sound("quack")
		end
		
		@bird&.jump(extreme)
	end
	
	def handle(event)
		case event[:type]
		when "keypress", "touchstart"
			detail = event[:detail]
			
			if @game.nil?
				self.start_game!
			elsif detail[:key] == " " || detail[:touch]
				self.jump
			end
		end
	end
	
	def forward_keypress
		"live.forwardEvent(#{JSON.dump(@id)}, event, {key: event.key})"
	end
	
	def reset!
		@bird = Bird.new
		@pipes = [
			Pipe.new(WIDTH + WIDTH * 1/2, HEIGHT/2, random: @random),
			Pipe.new(WIDTH + WIDTH * 2/2, HEIGHT/2, random: @random)
		]
		@bonus = nil
		@score = 0
		@count = 0
	end
	
	def play_sound(name)
		self.script(<<~JAVASCRIPT)
			if (!this.sounds) {
				this.sounds = {};
			}
			
			if (!this.sounds[#{JSON.dump(name)}]) {
				this.sounds[#{JSON.dump(name)}] = new Audio('/assets/#{name}.mp3');
			}
			
			this.sounds[#{JSON.dump(name)}].play();
		JAVASCRIPT
	end
	
	def play_music
		self.script(<<~JAVASCRIPT)
			if (!this.music) {
				this.music = new Audio('/assets/music.mp3');
				this.music.loop = true;
				this.music.play();
			}
		JAVASCRIPT
	end
	
	def stop_music
		self.script(<<~JAVASCRIPT)
			if (this.music) {
				this.music.pause();
				this.music = null;
			}
		JAVASCRIPT
	end
	
	def game_over!
		Console.info(self, "Player has died.")
		
		play_sound("death")
		stop_music
		
		Highscore.create!(name: ENV.fetch("PLAYER", "Anonymous"), score: @score)
		
		@prompt = "Game Over! Score: #{@score}. Press space or tap to restart."
		@game = nil
		
		self.update!
		
		raise Async::Stop
	end
	
	def preparing(message)
		@prompt = message
		self.update!
	end
	
	def start_game!(seed = 1)
		if @game
			@game.stop
			@game = nil
		end
		
		@random = Random.new(seed)
		
		self.reset!
		self.update!
		self.script("this.querySelector('.flappy').focus()")
		@game = self.run!
	end
	
	def step(dt)
		@bird.step(dt)
		@pipes.each do |pipe|
			pipe.step(dt) do
				# Pipe was reset:
				
				if @bonus.nil? and @count > 0 and (@count % 5).zero?
					@bonus = Gemstone.new(*pipe.center)
				end
			end
			
			if pipe.right < @bird.x && !pipe.scored
				@score += 1
				@count += 1
				
				pipe.scored = true
				
				if @count == 3
					play_music
				end
			end
			
			if pipe.intersect?(@bird)
				return game_over!
			end
		end
		
		@bonus&.step(dt) do
			@bonus = nil
		end
		
		if @bonus
			if !@bonus.collected? and @bonus.intersect?(@bird)
				play_sound("clink")
				@score = @score * 2
				@bonus.collect!
			elsif @bonus.right < 0
				@bonus = nil
			end
		end
		
		if @bird.top < 0
			return game_over!
		end
	end
	
	# If you change the delta time, you should also update the transform in the CSS so that the game runs at the correct speed.
	def run!(dt = 1.0/30.0)
		Async do
			start_time = Async::Clock.now
			
			while true
				self.step(dt)
				
				self.update!
				
				duration = Async::Clock.now - start_time
				if duration < dt
					sleep(dt - duration)
				else
					Console.info(self, "Running behind by #{duration - dt} seconds")
				end
				start_time = Async::Clock.now
			end
		end
	end
	
	def render(builder)
		builder.tag(:div, class: "flappy", tabIndex: 0, onKeyPress: forward_keypress, onTouchStart: forward_keypress) do
			if @game
				builder.inline_tag(:div, class: "score") do
					builder.text("Score: #{@score}")
				end
			else
				builder.inline_tag(:div, class: "prompt") do
					builder.text(@prompt)
					
					builder.inline_tag(:ol, class: "highscores") do
						Highscore.top10.each do |highscore|
							builder.inline_tag(:li) do
								builder.text("#{highscore.name}: #{highscore.score}")
							end
						end
					end
				end
			end
			
			@bird&.render(builder)
			
			@pipes&.each do |pipe|
				pipe.render(builder)
			end
			
			@bonus&.render(builder)
		end
	end
end
