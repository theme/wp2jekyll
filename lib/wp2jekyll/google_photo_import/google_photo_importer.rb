require 'tempfile'
require 'pathname'

module Wp2jekyll
    class GooglePhotoImporter
        include DebugLogger

        def process_posts_dir(posts_dir, image_dir)
            google_photo_client = GooglePhotoClient.new

            Dir.glob(File.join(posts_dir, '**/*.{md,markdown}')).each do |pfp|

                # for each URI in `jk_md`
                # search URI.basename in Google Photo
                # if hit, download photo to temp_f
                # img_merge temp_f into `image_dir`, using `post_date` as prepend path
                # and relink all URI in post to merged image

                im = ImageMerger.new
                jk_md = Post.new(pfp)
                @@logger.info "Import Google Photo for post : #{jk_md.post_info}"
                urls_hash = jk_md.all_urls_hash
                urls_hash.each do |k,v|
                    bn = Image.basen_in_url v

                    if nil != bn
                        @@logger.debug "import image : #{k} => #{v}".yellow
                    else
                        next
                    end

                    if Image.is_img_fn_exist?(bn, image_dir)
                        @@logger.debug "image exist : #{bn}".cyan
                        next
                    end

                    # download
                    tmp_f = Tempfile.new(bn)

                    datestr = jk_md.datef
                    post_date = Date.parse(datestr)
                    prev_year = (post_date << 6).to_s
                    post_year = (post_date >> 6).to_s

                    if nil != google_photo_client.search_and_download(img_fn:bn,
                        from_date:prev_year, to_date:post_year, to_path:tmp_f.path)

                        # merge
                        new_relative_path = post_date.strftime('%Y/%m/%d')
                        im.merge_img_prepend_path(image:tmp_f, rename:bn, to_dir:image_dir, prepend_path:new_relative_path)

                        # jk_md.relink

                        jk_md.relink_image(bn, File.join(File.basename(image_dir), new_relative_path)) # modify link to rel_path/image.jpg
                    end
                end

                jk_md.write

            end
        end

    end
end