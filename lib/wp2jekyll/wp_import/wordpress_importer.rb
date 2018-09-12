require 'tempfile'
require 'fileutils'

module Wp2jekyll
  
    class WordpressImporter
      include DebugLogger
        
      def import_post(fpath:, jekyll_posts_dir:)
        # comvert wordpress markdown to jekyll format
        jkmd_tmp = Tempfile.new('jkmd_tmp')
        FileUtils.cp(fpath, jkmd_tmp.path, :verbose => false)
        wpmd_tmp = WordpressMarkdown.new(jkmd_tmp.path)
        wpmd_tmp.write_jekyll_md!

        # merge (test if already exists?)
        PostMerger.new.merge_post(Post.new(jkmd_tmp.path), jekyll_posts_dir)
      end

      def import_posts_in_dir(wp_exported_posts_dir:, jekyll_posts_dir:)
        if Dir.exist?(wp_exported_posts_dir) then
            Dir.glob(wp_exported_posts_dir + '/**/*.{md,markdown}') do |fpath|
                import_post(fpath: fpath, jekyll_posts_dir: jekyll_posts_dir)
            end
        else
            @@logger.warn "WordpressImporter: No such dir #{wp_exported_posts_dir}".yellow
        end
      end
      
    end
end