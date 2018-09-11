require 'fileutils'
require 'logger'
require 'colorize'
require 'yaml'
require 'date'


module Wp2jekyll

  class Post < JekyllMarkdown
    attr_accessor :title
    attr_accessor :permalink_title
    attr_accessor :date_str

    @@fcache = FileCache.new

    def initialize(fp)
      super fp
      split_fulltxt(@@fcache.read(fp))
      parse_yaml_front_matter(@yaml_front_matter_str)
    end

    def parse_yaml_front_matter(yaml_txt)
      # @@logger.debug 'parse_yaml_front_matter'
      # @@logger.debug yaml_txt.green
      if @yaml_hash = YAML.load(yaml_txt)
        @title = @yaml_hash['title']
        @date_str = @yaml_hash['date']
        @permalink_title = @yaml_hash['permalink_title']
      end
    end

    def info
      "[Post #{@fp} #{date_str} #{@title}]"
    end

    def datef
      if @date_str.respond_to? :strftime
        @date_str.strftime('%Y-%m-%d')
      elsif @data_str.is_a? String
        Date.parse(@date_str).strftime('%Y-%m-%d')
      else
        Time.now.strftime('%Y-%m-%d')
      end
    end

    def post_fn_base
      datef + '-' + (@permalink_title || @title.gsub(' ', '_').downcase)
    end

    def yaml_hash_write_back
      if @yaml_hash
        @yaml_front_matter_str = @yaml_hash.to_yaml
      end
    end

    def write_to_dir(dir)
      usr_input_permalink
      fpath = File.join(dir, post_fn_base + '.md')
      if !File.exist?(fpath) then
        yaml_hash_write_back
        @@fcache.write(fpath, @yaml_front_matter_str + "---\n" + @body_str)
        @@logger.info "write file: #{fpath}"
      else
        @@logger.warn "! File exist, when Post.write_to_dir #{dir}"
      end
    end

    def input_with_hint(hint: '') # get a user input line
      puts hint
      STDIN.gets.chomp.strip.gsub(' ', '_')
    end

    def usr_input_title
      puts "> Please input a title (empty keeps original) for #{self.info}"
      puts "> Current post title: #{@title}"
      uin = input_with_hint
      if !uin.empty?
        @title = uin
        @yaml_hash['title'] = uin if @yaml_hash
      else
        @title
      end
    end

    def usr_input_permalink
      puts "> Please input a permalink title (empty keeps original) for #{self.info}"
      puts "> Current post file name : #{post_fn_base}"
      uin = input_with_hint
      puts uin
      if !uin.empty?
        @permalink_title = uin
        @yaml_hash['permalink_title'] = uin if @yaml_hash
      else
        @permalink_title
      end
    end
  end

end

