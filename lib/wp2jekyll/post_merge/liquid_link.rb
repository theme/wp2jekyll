require 'pathname'
require 'logger'
require 'colorize'

module Wp2jekyll

  class LiquidLink
    include DebugLogger

    RE = %r{(\{\{\s*\"(.*?)\"\s*(\|\s?(relative_url|absolute_url))?\s*\}\})}
    #E = %r{0---------1---1-----2-----3-------------------------32--------0}
    attr_accessor :path #1
    attr_accessor :jekyll_filter_url #2

    def initialize(str)
      if m = RE.match(str)
        @path = m[1] || ''
        @jekyll_filter_url = m[2] || ''
        @@logger.debug "LiquidLink #{m[0]}".green
        return true
      end
      false
    end

    # return [Array] with items: [0:whole_jekyll_link, 1:url, 2:url_filter_part, 3: url_filter]
    def self.extract(str)
      RE.scan str
    end

    def self.test?(str)
      nil != RE.match(str)
    end

    def change_path_to!(to_path)
      p = Pathname.new(@path)
      new_p = Pathname.new(File.join(to_path, p.basename))
      @path = new_p.to_s
    end

    def to_s(filter = '')
      if !filter.is_empty?
        "{{ \"#{@path}\" | #{filter} }}"
      elsif !@jekyll_filter_url.is_empty?
        "{{ \"#{@path}\" | #{@jekyll_filter_url} }}"
      else
        "{{ \"#{@path}\" }}"
      end
    end

  end
end
