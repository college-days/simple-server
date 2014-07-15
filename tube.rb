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

    REASONS = {
      200 => "OK",
      404 => "Not found"
    }
    
    def send_response(env)
      status, headers, body = @app.call(env)
      reason = REASONS[status]
      
      @socket.write "HTTP/1.1 #{status} #{reason}\r\n"
      headers.each_pair do |key, value|
        @socket.write "#{key}: #{value}\r\n"
      end
      @socket.write "\r\n"
      body.each do |chunck|
        @socket.write chunck
      end
      if body.respond_to? :close
        puts "body respond to close method"
        body.close
      else
        puts "body can not respond to close method"
      end
      self.close
    end

    def close
      @socket.close
    end
  end

  class Builder
    attr_reader :app
    def run(app)
      @app = app
    end
    
    # static method
    def self.parse_file(file)
      content = File.read(file)
      builder = self.new
      # 将config.ru中得内容读入，并且有最后一句就是run App.new实际就是执行了自己的run方法，把App.new当做参数传入
      builder.instance_eval(content)
      builder.app
    end
  end
end

app = Tube::Builder.parse_file("./config.ru")
server = Tube.new(3000, app)
puts "Plugging tube into port 3000"
server.start
