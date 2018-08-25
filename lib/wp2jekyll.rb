require "wp2jekyll/version"

module Wp2jekyll
  require 'wp2jekyll/wp_patch'
  require 'wp2jekyll/post_merge'
  
  def self.process_wordpress_md_dir(d)
    if Dir.exist? d then
      Dir.glob (d + '/**/*.md') do |fpath|
        WordpressMarkdown.new(fpath).to_jekyll_md
      end
    end
  end
  
  def self.merge_other_wordpress_md_dir(d, src_dir)

    if Dir.exist? d then
      Dir.glob (d + '/**/*.md') do |fpath|
        # TODO judge File(fpath) similarity to existing source md file
        WordpressMarkdown.new(fpath).to_jekyll_md
      end
    end
    
  end
  
end
