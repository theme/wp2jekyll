require 'logger'

require 'colorize'

module Wp2jekyll
  class MarkdownLink
    RE = %r{((\!)?\[([^\n]*)\]\(\s*([^"\s]*?)\s*("([^"]*?)")?\)(\{.*?\})?)}
    #E = %r{12--2--[3------3-]-(   4--------4   5"6-------6"5-)7-{----}7-1}m
    attr_accessor :cap
    attr_accessor :title
    attr_accessor :link
    attr_accessor :is_img
    attr_accessor :re
    def initialize(str)
      @logger = Logger.new(STDERR)
      @logger.level = Logger::DEBUG
      if m = RE.match(str)
        @cap = m[3] || ''
        @link = m[4] || ''
        @title = m[6] || ''
        @is_img = ('!' == m[2]) ? true : false
        @tail = m[7] || ''
        @logger.debug "MarkdownLink: #{@is_img ? '!' : ''}[#{@cap.red}](#{@link.green} \"#{@title.blue}\")#{@tail.magenta}"
      end
    end

    # return [Array] with items: [0:whole_markdown_link, 1:!(image mark), 2:capture, 3:link, 4:"title", 5:title, 6:tail{}]
    def extract(str)
      RE.scan str
    end

    def test?(str)
      nil != RE.match(str)
    end

    def to_s
      if @is_img
        @logger.info "![#{@cap}](#{@link})".cyan
        return "![#{@cap}](#{@link})"
      else # not image
        if @title.empty?
          return "[#{@cap}](#{@link})"
        else
          return "[#{@cap}](#{@link} \"#{title}\")"
        end
      end
    end
  end
end

