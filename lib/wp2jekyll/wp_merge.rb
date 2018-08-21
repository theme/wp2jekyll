require 'fileutils'
require 'cgi'
require 'uri'
require 'logger'
require 'yaml'
require 'date'

require 'colorize'
require 'diff/lcs'

module Wp2jekyll
  class Post < JekyllMarkdown
    attr_accessor :title
    attr_accessor :permalink_title
    attr_accessor :date
    def initialize(fp)
      super fp
      split_fulltxt(File.read(fp))
      parse_yaml_front_matter(@yaml_front_matter_str)
    end

    def parse_yaml_front_matter(yaml_txt)
      @logger.debug 'parse_yaml_front_matter'
      @logger.debug yaml_txt.green
      if @yaml_hash = YAML.load(yaml_txt)
        @title = @yaml_hash['title']
        @date = @yaml_hash['date']
        @permalink_title = @yaml_hash['permalink_title']
      end
    end

    def ==(obj)
      if not obj.is_a? self.class
        false
      end
      @title == obj.title && @date == obj.date
    end

    def info
      "[Post #{@fp} #{date_str} #{@title}]"
    end

    def date_str
      @date.strftime('%Y-%m-%d')
    end

    def post_fn_base
      date_str + '-' + (@permalink_title || @title.gsub(' ', '_').downcase)
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
        File.write(fpath, @yaml_front_matter_str + "---\n" + @body_str)
        @@logger.info "write file: #{fpath}"
      else
        @logger.warn "! File exist, when Post.write_to_dir #{dir}"
      end
    end

    def input_with_hint(hint: '') # get a user input line
      puts hint
      uin = STDIN.gets.chomp.strip.gsub(' ', '_')
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
    SIMILAR_LV = 0.95

    @@logger = Logger.new(STDERR)
    @@logger.level = Logger::DEBUG

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
      a.date == b.date
    end

    def is_post_same_title(a, b)
      a.title == b.title
    end

    def is_post_similar(a, b)
      lcs = Diff::LCS.lcs(a.body_str, b.body_str)
      lcs.length * 1.0 / [a.body_str.length, b.body_str.length].max > SIMILAR_LV
    end

    def is_post_exist(post, in_dir)
      Dir.glob(File.join(in_dir, '**/*.md')) do |fpath|
        if is_post_similar(post, Post.new(fpath))
          return true
        end
      end
      false
    end

    def merge_post(post, to_dir)
      if !is_post_exist(post, to_dir)
        @@logger.info post.body_str
        @@logger.info "merge_post #{post.info} new!"
        post.usr_input_title
        post.write_to_dir(to_dir)
      else
        @@logger.info "merge_post #{post.info} exist."
      end
    end

    def merge_dir(from_dir, to_dir)
      @@logger.info 'merge_dir'
      Dir.glob(File.join(from_dir, "**/*.{md,markdown}")) do |fpath|
        merge_post(Post.new(fpath), to_dir)
      end
    end
  end
end
