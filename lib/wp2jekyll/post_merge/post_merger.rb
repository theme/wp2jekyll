require 'fileutils'

module Wp2jekyll

  class MergeFailError < StandardError
    attr_reader :reason
    ALREADY_EXIST = -1
    USER_DENY = -2

    def initialize(msg:, reason:)
      super msg
      @reason = reason
    end

  end

  class PostMerger
    include DebugLogger

    attr_accessor :merged_post
    def initialize
      @merged_post = []
    end

    def user_confirm(hint = '')
      c = ''
      until ( 'y' == c || 'n' == c ) do
        puts "#{hint} \n?(y/n)"
        c = STDIN.gets.chomp
      end
      'y' == c
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

    def existing_post_fp(post, in_dir)
      Dir.glob(File.join(in_dir, '**/*.md')) do |fpath|
        if is_post_similar(post, Post.new(fpath))
          return fpath
        end
      end
      nil
    end

    # @return [Bool] true if post is merged.
    def merge_post(fp, to_dir)
      post = Post.new fp
      if !is_post_exist(post, to_dir)
        @@logger.info post.body_str
        @@logger.info "merge_post #{post.info} new!"
        if user_confirm("Do merge_post #{post.info}")
          post.usr_input_title
          post.write_to_dir(to_dir)
          @merged_post.append fp
        else
          # raise MergeFailError.new("User deny to merge post", reason: MergeFailError::USER_DENY)
        @@logger.info "merge_post user denied #{post.info}."
        end
      else
        @@logger.info "merge_post #{post.info} exist."
        # raise MergeFailError.new("Post already exist", reason: MergeFailError::ALREADY_EXIST)
      end
    end

    def merge_dir(from_dir, to_dir)
      # @@logger.info "merger dir #{from_dir} -> #{to_dir}".red
      # dbg_count = 0
      # limit_count = false

      Dir.glob(File.join(from_dir, "**/*.{md,markdown}")) do |fpath|
        merge_post(fpath, to_dir)

        # dbg_count += 1

        # if limit_count && dbg_count > 20
        #   break
        # end
      end
      @@logger.info "#{dbg_count} post(s) tried."
    end
  end
end
