require 'fileutils'
require 'pathname'

require 'diff/lcs'

module Wp2jekyll

  class ImageMerger
    include DebugLogger
    attr_accessor :merge_count
    attr_accessor :img_trans

    def initialize
      @merge_count = 0
      @img_trans = []
    end

    def basefn(path)
      base = File.basename(path)
    end

    def is_merged?(img)
      @img_trans.each do |t|
        if basefn(img) == t.fn && nil != t.to
          return true
        end
      end
      false
    end

    def is_skipped?(img)
      @img_trans.each do |t|
        if basefn(img) == t.fn && nil == t.to
          return true
        end
      end
      false
    end

    def user_confirm(hint = '', yes = false)
      c = ''
      c = 'y' if yes
      until ( 'y' == c || 'n' == c ) do
        puts "#{hint} \n?(y/n)"
        c = STDIN.gets.chomp
      end
      'y' == c
    end

    def ask_usr_if_img_is_the_same(a, b)
      puts '+'*20
      hint_img_contents(a)
      puts '-'*20
      hint_img_contents(b)
      puts '='*20

      user_input = ''
      until user_input == 'y' || user_input == 'n' do
        puts "Regards them as the same image ?"
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

    def hint_img_contents(p)
      # TODO
      puts p
    end

    def is_img_same_date(a, b)
      # TODO compare File ctime : change time
    end

    def is_img_same_title(a, b)
      # TODO now only compare file name
      basefn(a) == basefn(b)
    end

    def is_img_similar(a, b)
      if File.size(a) == File.size(b) # TODO
        @@logger.info "#{a} size: #{File.size(a)}\n#{b} size:#{File.size(b)}"
        return true 
      end

      if basefn(a) == basefn(b)
        @@logger.info "#{a} basefn: #{basefn(a)}\n#{b} basefn:#{basefn(b)}"
        return true
      end

      false
    end

    def is_img_exist(image, in_dir)
      Dir.glob(File.join(in_dir, '**/*')) do |fpath|
        if is_img_similar(image, fpath)
          @@logger.info "similar image #{fpath}".green
          return true
        end
      end
      false
    end
    
    # copy image
    #   from from_dir/relative_path/basename (image)
    #   to to_dir/prepend_path/basename
    def merge_img_prepend_path(image:, to_dir:, prepend_path:)
      if !is_img_exist(image, to_dir)
        @@logger.info "merge_img_prepend_path #{image} new!".green
        if user_confirm("Do merge_img_keep_path #{image}", true) # TODO
          new_path = File.join(to_dir, prepend_path)
          to_fp = File.join(new_path, basefn(image))

          FileUtils.mkdir_p(new_path)
          FileUtils.cp(image, to_fp)

          @merge_count += 1
          @img_trans.append ImageTransaction.new(fn: basefn(image), from: image, to: to_fp)
        end
      else
        @@logger.info "merge_img_prepend_path #{basefn(image)} exists in #{to_dir}.".green
        @img_trans.append ImageTransaction.new(fn: basefn(image), from: image, to: nil)
      end
    end

    # copy image
    #   from from_dir/relative_path/basename
    #   to to_dir/relative_path/basename
    def merge_img_keep_path(from_dir:, image:, to_dir:)
      if !is_img_exist(image, to_dir)
        @@logger.info "merge_img_keep_path #{image} new!".green
        if user_confirm("Do merge_img_keep_path #{image}", true) # TODO
          rel_path = Pathname.new(File.dirname(image)).relative_path_from(Pathname.new(from_dir))
          new_path = File.join(to_dir, rel_path)
          to_fp = File.join(to_path, basefn(image))
          FileUtils.mkdir_p(new_path)
          FileUtils.cp(image, to_fp)
          @merge_count += 1
          @img_trans.append ImageTransaction.new(fn: basefn(image), from: image, to: to_fp)
        end
      else
        @@logger.info "merge_img_keep_path #{basefn(image)} exists in #{to_dir}.".green
        @img_trans.append ImageTransaction.new(fn: basefn(image), from: image, to: nil)
      end
    end

    def merge_dir(from_dir, to_dir)
      @@logger.info "... merge image dir #{from_dir} -> #{to_dir}".cyan
      dbg_count = 0
      limit_count = false

      Dir.glob(File.join(from_dir, "**/*.{jpg,jpeg,png,gif,svg,bmp}")) do |fpath|
        merge_img_keep_path(from_dir, fpath, to_dir) # keep dir structure

        dbg_count += 1

        if limit_count && dbg_count > 20
          break
        end
      end
      @@logger.info "#{merge_count} / #{dbg_count} image(s) merged.".green
      
      # debug list untouched files
      Dir.glob(File.join(from_dir, "**/*")) do |fpath|
        if File.file?(fpath) && !is_merged?(fpath) && !is_skipped?(fpath)
          @@logger.debug "#{fpath} is not handled : not a image.".yellow
        end
      end
    end
  end
end

