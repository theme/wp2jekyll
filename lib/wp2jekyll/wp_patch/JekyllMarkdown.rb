require 'fileutils'
require 'cgi'
require 'uri'
require 'logger'

module Wp2jekyll
  
  class JekyllMarkdown
    attr_accessor :yaml_front_matter_str
    attr_accessor :body_str
    attr_accessor :body_segments # split post body into text\ code type segments
    attr_reader :fp
    def initialize(fp = '')
      @fp = fp # file path
      @logger = Logger.new(STDERR)
      # @logger.level = Logger::INFO
      @logger.level = Logger::DEBUG
      # DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
    end

    def split_fulltxt(txt)
      m = /(^(---)?.*?---)?(.*)/m.match(txt) #TODO understand yaml format
      @yaml_front_matter_str  = m[1] || ''
      @body_str = m[3] || ''
    end

    # (from: jekyll/utils.rb)
    # Returns true if the YAML front matter is present.
    def has_yaml_header?(file)
      # !! change 0 to true
      !!(File.open(file, "rb", &:readline) =~ %r!\A---\s*\r?\n!)
    rescue EOFError
      false
    end 

  end

end

