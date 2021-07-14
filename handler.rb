require_relative 'server'

class SimpleServerHandler
  def self.run(app)
    @server = SimpleServer.new(app)
    @server.start
  end
end
