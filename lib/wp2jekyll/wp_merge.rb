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
  class Post < JekyllMarkdown
    attr_accessor :title
    attr_accessor :date
    def initialize(fp)
      super fp
      split_fulltxt(File.read(fp))
      parse_yaml_front_matter(@yaml_front_matter_str)
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
      lcs.length * 1.0 / [a.body_str.length, b.body_str.length].max > 0.95
    end

    def is_post_exist(post, in_dir)
      Dir.glob("**/*.md") do |fpath|
        b_post = Post.new(fpath)
        if is_post_similar(post, b_post)
          return true
        end
      end
      false
    end

    def merger_post(post, to_dir)
    end

    def merge_dir(from_dir, to_dir)
    end
  end
end

