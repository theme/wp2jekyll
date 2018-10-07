require 'fileutils'
require 'parallel'

module Wp2jekyll

  class PostMerger < FileMerger
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

    def most_similar_post(fp, cp, in_dir)
      f_li = Dir.glob(File.join(in_dir, '**/*.{md,markdown}'))
      
      return nil if 0 == f_li.length

      # s_h = Parallel.map(f_li, in_process: 8) { |fpath|
      #   # @@logger.debug fpath
      #   c = PostCompare.new(fp, fpath, ac: cp)
      #   [c.body_similarity , fpath]
      # }

      s_h = []
      f_li.each { |fpath|
        # @@logger.debug fpath
        c = PostCompare.new(fp, fpath, ac: cp)
        s_h << [c.body_similarity , fpath]
      }

      m = s_h.max { |a,b|
        # @@logger.debug "max #{a} #{b}".red
        a[0] <=> b[0] # failed when [NaN, Number]
      }
      
      m[1]
    end

    # @op : original post file path
    # @cp : converted post file path
    def merge_converted_post(fp, cp, to_dir)
      @try_counter += 1

      post = Post.new fp
      do_merge = false

      begin
        e_p = most_similar_post(fp, cp, to_dir)
        if nil == e_p || !(PostCompare.new(fp, e_p, ac: cp).similar?)
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
        post = Post.new cp
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

    # @return [String] the post in target dir after merge.
    def merge_post(fp, to_dir)
      merge_converted_post(fp, fp, to_dir)
    end

    def stat
      "#{@post_trans.length}/#{try_counter}"
    end

    def merge_dir(from_dir, to_dir)
      Dir.glob(File.join(from_dir, "**/*.{md,markdown}")) do |fpath|
        begin
          Post.new fpath # test Post parse successful
          merge_post(fpath, to_dir)
        rescue ArgumentError # handle exception
          # degrade to file
          merge_file(fp: fpath, from_dir:from_dir, to_dir:to_dir)
        end
      end

      @@logger.info "post merge_dir #{stat}."
    end
  end
end
