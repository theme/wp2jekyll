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

    def is_post_exist?(fp, in_dir)
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

      do_merge = false
      if !is_post_exist?(fp, to_dir)
        @@logger.info "merge_post new! #{post.post_info} ".green
        do_merge = true
      else
        fpath = existing_post_fp(fp, to_dir)
        @@logger.info "merge_post exist. \n- #{fpath} ".yellow # BUG HINT
        e_p = Post.new fpath
        e_p.hint_contents
        @@logger.info "\n+ #{fp}".yellow
        post.hint_contents
        do_merge = user_confirm("Do merge post ? #{post.post_info}".yellow)
      end

      if do_merge
        post.usr_input_title

        if !Dir.exist?(to_dir)
          FileUtils.mkdir_p(to_dir)
        end

        post.write_to_dir(to_dir)
        @merged_post.append fp
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
