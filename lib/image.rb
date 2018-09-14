require 'fileutils'

module Image
    include DebugLogger
    FP_WILDCARD = "**/*.{jpg,jpeg,png,gif,svg,bmp}"
    PURE_PATH_RE_STR = '[^\s]*'
    IMG_BN_RE_STR = '[^\/\s]*\.(jpg|jpeg|png|gif|svg|bmp)'
    IMG_BN_RE = Regexp.new(IMG_BN_RE_STR)
    IMG_URL_RE  = Regexp.new(%{((https?|ftp):)?(#{PURE_PATH_RE_STR})?(#{IMG_BN_RE_STR})\??(.*=.*)*$})
    
    ImagePath_RE = Regexp.new(%{imagePath=(#{PURE_PATH_RE_STR}#{IMG_BN_RE_STR})})


    def self.is_a_image_url?(str)
        nil != (IMG_URL_RE =~ str)
    end

    def self.basen_in_url(url)
        if self.is_a_image_url? url
            uri = URI(url)

            # special: image in query params
            li = uri.query.split('&').select {|i| i =~ ImagePath_RE}
            # @@logger.debug li
            # STDIN.gets
            if  li.length > 0
                url = ImagePath_RE.match(url)[1]
                # @@logger.debug url
                # STDIN.gets
            end

            Pathname(URI(url).path).basename.to_s
        else
            nil
        end
    end

    def self.is_img_fn_exist?(img_fn, in_dir)
        Dir.glob(File.join(in_dir, FP_WILDCARD)).each do |fp|
            if fp.include? File.basename(fp)
                return true
            end
        end
        false
    end
end
