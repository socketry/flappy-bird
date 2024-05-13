require 'async/websocket/adapters/rails'

class GameController < ApplicationController
  RESOLVER = Live::Resolver.allow(FlappyView)

  def index
    @tag = FlappyView.new
  end

  skip_before_action :verify_authenticity_token, only: :live

  def live
    self.response = Async::WebSocket::Adapters::Rails.open(request) do |connection|
      Live::Page.new(RESOLVER).run(connection)
    end
  end
end
