require 'logger'

require 'colorize'

module Wp2jekyll
  class MarkdownLink
    include DebugLogger

    RE = %r{((\!)?\[([^\n]*)\]\(\s*([^"\s]*?)\s*("([^"]*?)")?\)(\{.*?\})?)}
    #E = %r{12--2--[3------3-]-(   4--------4   5"6-------6"5-)7-{----}7-1}m
    attr_accessor :cap
    attr_accessor :link
    attr_accessor :title
    attr_accessor :is_img
    attr_accessor :tail
    
    # simple constructor
    def initialize(is_img: false, cap: '', link:, title: '', tail: '')
      @cap = cap
      @link = link
      @title = title
      @is_img = is_img
      @tail = tail
    end

    def to_s
      if @is_img
        # @@logger.info "![#{@cap}](#{@link})".cyan
        return "![#{@cap}](#{@link})"
      else # not image
        if @title.empty?
          return "[#{@cap}](#{@link})"
        else
          return "[#{@cap}](#{@link} \"#{title}\")"
        end
      end
    end
    
    def info
      "MarkdownLink: #{@is_img ? '!' : ''}[#{@cap.red}](#{@link.green} \"#{@title.blue}\")#{@tail.magenta}"
    end

    # @return
    #   - [nil] if failed
    #   - [MarkdownLink] if success
    def self.parse(str)
      if m = RE.match(str)
        o = self.new(
          is_img: ('!' == m[2]) ? true : false,
          cap: m[3] || '',
          link: '',
          title: m[6] || '',
          tail: m[7] || ''
        )
        @@logger.debug o.info

        return o
      end
      nil
    end

    # return [Array] of MarkdownLink
    def self.extract(str)
      li = []
      RE.scan(str).each do |m|
        li.append self.parse m[0]
      end
      return li
    end

    def test?(str)
      nil != RE.match(str)
    end

  end
end

