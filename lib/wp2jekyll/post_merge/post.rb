require 'fileutils'
require 'logger'
require 'colorize'
require 'yaml'
require 'date'


module Wp2jekyll

  class Post < JekyllMarkdown

    attr_accessor :yaml_front_matter

    @@fcache = FileCache.new

    def initialize(fp)
      super fp

      parse_yaml_front_matter(@yaml_front_matter_str)
    end

    def parse_yaml_front_matter(yaml_txt)
      # @@logger.debug 'parse_yaml_front_matter'
      # @@logger.debug yaml_txt.green
      @yaml_front_matter = YAML.load(yaml_txt)
    rescue Psych::SyntaxError => e
      @@logger.error e.message.red
      @@logger.warn "error Post::parse_yaml_front_matter: #{fp}\n#{yaml_txt}".red
      @yaml_front_matter = {}
    rescue TypeError => e
      @@logger.error e.message.red
      @@logger.warn "error Post::parse_yaml_front_matter: #{fp}\n#{yaml_txt}".red
      @yaml_front_matter = {}
    end
    
    def title
      @yaml_front_matter['title']
    end
    def date
      d = @yaml_front_matter['date']
      if nil == d
        begin
          # try guess date from fp
          d = Date.parse(/^\d\d\d\d-\d\d-\d\d/.match(File.basename(@fp)).to_s)
        rescue ArgumentError
          d = nil
        end
      end
      return d
    end
    def permalink_title
      @yaml_front_matter['permalink_title']
    end
    def style
      @yaml_front_matter['style']
    end

    def post_info
      "[Post #{@fp} #{datef} #{title}]"
    end

    def datef
      if date.respond_to? :strftime
        date.strftime('%Y-%m-%d')
      else
        ''
      end
    end

    def get_title
      (permalink_title || title.gsub(' ', '_').downcase)
    end

    def post_fn_base
      if 'post' == style
        datef + '-' + get_title
      else
        get_title
      end
    end

    def to_s
      @yaml_front_matter_str = @yaml_front_matter.to_yaml
      super
    end

    def write_to_dir(dir, force: false)
      usr_input_permalink
      fpath = File.join(dir, post_fn_base + '.md')
      if !File.exist?(fpath) then
        @@fcache.write(fpath, to_s)
        @@logger.info "write file: #{fpath}"
      elsif force
        File.delete(fpath)
        @@fcache.write(fpath, to_s)
        @@logger.info "force write file: #{fpath}"
      else
        @@logger.warn "skip write file:  #{fpath}"
      end
      fpath
    end

    def input_with_hint(hint: '') # get a user input line
      puts hint
      STDIN.gets.chomp.strip.gsub(' ', '_')
    end

    def usr_input_title
      puts "> Please input a title (empty keeps original) for #{post_info}"
      puts "> Current post title: #{title}"
      uin = input_with_hint
      if !uin.empty?
        @yaml_front_matter[:title] = uin
      end
    end

    def usr_input_permalink
      puts "> Please input a permalink title (empty keeps original) for #{post_info}"
      puts "> Current post file name : #{post_fn_base}"
      uin = input_with_hint
      puts uin
      if !uin.empty?
        @yaml_front_matter[:permalink_title] = uin
      end
    end
  end

end
