require 'tempfile'
require 'fileutils'

module Wp2jekyll
  
  class WordpressImporter
    include DebugLogger

    attr_accessor :tasks # calculated tasks, each one describe import of one post

    def initialize
      @tasks = []
    end

    def add_task(fp, to_dir)
      @tasks.append ImportingTask.new(fp:fp, to_dir:to_dir)
    end

    def run_tasks
      @tasks.each { |t|
        puts "\n"
        @@logger.info "import_post #{t.fpath} #{'-->'.green} #{t.jekyll_posts_dir}"
  
        # comvert wordpress markdown to jekyll format
        jkmd_tmp = Tempfile.new('jkmd_tmp')
        FileUtils.cp(t.fpath, jkmd_tmp.path, :verbose => false) # do not touch import source
  
        wpmd_tmp = WordpressMarkdown.new(jkmd_tmp.path)
        wpmd_tmp.write_jekyll_md!

        t.converted_fpli << wpmd_tmp.path
  
        # merge (test if already exists?)
        PostMerger.new.merge_converted_post(t.fpath, t.converted_fpli.last, t.jekyll_posts_dir)
      }
    end

    # populate tasks and run tasks
    def import_post(fpath:, jekyll_posts_dir:)
      add_task(fpath, jekyll_posts_dir)
      run_tasks
    end

    def import_posts_in_dir(wp_exported_posts_dir:, jekyll_posts_dir:)
      if Dir.exist?(wp_exported_posts_dir) then
          Dir.glob(wp_exported_posts_dir + '/**/*.{md,markdown}') do |fpath|
              add_task(fpath, jekyll_posts_dir)
          end
      else
          @@logger.warn "WordpressImporter: No such dir #{wp_exported_posts_dir}".yellow
      end

      run_tasks
    end
  end
end
