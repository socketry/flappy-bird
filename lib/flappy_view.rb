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
		end
		
		def step(dt)
			@velocity += GRAVITY * dt
			@y += @velocity * dt
			
			if @y > HEIGHT
				@y = HEIGHT
				@velocity = 0.0
			end
		end
		
		def jump
			@velocity = 300.0
		end
		
		def render(builder)
			rotation = (@velocity / 20.0).clamp(-40.0, 40.0)
			rotate = "rotate(#{-rotation}deg)";
			
			builder.inline_tag(:div, class: 'bird', style: "left: #{@x}px; bottom: #{@y}px; width: #{@width}px; height: #{@height}px; transform: #{rotate};")
		end
	end
	
	class Pipe
		def initialize(x, y, offset = 100, width: 44, height: 700)
			@x = x
			@y = y
			@offset = offset
			
			@width = width
			@height = height
			@difficulty = 0.0
			@scored = false
		end
		
		attr_accessor :x
		attr_accessor :y
		attr_accessor :offset
		
		# Whether the bird has passed through the pipe.
		attr_accessor :scored
		
		def scaled_random
			rand(-1.0..1.0) * [@difficulty, 1.0].min
		end
		
		def reset!
			@x = WIDTH + (rand * 10)
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
		
		def upper_bounding_box
			BoundingBox.new(@x, self.top, @width, @height)
		end
		
		def lower_bounding_box
			BoundingBox.new(@x, self.bottom, @width, @height)
		end
		
		def intersect?(other)
			upper_bounding_box.intersect?(other) || lower_bounding_box.intersect?(other)
		end
		
		def render(builder)
			display = "display: none;" if @x > WIDTH
			
			builder.inline_tag(:div, class: 'pipe', style: "left: #{@x}px; bottom: #{self.bottom}px; width: #{@width}px; height: #{@height}px; #{display}")
			builder.inline_tag(:div, class: 'pipe', style: "left: #{@x}px; bottom: #{self.top}px; width: #{@width}px; height: #{@height}px; #{display}")
		end
	end
	
	def initialize(...)
		super
		
		@game = nil
		@bird = nil
		@pipes = nil
		
		# Defaults:
		@score = 0
		@prompt = "Press Space to Start"
	end
	
	def handle(event)
		case event[:type]
		when "keypress", "touchstart"
			detail = event[:detail]
			
			if @game.nil?
				start_game!
			elsif detail[:key] == " " || detail[:touch]
				@bird&.jump
			end
		end
	end
	
	def forward_keypress
		"live.forwardEvent(#{JSON.dump(@id)}, event, {value: event.target.value, key: event.key, touch: (event.type === 'touchstart')})"
	end
	
	def reset!
		@bird = Bird.new
		@pipes = [
			Pipe.new(WIDTH * 1/2, HEIGHT/2),
			Pipe.new(WIDTH * 2/2, HEIGHT/2)
		]
		@score = 0
	end
	
	def game_over!
		Highscore.connection_pool.with_connection do
			Highscore.create!(name: "Anonymous", score: @score)
		end
		
		@prompt = "Game Over! Score: #{@score}. Press Space to Restart"
		@game = nil
		
		self.update!
		
		raise Async::Stop
	end
	
	def start_game!
		if @game
			@game.stop
			@game = nil
		end
		
		self.reset!
		@game = self.run!
	end
	
	def step(dt)
		@bird.step(dt)
		@pipes.each do |pipe|
			pipe.step(dt)
			
			if pipe.right < @bird.x && !pipe.scored
				@score += 1
				pipe.scored = true
			end
			
			if pipe.intersect?(@bird)
				return game_over!
			end
		end
		
		if @bird.top < 0
			return game_over!
		end
	end
	
	def run!(dt = 1.0/20.0)
		Async do
			while true
				start_time = Async::Clock.now
				self.step(dt)
				self.update!
				
				duration = Async::Clock.now - start_time
				sleep(dt - duration) if duration < dt
			end
		end
	end
	
	def close
		if @game
			@game.stop
			@game = nil
		end
		
		super
	end
	
	def render(builder)
		builder.tag(:div, class: "flappy", tabIndex: 0, onKeyPress: forward_keypress, onTouchStart: forward_keypress) do
			if @game
				builder.inline_tag(:div, class: "score") do
					builder.text(@score)
				end
			else
				builder.inline_tag(:div, class: "prompt") do
					builder.text(@prompt)
					
					builder.inline_tag(:ol, class: "highscores") do
						Highscore.connection_pool.with_connection do
							Highscore.order(score: :desc).limit(10).each do |highscore|
								builder.inline_tag(:li) do
									builder.text("#{highscore.name}: #{highscore.score}")
								end
							end
						end
					end
				end
			end
			
			@bird&.render(builder)
			
			@pipes&.each do |pipe|
				pipe.render(builder)
			end
		end
	end
end
