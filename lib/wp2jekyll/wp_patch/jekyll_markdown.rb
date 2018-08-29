require 'fileutils'
require 'cgi'
require 'uri'
require 'logger'

module Wp2jekyll
  
  class JekyllMarkdown
    attr_accessor :yaml_front_matter_str
    attr_accessor :body_str
    attr_reader :fp
    def initialize(fp = '')
      @logger = Logger.new(STDERR)
      # @logger.level = Logger::INFO
      @logger.level = Logger::DEBUG
      # DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
      
      @fp = fp # file path
      
      if File.exist?(@fp)
        split_fulltxt(File.read(@fp))
      end
    end

    def split_fulltxt(txt)
      m = /(^(---)?.*?---)?(.*)/m.match(txt) # TODO understand yaml format
      @yaml_front_matter_str  = m[1] || ''
      @body_str = m[3] || ''
    end

    # Returns true if the YAML front matter is present.
    def has_yaml_header?(file)
      # !! <---- change 0 to true
      !!(File.open(file, "rb", &:readline) =~ %r!\A---\s*\r?\n!)
    rescue EOFError
      false
    end

    # search link that contains img_fn, replace its path with provided path
    def relink_image(img_fn, relative_path)

      tmp_s = @body_str
      # scan normal markdown link
      @body_str.scan(MarkdownLink::RE).each do |m|
        mdlk = MarkdownLink.new(m[0])
        if mdlk.link.include?(img_fn)
          mdlk.link = File.join(relative_path, img_fn)
          tmp_s.gsub!(m[0], mdlk.to_s)
        end
      end

      # scan jekyll filtered markdown link
      tmp_s2 = tmp_s
      tmp_s.scan(JekyllLink::RE).each do |m|
        jklk = JekyllLink.new(m[0])
        if jklk.link.include?(img_fn)
          jklk.link.change_path_to!(relative_path)
          tmp_s2.gsub!(m[0], jklk.to_s)
        end
      end

      tmp_s2
    end

    # write to @fp file
    def write
      File.write(@fp, @yaml_front_matter_str + @body_str)
    end

    def info
      @logger.info "JekyllMarkdown: #{@fp}\n#{@yaml_front_matter_str}\n#{@body_str}".white
    end
  end

end

