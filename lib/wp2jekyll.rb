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

  require 'wp2jekyll/wp_import'
  require 'wp2jekyll/google_photo_import'
  require 'wp2jekyll/blogspot_import'
  
  def self.process_wordpress_md_dir(d)
    if Dir.exist? d then
      Dir.glob (d + '/**/*.md') do |fpath|
        WordpressMarkdown.new(fpath).write_jekyll_md
      end
    end
  end
  
end
