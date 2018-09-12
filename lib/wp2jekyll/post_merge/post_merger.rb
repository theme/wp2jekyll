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
    attr_accessor :try_counter

    def initialize
      @merged_post = []
      @try_counter = 0
    end

    def stat
      "#{@merged_post.length}/#{@try_counter} merge/try"
    end

    def user_confirm(hint = '')
      c = ''
      until ( 'y' == c || 'n' == c ) do
        puts "#{hint} \n?(y/n)"
        c = STDIN.gets.chomp
      end
      'y' == c
    end

    def is_post_exist(fp, in_dir)
      # @@logger.debug "test post exist #{post.fp} in #{in_dir} ".green
      Dir.glob(File.join(in_dir, '**/*.md')) do |fpath|
        if PostCompare.new(fp, fpath).similar?
          return true
        end
      end
      false
    end

    def existing_post_fp(fp, in_dir)
      Dir.glob(File.join(in_dir, '**/*.md')) do |fpath|
        if PostCompare.new(fp, fpath).similar? # TODO get top similar post
          return fpath
        end
      end
      nil
    end

    # @return [Bool] true if post is merged.
    def merge_post(fp, to_dir)
      @try_counter += 1
      post = Post.new fp
      if !is_post_exist(fp, to_dir)
        @@logger.info post.body_str
        @@logger.info "merge_post #{post.post_info} new!"
        if user_confirm("Do merge_post #{post.post_info}")
          post.usr_input_title
          post.write_to_dir(to_dir)
          @merged_post.append fp
        else
          # raise MergeFailError.new("User deny to merge post", reason: MergeFailError::USER_DENY)
        @@logger.info "merge_post user denied #{post.post_info}."
        end
      else
        @@logger.info "merge_post #{post.post_info} exist."
        # raise MergeFailError.new("Post already exist", reason: MergeFailError::ALREADY_EXIST)
      end
    end

    def merge_dir(from_dir, to_dir)

      Dir.glob(File.join(from_dir, "**/*.{md,markdown}")) do |fpath|
        merge_post(fpath, to_dir)
      end

      @@logger.info "post merge_dir #{stat}."
    end
  end
end
