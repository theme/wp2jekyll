require 'pathname'
require 'logger'
require 'colorize'
require 'uri'

module Wp2jekyll

  class LiquidUrl
    include DebugLogger

    RE = %r{(\{\{\s*\"(.*?)\"\s*(\|\s?(relative_url|absolute_url))?\s*\}\})}
    #E = %r{0---------1---1-----2-----3-------------------------32--------0}
    attr_accessor :uri #1
    attr_accessor :liquid_filter #2
    attr_accessor :parsed_str # last string parsed

    def initialize(uri:, liquid_filter: 'relative_url')
      @uri = URI(uri)
      @liquid_filter = liquid_filter
    end

    def to_s
      if (nil == @liquid_filter) || @liquid_filter.is_empty?
        @uri.to_s
      else
        "{{ \"#{@uri.path}\" | #{@liquid_filter} }}"
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
          uri: m[1] || '',
          liquid_filter: m[2] || '')

        o.parsed_str = str
        @@logger.debug info.green
        return o
      end
      nil
    end

    # return [Array] of LiquidUrl
    def self.extract(str)
      li = []
      RE.scan(str).each do |m|
        li.append self.parse m[0]
      end
      return li
    end

    def self.test?(str)
      nil != RE.match(str)
    end

    def change_path_to!(to_path)
      @uri.path = to_path
    end

    def drop_scheme_host!
      @uri.scheme = ''
      @uri.host = ''
    end

    def to_liquid_relative!
      drop_scheme_host!
      @liquid_filter = 'relative_url'
    end

    def to_liquid_absolute!(scheme, host)
      drop_scheme_host!
      @liquid_filter = 'absolute_url'
    end

  end
end
