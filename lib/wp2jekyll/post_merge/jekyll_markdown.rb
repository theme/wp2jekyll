require 'fileutils'
require 'cgi'
require 'uri'
require 'logger'

module Wp2jekyll
  
  class JekyllMarkdown
    include DebugLogger
    attr_accessor :yaml_front_matter_str
    attr_accessor :body_str
    attr_reader :fp

    def initialize(fp = '')
      @fp = fp # file path
      
      if File.exist?(@fp)
        split_fulltxt(File.read(@fp))
      end
    end

    def hint_contents
      puts @body_str
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
      @@logger.debug "relink_image #{img_fn}".yellow

      tmp_s = @body_str
      
      URI.extract(tmp_s).each do |uri|
        uri.gsub!(/\)$/,'') # a patch
        
        if uri.include? img_fn
          @@logger.debug "relink_image uri: #{uri.red}"
          jekyll_img_link = LiquidUrl.new(uri: File.join(relative_path,img_fn)).to_s
          tmp_s.gsub!(uri, jekyll_img_link)
        end
      end

      @body_str = tmp_s
    end

    # write to @fp file
    def write
      File.write(@fp, @yaml_front_matter_str + @body_str)
    end

    def info
      "JekyllMarkdown: #{@fp}\n#{@yaml_front_matter_str}\n#{@body_str}"
    end
  end

end
