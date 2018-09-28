require 'pathname'
require 'logger'
require 'colorize'
require 'uri'

module Wp2jekyll

  class LiquidUrl
    include DebugLogger

    RE = %r{(\{\{\s*\"(.*?)\"\s*(\|\s?(relative_url|absolute_url))?\s*\}\})}
    #E = %r{0---------1---1-----2-----3-------------------------32--------0}
    attr_accessor :url #1
    attr_accessor :liquid_filter #2
    attr_reader :parsed_str # last string parsed

    def initialize(url:, liquid_filter: 'relative_url', parsed_str: nil)
      @url = URI(url)
      @liquid_filter = liquid_filter
      @parsed_str = parsed_str
    end

    def to_s
      if (nil == @liquid_filter) || @liquid_filter.empty?
        @url.to_s
      else
        "{{ \"#{@url.to_s}\" | #{@liquid_filter} }}"
      end
    end

    def info
      "LiquidUrl #{to_s}"
    end

    # @return
    #   - [nil] if failed
    #   - [LiquidUrl] if success
    def self.parse(str)
      if m = RE.match(str)
        o = self.new(
          url: m[2] || '',
          liquid_filter: m[4] || '',
          parsed_str: str
          )
          
        # @@logger.debug o.info.green

        return o
      end
      nil
    end

    # return [Array] of LiquidUrl
    def self.extract(str)
      li = []
      str.scan(RE).each do |m|
        lqlk = self.parse m[0]
        li.append lqlk if nil != lqlk
      end
      return li
    end

    def self.test?(str)
      nil != RE.match(str)
    end

    def change_path_to!(to_path)
      @url.path = to_path
    end

    def drop_scheme_host!
      @url.scheme = nil
      @url.host = ''
      @url.port = ''
      @url = URI.join(@url.to_s) # reduce // to /
    end

    def to_liquid_relative!
      drop_scheme_host!
      @liquid_filter = 'relative_url'
      self
    end

    def to_liquid_absolute!(scheme, host)
      drop_scheme_host!
      @liquid_filter = 'absolute_url'
      self
    end

  end
end
