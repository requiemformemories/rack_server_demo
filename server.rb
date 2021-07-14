require 'socket'

class SimpleServer
  def initialize(app, server_name, port, is_https: false)
    @app = app
    @server_name = server_name
    @port = port
    @is_https = is_https
  end

  def start
    server = TCPServer.new @server_name, @port

    while socket = server.accept
      # get http request
      request = socket.readpartial(2048)

      # parse request data
      path, query_string, method, headers, request_body = parse_request(request)
      env = generate_env(method, query_string, path, headers, request_body)

      # get response infomation from Rack App
      status, raw_headers, body = @app.call(env)

      # prepare response & close connection
      socket.write generate_response_header(status, raw_headers)
      body.each { |part| socket.write(part) }
      body.close
      socket.close
    end
  end

  def parse_request(request)
    method, raw_path, _http_version = request.lines[0].split
    path, query_string = parse_path(raw_path)

    [path, query_string, method, parse_headers(request), parse_body(request)]
  end

  def parse_path(raw_path)
    uri = URI.parse(raw_path)

    [uri.path, uri.query]
  end

  def parse_headers(request)
    request.lines[1..-1].reduce({}) do |headers, line|
      break headers if line == "\r\n"

      raw_header, value = line.split
      header = raw_header.gsub(':', '').gsub('-', '_').upcase
      headers.merge!("HTTP_#{header}" => value)
    end
  end

  def parse_body(request)
    lines = request.lines[1..-1]
    idx = lines.find_index("\r\n")

    lines[(idx + 1)..-1].join
  end

  def generate_env(method, query_string, path, headers, body)
    { 'REQUEST_METHOD'    => method,
      'SCRIPT_NAME'       => '',
      'PATH_INFO'       => path,
      'QUERY_STRING'      => query_string || '',
      'SERVER_NAME'       => @server_name,
      'SERVER_PORT'       => @port.to_s,
      'rack.version'      => [1, 3],
      'rack.input'        => StringIO.new(body.encode(Encoding::ASCII_8BIT)),
      'rack.errors'       => STDERR,
      'rack.multithread'  => false,
      'rack.multiprocess' => false,
      'rack.run_once'      => false,
      'rack.url_scheme'   => @is_https ? 'https' : 'http' }.merge(headers)
  end

  def generate_response_header(status, raw_headers)
    headers = raw_headers.transform_keys(&:downcase)
    content_type = headers['content-type'] || 'text/html'

    "HTTP/1.1 #{status}\r\n" +
    "Content-Type: #{content_type}\r\n" +
    "\r\n"
  end
end
