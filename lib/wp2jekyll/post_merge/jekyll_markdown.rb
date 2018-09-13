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
      @links = {}
      
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

    def extract_md_link_urls(str)
      h = {}
      MarkdownLink.extract(str).each do |mdlk|
        h.merge({ mdlk.parsed_str => mdlk.link })
        h.merge(extract_md_link_urls(mdlk.cap))
      end
      h
    end

    # @return [Hash] of { match_string => url_inside }
    def extract_urls_hash
      h = {}
      # markdown_link
      h.merge(extract_md_link_urls(body_str))

      # liquid_url
      LiquidUrl.extract(body_str).each do |lqlk|
        if !h.keys.include? lqlk.parsed_str
          h.merge({ lqlk.parsed_str => lqlk.uri })
        end
      end

      # simple_url
      URI.extract(body_str).each do |uri|
        uri.gsub!(/\)$/,'')
        if !h.keys.include? uri then
          h.merge({ uri => uri})
        end
      end

    end

    # search link that contains img_fn, replace its path with provided path
    def relink_image(img_fn, relative_path)
      @@logger.debug "relink_image #{img_fn}".yellow

      tmp_s = @body_str
      
      URI.extract(tmp_s).each do |uri|
        uri.gsub!(/\)$/,'') # a patch
        
        if uri.include? img_fn
          @@logger.debug "relink_image uri: #{uri.red}"
          lqlk_s = LiquidUrl.new(uri: File.join(relative_path,img_fn)).to_s
          tmp_s.gsub!(uri, lqlk_s)
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

