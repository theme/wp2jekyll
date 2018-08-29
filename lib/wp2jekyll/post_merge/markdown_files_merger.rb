require 'fileutils'
require 'logger'
require 'colorize'
require 'diff/lcs'

module Wp2jekyll

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

