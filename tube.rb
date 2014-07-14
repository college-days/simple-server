# -*- coding: utf-8 -*-
require "socket"
require "http/parser"

class Tube
  def initialize(port)
    @server = TCPServer.new(port)
  end
  
  def start
    loop do
      socket = @server.accept
      connection = Connection.new(socket)
      connection.process
    end  
  end

  class Connection
    def initialize(socket)
      @socket = socket
      @parser = Http::Parser.new(self)
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
      
      self.send_response
    end

    def send_response
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

server = Tube.new(3000)
puts "Plugging tube into port 3000"
server.start
