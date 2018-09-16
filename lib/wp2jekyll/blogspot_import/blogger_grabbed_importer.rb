require 'fileutils'
require 'logger'
require 'colorize'

module Wp2jekyll
  
  class BloggerGrabbedImporter
    include DebugLogger

    def self.import(grabbed_dir, to_dir, to_img_dir, replace_meta:)
      pm = PostMerger.new

      Dir.glob(File.join(grabbed_dir,'*')).each do |post_dir|
        # read
        blogger_post = BloggerPost.new(post_dir) # post_dir/images files is recorded
        blogger_post.replace_meta(replace_meta)

        # assemble to jekyll markdown
        tmp_fpath = File.join(post_dir, 'jekyll_md')
        # @@logger.debug "assemble jekyll md : #{blogger_post.to_s}".yellow
        blogger_post.post['layout'] = 'post'
        File.write(tmp_fpath, blogger_post.to_s)

        # patch post body format to markdown using wp_import
        WordpressPost.new(tmp_fpath).write_jekyll_md!

        # try import
        pfp = pm.merge_post(tmp_fpath, to_dir) # may be imported, may be not.

        # for post that is now in the to_dir, try import images
        if nil != pfp then
          jk_md = JekyllMarkdown.new(pfp)
          im = ImageMerger.new
          
          # Handles only blogger_post's known images (that are on the disk at initialzing time),
          # missing images will be handled by other separate module later, like google_photo_importer.
          blogger_post.images.each do |i|
            bn = File.basename(i)
            new_relative_path = blogger_post.date.strftime('%Y/%m/%d')
            
            # modify link of image
            # from blog spot magic number path
            # to jekyll/_source/_images/yyyy/mm/dd/basename
            jk_md.relink_image(bn, File.join(File.basename(to_img_dir), new_relative_path)) # modify link to rel_path/image.jpg

            # TODO : for JFIF file with a messed file name that is not end in jpg, add one.

            im.merge_img_prepend_path(image:i, to_dir:to_img_dir, prepend_path:new_relative_path)
          end

          jk_md.write

          # TODO : handle_other images link in jk_md
        end

        File.delete(tmp_fpath)
        
      end

      @@logger.info pm.stat.yellow
    end

  end

end

