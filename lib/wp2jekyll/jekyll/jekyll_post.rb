require 'fileutils'
require 'cgi'
require 'uri'
require 'logger'

module Wp2jekyll
  
  class JekyllPost
    include DebugLogger

    RE_SEP = %r{---\s*\r?\n}
    RE = Regexp.new %r{\A#{RE_SEP}(.*?)#{RE_SEP}(.*)}m

    attr_accessor :yaml_front_matter_str
    attr_accessor :content
    attr_reader :fp

    def initialize(fp = '')
      @fp = fp # file path
      @links = {}
      
      if File.exist?(@fp)
        parse(File.read(@fp))
      else
        raise RuntimeError.new("error init JekyllPost: File not exist: #{fp}")
      end
    end

    def hint_contents
      puts @content
    end

    # @return [Hash] {:yaml_front_matter => 'yaml_front_matter_str', :content => 'post content string'}
    def parse(txt)
      m = RE.match(txt) # TODO understand yaml format
      if nil != m
        @yaml_front_matter_str  = m[1]
        @content = m[2]
        return {:yaml_front_matter => @yaml_front_matter_str, :content => @content}
      else
        raise RuntimeError.new("error parsing Jekyll Post: #{RE} ! =~ \n#{txt}")
      end
      nil
    end

    def to_s
      "---\n" + @yaml_front_matter_str + "---\n" + @content
    end

    # Returns true if the YAML front matter is present.
    def self.has_yaml_header?(file)
      nil != (File.open(file, "rb", &:readline) =~ RE_SEP)
    rescue EOFError
      false
    end

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
      extract_urls_hash(@content)
    end

    # search link that contains img_fn, replace its path with provided path
    def relink_image_in_txt(img_fn, to_path, in_txt)
      @@logger.info "relink_image_in_txt img_fn #{img_fn} to_path #{to_path}"
      new_url = URI.join(File.join(to_path, img_fn))
      extract_urls_hash(in_txt).each do |mstr, url|
        if url.include? img_fn
          if mdlk = MarkdownLink.parse(mstr)
            mdlk.cap = relink_image_in_txt(img_fn, to_path, mdlk.cap)
            mdlk.link = LiquidUrl.new(url:new_url)
            in_txt.gsub!(mstr, mdlk.to_s)
          end

          if lqlk = LiquidUrl.parse(mstr)
            lqlk.uri = URI.parse(url)
            in_txt.gsub!(mstr, lqlk.to_s)
          end

          begin
            # uri = URI.parse(url)
            in_txt.gsub!(mstr, LiquidUrl.new(url:new_url).to_s)
          rescue URI::InvalidURIError
            nil
          end
        end
      end
      in_txt
    end

    def relink_image(img_fn, to_path)
      @@logger.debug "relink_image #{img_fn}".yellow
      @content = relink_image_in_txt(img_fn, to_path, @content)
    end

    # write to @fp file
    def write
      File.write(@fp, @yaml_front_matter_str + @content)
    end

    def info
      "JekyllPost: #{@fp}\n#{@yaml_front_matter_str}\n#{@content}"
    end
  end

end

