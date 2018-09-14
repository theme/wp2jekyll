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

    # def extract_md_link_urls(str)
    #   h = {}
    #   h
    # end

    # @return [Hash] of { match_string => url_inside }
    def extract_urls_hash(txt)
      h = {}
      # markdown_link
      MarkdownLink.extract(txt).each do |mdlk|
        h = h.merge(extract_urls_hash(mdlk.cap))
        h = h.merge(extract_urls_hash(mdlk.link))
        if !h.keys.include? mdlk.parsed_str
          h = h.merge({ mdlk.parsed_str => mdlk.link })
        end
      end
      
      # liquid_url
      LiquidUrl.extract(txt).each do |lqlk|
        if !h.keys.include? lqlk.parsed_str
          h = h.merge({ lqlk.parsed_str => lqlk.uri.to_s })
        end
      end

      # simple_url
      URI.extract(txt).each do |uri|
        uri.gsub!(/\)$/,'')
        if !h.keys.include? uri
          h = h.merge({ uri => uri})
        end
      end

      # @@logger.info "#{h.inspect}".red
      h
    end

    def all_urls_hash
      extract_urls_hash(@body_str)
    end

    # search link that contains img_fn, replace its path with provided path
    def relink_image_in_txt(img_fn, to_path, in_txt)
      new_url = URI.join(File.join(to_path, img_fn))
      extract_urls_hash(in_txt).each do |mstr, url|
        if url.include? img_fn
          if mdlk = MarkdownLink.parse(mstr)
            mdlk.cap = relink_image_in_txt(img_fn, to_path, mdlk.cap)
            mdlk.link = LiquidUrl.new(uri:new_url)
            in_txt.gsub!(mstr, mdlk.to_s)
          end

          if lqlk = LiquidUrl.parse(mstr)
            lqlk.uri = URI.parse(url)
            in_txt.gsub!(mstr, lqlk.to_s)
          end

          begin
            uri = URI.parse(url)
            in_txt.gsub!(mstr, LiquidUrl.new(uri:new_url).to_s)
          rescue URI::InvalidURIError => e
            nil
          end
        end
      end
      in_txt
    end

    def relink_image(img_fn, to_path)
      @@logger.debug "relink_image #{img_fn}".yellow
      @body_str = relink_image_in_txt(img_fn, to_path, @body_str)
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

