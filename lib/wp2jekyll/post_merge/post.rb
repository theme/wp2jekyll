require 'fileutils'
require 'logger'
require 'colorize'
require 'yaml'
require 'date'


module Wp2jekyll

  class Post < JekyllPost # TODO: JekyllPost
    attr_accessor :title
    attr_accessor :permalink_title
    attr_accessor :date
    attr_accessor :style

    @@fcache = FileCache.new

    def initialize(fp)
      super fp
      parse(@@fcache.read(fp))
      parse_yaml_front_matter(@yaml_front_matter_str)

      if nil == @date
        begin
          # try guess date from fp
          @date = Date.parse(/^\d\d\d\d-\d\d-\d\d/.match(File.basename(fp)).to_s)
        rescue ArgumentError
          @date = nil
        end
      end
    end

    def parse_yaml_front_matter(yaml_txt)
      # @@logger.debug 'parse_yaml_front_matter'
      # @@logger.debug yaml_txt.green
      if @yaml_hash = YAML.load(yaml_txt)
        @title = @yaml_hash['title']
        @date = @yaml_hash['date']
        @permalink_title = @yaml_hash['permalink_title']
        @style = @yaml_hash['style']
      end
    rescue Psych::SyntaxError => e
      @@logger.error e.message.red
      @@logger.error "error Post::parse_yaml_front_matter: #{fp}\n#{yaml_txt}".red
      Process.exit
    end

    def post_info
      "[Post #{@fp} #{@date} #{@title}]"
    end

    def datef
      # @@logger.debug "datef #{@date}".red
      if @date.is_a? String
        begin
          @date = Date.parse @date
        rescue RuntimeError
          @@logger.info "error Date.parse #{@date}"
        end
      end

      if @date.respond_to? 'strftime'
        @date.strftime('%Y-%m-%d')
      else
        ''
      end
    end

    def get_title
      (@permalink_title || @title.gsub(' ', '_').downcase)
    end

    def post_fn_base
      if 'post' == @style
        datef + '-' + get_title
      else
        get_title
      end
    end

    def yaml_hash_write_back
      if @yaml_hash
        @yaml_front_matter_str = @yaml_hash.to_yaml
      end
    end

    def write_to_dir(dir, force: false)
      usr_input_permalink
      fpath = File.join(dir, post_fn_base + '.md')
      if !File.exist?(fpath) then
        yaml_hash_write_back
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
      puts "> Please input a permalink title (empty keeps original) for #{post_info}"
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
