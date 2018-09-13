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

    attr_accessor :post_trans
    attr_accessor :try_counter

    def initialize
      @post_trans = FileTransactionHistory.new
      @try_counter = 0
    end

    def user_confirm(hint = '')
      c = ''
      until ( 'y' == c || 'n' == c ) do
        puts "#{hint} \n?(y/n)"
        c = STDIN.gets.chomp
      end
      'y' == c
    end

    def most_similar_post(fp, in_dir)
      highest_similarity = 0
      nearest_post = nil
      Dir.glob(File.join(in_dir, '**/*.md')) do |fpath|
        c = PostCompare.new(fp, fpath)
        if c.similar? && c.get_similarity > highest_similarity
            highest_similarity = c.get_similarity
            nearest_post = fpath
        end
      end

      nearest_post
    end

    # @return [String] the post in target dir after merge.
    def merge_post(fp, to_dir)
      @try_counter += 1

      post = Post.new fp
      do_merge = false

      begin
        e_p = most_similar_post(fp, to_dir)
        if nil == e_p 
          # not exist, do merge, return target
          @@logger.info "merge_post new! #{post.post_info} ".green
          do_merge = true
        else
          # exist
          @@logger.info "merge_post exist. #{e_p} ".yellow
          # e_p = Post.new fpath
          # e_p.hint_contents
          # @@logger.info "\n+ #{fp}".yellow
          # post.hint_contents
          # do_merge = user_confirm("Do merge post ? #{post.post_info}".yellow)
          do_merge = false
        end
      rescue UncertainSimilarityError => e  # not sure,  user decided
        if !e.user_judge # posts are not the same
          @@logger.info "merge_post new! #{post.post_info} ".green
          do_merge = true
        else # posts are the same
          if user_confirm("Force merge and overwrite ???".red)
            File.delete(e.b)
            do_merge = true
          else
            do_merge = false
            @@logger.info "user skip merge_post #{e_p}"
          end
        end
      end

      if do_merge
        post.usr_input_title

        if !Dir.exist?(to_dir)
          FileUtils.mkdir_p(to_dir)
        end

        wrote_fpath = post.write_to_dir(to_dir, force: true)
        @post_trans.add(from:fp, to:wrote_fpath)
        wrote_fpath
      else
        nil
      end
    end

    def stat
      "#{@post_trans.length}/#{try_counter}"
    end
    def merge_dir(from_dir, to_dir)

      Dir.glob(File.join(from_dir, "**/*.{md,markdown}")) do |fpath|
        merge_post(fpath, to_dir)
      end

      @@logger.info "post merge_dir #{stat}."
    end
  end
end
