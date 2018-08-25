require 'fileutils'
require 'cgi'
require 'uri'
require 'logger'
require 'yaml'
require 'date'

require 'colorize'
require 'diff/lcs'

module Wp2jekyll
  class FileCache
    attr_accessor :cache
    def initialize
      @cache = {}
    end

    def read(fpath)
      if !@cache.has_key?(fpath)
        @cache[fpath] = File.read(fpath)
      end
      @cache[fpath]
    end

    def write(fpath, content)
      # delete item
      @cache.delete(fpath)
      # write through
      File.write(fpath, content)
    end
  end

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
      # @logger.debug 'parse_yaml_front_matter'
      # @logger.debug yaml_txt.green
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
        @logger.info "write file: #{fpath}"
      else
        @logger.warn "! File exist, when Post.write_to_dir #{dir}"
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

  class MarkdownFilesMerger
    SIMILAR_LV = 0.9

    @@logger = Logger.new(STDERR)
    @@logger.level = Logger::DEBUG

    def user_confirm(hint = '')
      c = ''
      until ( 'y' == c || 'n' == c ) do
        puts "#{hint} \n?(y/n)"
        c = STDIN.gets.chomp
      end
      'y' == c
    end

    def ask_usr_if_post_is_the_same(a, b)
      puts '+'*20
      hint_post_contents(a)
      puts '-'*20
      hint_post_contents(b)
      puts '='*20

      user_input = ''
      until user_input == 'y' || user_input == 'n' do
        puts "Regards them as the same post ?"
        user_input = STDIN.getc
        STDIN.gets # flush
      end

      case user_input
      when 'y' then
        true
      when 'n' then
        false
      end
    end

    def hint_post_contents(p)
      puts p.body_str.split[0..5].join
    end

    def is_post_same_date(a, b)
      a.date_str === b.date_str
    end

    def is_post_same_title(a, b)
      a.title == b.title
    end

    def is_post_similar(a, b)
      if a.title == b.title then return true end

      lcs = Diff::LCS.lcs(a.body_str, b.body_str)
      similarity = lcs.length * 1.0 / [a.body_str.length, b.body_str.length].max
      # @@logger.debug "similarity #{similarity} #{a.title} <-> #{b.title}".blue
      
      @@logger.info "\nsimilar? #{similarity}\n #{a.info}\n #{b.info}".green if similarity > 0.618
      similarity > SIMILAR_LV 
    end

    def is_post_exist(post, in_dir)
      # @@logger.debug "test post exist #{post.fp} in #{in_dir} ".green
      Dir.glob(File.join(in_dir, '**/*.md')) do |fpath|
        if is_post_similar(post, Post.new(fpath))
          return true
        end
      end
      false
    end

    def merge_post(post, to_dir)
      # @@logger.debug "try merge post #{post.fp} ".green
      if !is_post_exist(post, to_dir)
        @@logger.info post.body_str
        @@logger.info "merge_post #{post.info} new!"
        if user_confirm("Do merge_post #{post.info}")
          post.usr_input_title
          post.write_to_dir(to_dir)
        end
      else
        @@logger.info "merge_post #{post.info} exist."
      end
    end

    def merge_dir(from_dir, to_dir)
      @@logger.info "merger dir #{from_dir} -> #{to_dir}".red
      dbg_count = 0
      limit_count = false

      Dir.glob(File.join(from_dir, "**/*.{md,markdown}")) do |fpath|
        merge_post(Post.new(fpath), to_dir)

        dbg_count += 1

        if limit_count && dbg_count > 20
          break
        end
      end
      @@logger.info "#{dbg_count} post(s) tried."
    end
  end
end

