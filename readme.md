# Flappy Bird on Rails

This is a simple Flappy Bird clone written in Ruby on Rails. It uses Falcon and Live to implement real-time interactivity.

![Flappy Bird Demo](media/Flappy%20Bird%20Demo.gif)

## Usage

To run the game, clone the repository and run the following commands:

```bash
$ bundle install
$ bundle exec rails server
```

Then, open your browser and navigate to `http://localhost:3000`.

## Overview

The game is implemented as a server-side rendered view. The game logic is fully implemented in [lib/flappy_view.rb](lib/flappy_view.rb).

The game uses a standard Rails controller, implemented in [app/controllers/game_controller.rb](app/controllers/game_controller.rb). The controller consists of two actions:

~~~ ruby
require 'async/websocket/adapters/rails'

class GameController < ApplicationController
  RESOLVER = Live::Resolver.allow(FlappyView)

  def index
    @view = FlappyView.new
  end

  skip_before_action :verify_authenticity_token, only: :live

  def live
    self.response = Async::WebSocket::Adapters::Rails.open(request) do |connection|
      Live::Page.new(RESOLVER).run(connection)
    end
  end
end
~~~

The `index` action instantiates the game view `FlappyView` which is then rendered by the view template [app/views/game/index.html.xrb](app/views/game/index.html.xrb). The `live` action is used to accept a WebSocket connection from the client browser.

When the client connects to the server, it binds the `<div class="live" data-class="FlappyView" id="...">` tag to a server side instance. User interactions generate events which are sent to the server, and the server can send HTML to the client to update the view. In addition, for things like sound effects, the server can send JavaScript to the client to execute.

The actual implementation of the game logic consists of a main game loop which updates the game physics at 30 FPS (frames per second), and then renders the update to the client browser. As the client browser may be running at something other than 30 FPS, we use CSS transforms with linear interpolation to smooth out the changes in position.

## Compatibility

Surprisingly, this game can run on any Rack 3 compatible server, including both Puma and Falcon. Rack 3 requires support for streaming requests and responses, which is sufficient to support WebSockets. The difference then, between servers, is how they choose to expose concurrency to the application. In the case of Puma, it is one thread per request, while Falcon uses one fiber per request.

## Presentation

This project was part of my RubyKaigi 2024 Keynote. The <a href="https://github.com/ioquatix/presentations/tree/main/2024">slides are available here</a>.

## See Also

- [Async](https://github.com/socketry/async) - The Async library for Ruby, which provides a foundation for scalable concurrency.
- [Async::HTTP](https://github.com/socketry/async-http) - The HTTP client and server library for Ruby, built on Async, supporting HTTP/1 and HTTP/2.
- [Falcon](https://github.com/socketry/falcon) - The Ruby web server used to run the game, built on Async.
- [Async::WebSocket] - The WebSocket library for Ruby, built on Async, supporting both HTTP/1 and HTTP/2 client and server WebSockets.
- [Live](https://github.com/socketry/live) - The library used to implement real-time interactivity, built on top of Async::WebSocket.
- [Live.js](https://github.com/socketry/live-js) - The JavaScript library used to interact with the server.
- [Lively](https://github.com/socketry/lively) - A single-file live programming environment for Ruby, which also uses Live for real-time interactivity. It has a multiplayer example of the Flappy Bird game, using a similar implementation.