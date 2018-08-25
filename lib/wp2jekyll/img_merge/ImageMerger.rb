require 'fileutils'
require 'pathname'
require 'logger'
require 'colorize'
require 'diff/lcs'

module Wp2jekyll

  class ImageMerger

    @@logger = Logger.new(STDERR)
    @@logger.level = Logger::DEBUG

    attr_accessor :merge_count
    def initialize
      @merge_count = 0
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
    end

    def is_img_same_date(a, b)
      # TODO compare File ctime : change time
    end

    def basefn(path)
      base = File.basename(path)
    end

    def is_img_same_title(a, b)
      # TODO now only compare file name
      basefn(a) == basefn(b)
    end

    def is_img_similar(a, b)
      begin
        return true if File.size(a) == File.size(b) # TODO
      rescue
      end

      return true if basefn(a).include?(basefn(b)) || basefn(b).include?(basefn(a))

      false
    end

    def is_img_exist(image, in_dir)
      Dir.glob(File.join(in_dir, '**/*')) do |fpath|
        if is_img_similar(image, fpath)
          return true
        end
      end
      false
    end

    def merge_img(from_dir, image, to_dir)
      if !is_img_exist(image, to_dir)
        @@logger.info "merge_img #{image} new!"
        if user_confirm("Do merge_img #{image}", true) # TODO
          rel_path = Pathname.new(File.dirname(image)).relative_path_from(Pathname.new(from_dir))
          to_path = File.join(to_dir, rel_path)
          FileUtils.mkdir_p(to_path)
          FileUtils.cp(image, File.join(to_path, basefn(image)))
          @merge_count += 1
        end
      else
        @@logger.info "merge_img #{image} exists under #{to_dir}."
      end
    end

    def merge_dir(from_dir, to_dir)
      @@logger.info "merger image dir #{from_dir} -> #{to_dir}".red
      dbg_count = 0
      limit_count = false

      Dir.glob(File.join(from_dir, "**/*.{jpg,jpeg,png,gif,svg,bmp}")) do |fpath|
        merge_img(from_dir, fpath, to_dir) # keep dir structure

        dbg_count += 1

        if limit_count && dbg_count > 20
          break
        end
      end
      @@logger.info "#{merge_count} / #{dbg_count} image(s) merged."
    end
  end
end

