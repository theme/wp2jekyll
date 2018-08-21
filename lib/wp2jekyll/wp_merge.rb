require 'fileutils'
require 'cgi'
require 'uri'
require 'logger'
require 'yaml'
require 'date'

require 'nokogiri'
require 'colorize'
require 'diff/lcs'

module Wp2jekyll
  class Post
    attr_accessor :title
    attr_accessor :date
    attr_accessor :body_txt
    def initialize(fp)
      @logger = Logger.new(STDERR)
      @logger.level = Logger::DEBUG

      jkm = JekyllMarkdown.new(fp)
      jkm.split_fulltxt(File.read(fp))
      parse_yaml_front_matter(jkm.yaml_front_matter_str)
      @body_txt = jkm.body_str
    end

    def parse_yaml_front_matter(yaml_txt)
      hash = YAML.load(yaml_txt)
      @title = hash['title']
      @date = hash['date']
    end

    def ==(obj)
      if not obj.is_a? self.class
        false
      end
      @title == obj.title && @date == obj.date
    end
  end

  class MarkdownFilesMerger
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
      jmd = JekyllMarkdown.new
      jmd.split_fulltxt(File.read(p))
      puts jmd.body_str.split[0..5].join
    end

    def is_post_same_date(a, b)
      Post.new(a).date == Post.new(b).date
    end

    def is_post_same_title(a, b)
      Post.new(a).title == Post.new(b).title
    end

    def is_post_similar(a, b)
      ta = Post.new(a).body_txt
      tb = Post.new(b).body_txt
      lcs = Diff::LCS.lcs(ta, tb)
      lcs.length * 1.0 / [ta.length, tb.length].max > 0.95
    end

    def is_post_exist(post, in_dir)
    end

    def merger_post(post, to_dir)
    end

    def merge_dir(from_dir, to_dir)
    end
  end
end

