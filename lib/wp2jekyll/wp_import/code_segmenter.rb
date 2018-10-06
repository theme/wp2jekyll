
require 'logger'

require 'colorize'

module Wp2jekyll

  # Used to cut Wordpress post into interleaved Code | Text list. ( for other processing )
  class CodeSegmenter
    include DebugLogger
    
    RE = %r{([ \t\r\f]*\[code.*?\](.*?)\[/code\])}m
    attr_accessor :li

    def initialize( txt = '')

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
        if 0 < m.begin(0) # some text here
          text = txt[pos .. m.begin(0) -1]
          @li.append({:text => text, :rage => [pos, m.begin(0)-1]})
          # @@logger.debug "text #{text}".red
        end

        if m.begin(0) < m.end(0) # some code here
          code = txt[m.begin(0) .. m.end(0)-1]
          @li.append({:code => code, :rage => [m.begin(0), m.end(0)-1]})
          # @@logger.debug "code end-1 = #{m.end(0)-1} #{code}".red
        end

        pos = m.end(0)
      end

      if pos < (txt.length - 1)
        @li.append({:text => txt[pos .. -1], :rage => [pos, -1]})
        # @@logger.debug "final text pos = #{pos } #{txt[pos .. -1]}".red
      end

      @li
    end

    def join
      @li.map {|o| o[:text] || o[:code] }.join
    end
  end
end

