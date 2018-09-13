require "wp2jekyll/version"

# This gem try to import 2 kinds of things, into jekyll blog:

# 1. other blog's posts.
# 1.1 TODO get input_dirs ( user config search path, and dir name wildcard)
# 1.2 check if post already exists in jekyll/_posts/ for each post in each input_dir (using similarity algorithm)
# 1.3 hint user to modify post name, then write it into jekyll/_posts/ dir.
# 1.4 patch post content (like html tags) to jekyll supported markdown format. (TODO some old format is lost)


# 2. TODO other blog's images.
# 2.1 get input_dirs (scan input dir_list, search for known_names, such as wordpress's "wp-content/uploads/")
# 2.2 check if image file is already exist in jekyll's _assets dir.
# 2.3 copy image, keep dir structure for same kind of source. (wordpress | wordpress.com | blogspot)
# 2.4 modify every link that referes to a image in jekyll/_posts/ to new dir path.
# 2.5 If a image link lack correspondent image file, try search from online storage ( e.g. Google Photo ) and save to local, then modify link to jekyll format.

module Wp2jekyll
  require 'debug_logger'
  require 'image'

  require 'wp2jekyll/wp_import'
  require 'wp2jekyll/google_photo_import'
  require 'wp2jekyll/blogspot_import'
  
  def self.process_wordpress_md_in_dir(d)
    if Dir.exist? d then
      Dir.glob (d + '/**/*.md') do |fpath|
        WordpressMarkdown.new(fpath).write_jekyll_md!
      end
    end
  end

  def self.merge_markdown_posts(from_dir:, to_jekyll_posts_dir:)
    PostMerger.new.merge_dir(from_dir, to_jekyll_posts_dir)
  end

  def self.import_blogger_post(from_grabbed_dir:, to_dir:, to_img_dir:, replace_meta:)
    BloggerGrabbedImporter.import(from_grabbed_dir, to_dir, to_img_dir, replace_meta: replace_meta)
  end

  def self.rename_md_posts_indir(dir)
    if Dir.exist? dir then
      Dir.glob (dir + '**/*.md') do |fpath|
        dirn = File.dirname(fpath)
        extn = File.extname(fpath)
        basen = File.basename(fpath, extn)

        ma = basen.match(/^\d\d\d\d-\d\d-\d\d-/)
        next if !ma
        dates = ma[0]
        fn_re = /^[a-zA-Z_0-9-]+$/
        next if fn_re.match?(basen)

        dst_string = File.read(fpath)
        puts dst_string

        puts '---------'
        puts basen
        puts URI.unescape(fpath)

        c = ''
        until ( 'r' == c || 'd' == c ) do
          puts '(r)ename? (d)raft?'
          c = STDIN.getc
          STDIN.gets # this flush getc's left over string
        end

        case c
        when 'r' then
          puts 'rename to?'
          puts dates

          # input new name
          inputs = STDIN.gets.chomp
          basen_new = dates + inputs
          basen_new.downcase!
          basen_new.gsub!(' ', '-')
          puts basen_new

          # move
          fpath_new = fpath.gsub(basen, basen_new)
          if fn_re.match?(basen_new) then
            FileUtils.mv(fpath, fpath_new,
                         :force => false, :verbose => true)
          else
            puts 'X invalid name: ' + fpath_new
            exit
          end

        when 'd' then
          puts 'TODO: mv to ../_drafts/, append date if conflict.'
          dirn = File.dirname(fpath)
          extn = File.extname(fpath)
          basen = File.basename(fpath, extn)
          FileUtils.mv(fpath, fpath.gsub(dirn, dirn + '/../_drafts/'),
                       :force => false, :verbose => true)
        end
      end
    end

  end
  
end
