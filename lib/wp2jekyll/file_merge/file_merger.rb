require 'fileutils'
require 'parallel'

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
      Parallel.map(Dir.glob(File.join(in_dir, '**/*'))) do |fpath|
        if File.file?(fp) && File.file?(fpath)
          c = FileCompare.new(fp, fpath)
          if c.similar? && c.binary_similarity > highest_similarity
              highest_similarity = c.binary_similarity
              nearest_file = fpath
          end
        end
      end

      nearest_file
    end

    # merge file
    #   from from_dir/relativs_fath/basename (file)
    #   to to_dir/prepend_path/keep_rela_path?/rename?_basename
    #
    # if file is already exist, mv to desired path
    # @return [String] final existing full path of file
    def merge_file(fp:, from_dir:, to_dir:, prepend_path: '', keep_rela_path: false, rename: nil)

      @@logger.debug "merge_file #{fp}"
      @try_counter += 1

      do_merge = false

      begin
        s_f = most_similar_file(fp, to_dir)
        if nil == s_f 
          # not exist, do merge, return target
          @@logger.info "merge_file new! #{fp}".green
          do_merge = true
        else
          # exist
          @@logger.info "merge_file exist. #{s_f}".yellow
          do_merge = false
        end
      rescue UncertainSimilarityError => e  # not sure,  user decided
        if !e.user_judge # files are not the same
          @@logger.info "merge_file new! #{fp} ".green
          do_merge = true
        else # files are the same
          if user_confirm("Force merge and overwrite ???".red)
            File.delete(e.b)
            do_merge = true
          else
            do_merge = false
            @@logger.info "user skip merge_file #{fp}"
          end
        end
      end

      if do_merge
        if nil != rename && '' != rename
          new_bn = rename
        else
          new_bn = File.basename(fp)
        end

        rel_path = Pathname.new(File.dirname(fp)).relative_path_from(Pathname.new(from_dir))
        if keep_rela_path
          @@logger.debug "prepend_path #{prepend_path} rel_path #{rel_path}"
          new_path = File.join(prepend_path, rel_path)
        else
          new_path = prepend_path
        end

        new_fp = File.join(to_dir, new_path, new_bn)

        if !Dir.exist?(File.join(to_dir, new_path))
          FileUtils.mkdir_p(File.join(to_dir, new_path))
        end

        FileUtils.cp(fp, new_fp, verbose: true)
        @file_trans.add(from:fp, to:new_fp)
        new_fp
      else
        nil
      end
    end

    def stat
      "#{@file_trans.length}/#{try_counter}"
    end

    def merge_dir(from_dir:, to_dir:, skip_image: true)

      Dir.glob(File.join(from_dir, "**/*")) do |fpath|
        if File.file?(fpath)
          if skip_image
            if Image.is_a_image_fp? fpath
              # @@logger.debug "merge_file skip #{fpath}"
              next
            end
          end
          merge_file(fp:fpath, from_dir: from_dir, to_dir: to_dir, keep_rela_path: true)
        end
      end

      @@logger.info "merge_files (dir) #{stat}."
    end
  end
end

