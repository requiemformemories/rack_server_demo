require_relative 'server'

class SimpleServerHandler
  def self.run(app, **options)
    # 一切從簡，先不處理 environment, pid, AccessLog, config, etc.
    @server = SimpleServer.new(app, server_name: options[:Host], port: options[:Port])
    @server.start
  end
end

module Rack::Handler
  def self.default(options = {})
    SimpleServerHandler
  end
end
