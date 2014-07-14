# -*- coding: utf-8 -*-
require "http/parser"

class ParserDemo
  def initialize
    @parser = Http::Parser.new(self)
  end

  def on_message_complete
    puts "Method: " + @parser.http_method
    # puts "Path: " + @parser.request_path
    puts "Path: " + @parser.request_url
  end

  def parse
    # 用<<向parser里面写入请求数据，当写入完之后，也就是写入EOF标志之后就会触发on_message_complete方法，这种肯定是用了meta_programming的技巧了
    @parser << "GET / HTTP/1.1\r\n"
    @parser << "Host: localhost:3000\r\n"
    @parser << "Accept: */\r\n"
    @parser << "\r\n"
  end
end

ParserDemo.new.parse
