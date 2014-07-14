# -*- coding: utf-8 -*-
require "socket"
require "http/parser"
require "stringio"

class Tube
  def initialize(port, app)
    @server = TCPServer.new(port)
    @app = app
  end
  
  def start
    loop do
      socket = @server.accept
      connection = Connection.new(socket, @app)
      connection.process
    end  
  end

  class Connection
    def initialize(socket, app)
      @socket = socket
      @parser = Http::Parser.new(self)
      @app = app
    end

    def process
      # 参考parser_demo，可以知道必须要等请求数据用<<往parser中写入完成以后才会触发对应的on_message_complete回调
      until @socket.closed? || @socket.eof?
        data = @socket.readpartial(1024)
        puts data
        @parser << data
      end
    end

    def on_message_complete
      puts "#{@parser.http_method}, #{@parser.request_url}"
      puts "  " + @parser.headers.inspect
      puts

      env = {}
      @parser.headers.each_pair do |key, value|
        # User-Agent => HTTP_USER_AGENT
        # Host => HTTP_HOST
        # Connection => HTTP_CONNECTION
        name = "HTTP_" + key.upcase.tr("-", "_")
        env[name] = value
      end
      env["PATH_INFO"] = @parser.request_url
      env["REQUEST_METHOD"] = @parser.http_method
      env["rake.input"] = StringIO.new
      
      self.send_response env
    end

    def send_response(env)
      status, headers, body = @app.call(env)
      
      @socket.write "HTTP/1.1 200 OK \r\n"
      @socket.write "\r\n"
      # just follow the ruby code style guide and the #@ beside problem we use #<whitespace> to comment a single line
      # or just this also works fine
      # @socket.write "HTTP/1.1 200 OK \n"
      @socket.write "hello\n"
      self.close
    end

    def close
      @socket.close
    end
  end

end

class App
  def call(env)
    message = "Hello from the tube. \n"
    [
      200,
      {
        'Content-Type' => 'text/plain',
        'Content-Length' => message.size.to_s
      },
      [message]
    ]
  end
end

app = App.new
server = Tube.new(3000, app)
puts "Plugging tube into port 3000"
server.start
