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

  class FileMerger
    include DebugLogger

    attr_accessor :file_trans
    attr_accessor :try_counter

    def initialize
      @file_trans = FileTransactionHistory.new
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

    def most_similar_file(fp, in_dir)
      highest_similarity = 0
      nearest_file = nil
      Dir.glob(File.join(in_dir, '**/*.md')) do |fpath|
        c = FileCompare.new(fp, fpath)
        if c.similar? && c.binary_similarity > highest_similarity
            highest_similarity = c.binary_similarity
            nearest_file = fpath
        end
      end

      nearest_file
    end

    # merge file
    #   from from_dir/relativs_fath/basename (file)
    #   to to_dir/prepend_path/keep_path?/rename?_basename
    #
    # if file is already exist, mv to desired path
    # @return [String] final existing full path of file
    def merge_file(fp:, from_dir:, to_dir:, prepend_path:, keep_path: false, rename: nil)

      ### TODO
      
      @try_counter += 1

      do_merge = false

      begin
        s_f = most_similar_file(fp, to_dir)
        if nil == s_f 
          # not exist, do merge, return target
          @@logger.info "merge_file new! #{post.post_info} ".green
          do_merge = true
        else
          # exist
          @@logger.info "merge_file exist. #{s_f} ".yellow
          # s_f = Post.new fpath
          # s_f.hint_contents
          # @@logger.info "\n+ #{fp}".yellow
          # post.hint_contents
          # do_merge = user_confirm("Do merge post ? #{post.post_info}".yellow)
          do_merge = false
        end
      rescue UncertainSimilarityError => e  # not sure,  user decided
        if !e.user_judge # posts are not the same
          @@logger.info "merge_file new! #{post.post_info} ".green
          do_merge = true
        else # posts are the same
          if user_confirm("Force merge and overwrite ???".red)
            File.delete(e.b)
            do_merge = true
          else
            do_merge = false
            @@logger.info "user skip merge_file #{s_f}"
          end
        end
      end

      if do_merge
        post.usr_input_title

        if !Dir.exist?(to_dir)
          FileUtils.mkdir_p(to_dir)
        end

        wrote_fpath = post.write_to_dir(to_dir, force: true)
        @file_trans.add(from:fp, to:wrote_fpath)
        wrote_fpath
      else
        nil
      end
    end

    def stat
      "#{@file_trans.length}/#{try_counter}"
    end

    def merge_dir(from_dir, to_dir)

      Dir.glob(File.join(from_dir, "**/*.{md,markdown}")) do |fpath|
        merge_file(fpath, to_dir)
      end

      @@logger.info "post merge_dir #{stat}."
    end
  end
end
