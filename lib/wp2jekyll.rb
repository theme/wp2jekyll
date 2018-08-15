require "wp2jekyll/version"

module Wp2jekyll
  require 'wp2jekyll/wp_patch'
  
  def self.process_wordpress_md_dir(d)
    if Dir.exist? d then
      Dir.glob (d + '/**/*.md') do |fpath|
        WordpressMarkdown.new(fpath).to_jekyll_md
      end
    end
  end
  
end
