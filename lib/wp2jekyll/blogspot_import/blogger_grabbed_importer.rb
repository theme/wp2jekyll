require 'fileutils'
require 'logger'
require 'colorize'

module Wp2jekyll
  
  class BloggerGrabbedImporter
    @@logger = Logger.new(STDERR)
    @@logger.level = Logger::DEBUG

    def import(grabbed_dir, to_dir, to_img_dir)
      Dir.glob(File.join(grabbed_dir,'*')).each do |post_dir|
        # read
        blogger_post = BloggerPost.new
        blogger_post.read_grabbed_post_dir(post_dir)

        # assemble to jekyll markdown
        tmp_fpath = File.join(post_dir, 'jekyll_md')
        # @@logger.debug "assemble jekyll md : #{blogger_post.to_s}".yellow
        File.write(tmp_fpath, blogger_post.to_s)

        # patch post body format to markdown using wp_patch
        WordpressMarkdown.new(tmp_fpath).write_jekyll_md

        # modify link of image
        # from blog spot magic number path
        # to jekyll/_source/_images/yyyy/mm/dd/basename 
        #
        images_tobe_copy = {}
        blogger_post.images.each do |i|
          d = Date.parse(blogger_post.date_str)
          bn = File.basename(i)
          jk_md = JekyllMarkdown.new(tmp_fpath)
          new_relative_path = d.strftime('%Y/%m/%d')
          jk_md.relink_image(bn, new_relative_path)
          # jd_md.write
          jk_md.info # TODO debug

          i_path = File.dirname(i)
          images_tobe_copy[i] = [to_img_dir, new_relative_path] # to be copied
          @@logger.info "[dbg] import #{i} to #{to_img_dir} with_path #{new_relative_path}" #TODO debug
        end

        # import using post
        MarkdownFilesMerger.new.merge_post(Post.new(tmp_fpath), to_dir)
        
        # Do: copy images.
        images_tobe_copy.each do |k,v| 
          @@logger.debug "to cp #{k} #{v}"
          # ImageMerger.new.merge_img_with_path(i, v[0], v[1])
        end
      end
    end

  end

end

