require 'fileutils'
require 'logger'
require 'colorize'

module Wp2jekyll
  
  class BloggerGrabbedImporter
    include DebugLogger

    def import(grabbed_dir, to_dir, to_img_dir)
      Dir.glob(File.join(grabbed_dir,'*')).each do |post_dir|
        # read
        blogger_post = BloggerPost.new(post_dir) # post_dir/images files is recorded

        # assemble to jekyll markdown
        tmp_fpath = File.join(post_dir, 'jekyll_md')
        # @@logger.debug "assemble jekyll md : #{blogger_post.to_s}".yellow
        File.write(tmp_fpath, blogger_post.to_s)

        # patch post body format to markdown using wp_import
        WordpressMarkdown.new(tmp_fpath).write_jekyll_md

        # modify link of image
        # from blog spot magic number path
        # to jekyll/_source/_images/yyyy/mm/dd/basename 
        #
        images_tobe_copy = {}
        jk_md = JekyllMarkdown.new(tmp_fpath)
        blogger_post.images.each do |i| 
          # Handles only blogger_post's known images (that are on the disk at initialzing time),
          # missing images will be handled below.

          bn = File.basename(i)
          new_relative_path = blogger_post.date.strftime('%Y/%m/%d')

          jk_md.relink_image(bn, File.join(File.basename(to_img_dir), new_relative_path))

          i_path = File.dirname(i)
          images_tobe_copy[i] = [to_img_dir, new_relative_path] # to be copied
          @@logger.info "[dbg] import #{i} to #{to_img_dir} with_path #{new_relative_path}" #TODO debug
        end
        # jd_md.write
        @@logger.info jk_md.white

        # import using post
        MarkdownFilesMerger.new.merge_post(Post.new(tmp_fpath), to_dir)
        
        # Do: copy images.
        images_tobe_copy.each do |k,v| 
          @@logger.debug "[dbg] to cp #{k} #{v}"
          # ImageMerger.new.merge_img_with_path(i, v[0], v[1])
        end
      end
    end

  end

end

