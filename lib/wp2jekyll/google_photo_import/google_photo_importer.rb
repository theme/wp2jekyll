require 'tempfile'
require 'pathname'

module Wp2jekyll
    class GooglePhotoImporter
        include DebugLogger

        attr_reader :google_photo_client

        def initialize
            @google_photo_client = GooglePhotoClient.new
        end

        def process_posts_dir(posts_dir, image_dir)
            Dir.glob(File.join(posts_dir, '**/*.{md,markdown}')).each do |pfp|
                @@logger.debug "... import Google Photo for post : #{pfp}"

                # for each URI in `jk_md`
                # search URI.basename in Google Photo
                # if hit, download photo to temp_f
                # img_merge temp_f into `image_dir`, using `post_date` as prepend path
                # and relink all URI in post to merged image

                im = ImageMerger.new
                jk_md = Post.new(pfp)
                urls_hash = jk_md.extract_urls_hash
                urls_hash.each do |k,v|
                    begin
                        uri = URI(v)
                    rescue ArgumentError => e
                        @@logger.debug "#{e} , v=#{v}, urls_hash : #{urls_hash.inspect}".red
                        next
                    end

                    @@logger.debug "import image for : #{k} => #{v}".yellow
                    
                    # if v is image
                    bn = Pathname(uri).basename.to_s
                    if im.is_img_exist(bn, image_dir)
                        @@logger.debug "image exist : #{bn}"
                        next
                    end

                    # download
                    tmp_f = Tempfile.new(bn)
                    if nil != @google_photo_client.search_and_download(img_fn:bn, to_path:tmp_f) # TODO
                        # merge
                        new_relative_path = jk_md.date.strftime('%Y/%m/%d')
                        im.merge_img_prepend_path(image:temp_f, to_dir:image_dir, prepend_path:new_relative_path)

                        # jk_md.relink
                        jk_md.relink_image(bn, File.join(File.basename(image_dir), new_relative_path)) # modify link to rel_path/image.jpg
                    end
                end

                jk_md.write

            end
        end

    end
end