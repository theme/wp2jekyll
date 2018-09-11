
require 'logger'

require 'colorize'

module Wp2jekyll

  # Used to cut Wordpress post into interleaved Code | Text list. ( for other processing )
  class CodeSegmenter
    include DebugLogger
    
    RE = %r{([ \t\r\f]*\[code.*?\](.*?)\[/code\])}m
    attr_accessor :li

    def initialize( txt = '')
      @@logger = Logger.new(STDERR)
      @@logger.level = Logger::DEBUG

      @li = []
      if !txt.empty?
        parse(txt)
      end
    end

    def parse(txt)
      # @@logger.debug "CodeSegmenter.parse << #{txt}".red
      @li.clear
      pos = 0
      while m = RE.match(txt, pos) do
        text = txt[pos .. m.begin(0) -1]
        @li.append({:text => text, :rage => [pos, m.begin(0)-1]}) if !text.empty?
        # @@logger.debug "text #{text}".red

        code = txt[m.begin(0) .. m.end(0)-1]
        @li.append({:code => code, :rage => [m.begin(0), m.end(0)-1]}) if !code.empty?
        # @@logger.debug "code end-1 = #{m.end(0)-1} #{code}".red

        pos = m.end(0)
      end

      @li.append({:text => txt[pos .. -1], :rage => [pos, -1]}) if pos < (txt.length - 1)
      # @@logger.debug "final text pos = #{pos } #{txt[pos .. -1]}".red

      @li
    end

    def join
      @li.map {|o| o[:text] || o[:code] }.join
    end
  end
  
end

