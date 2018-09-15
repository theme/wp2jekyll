require 'fileutils'

module Image
    include DebugLogger
    FP_WILDCARD = "**/*.{jpg,jpeg,png,gif,svg,bmp}"
    PURE_PATH_RE_STR = '[^\s]*'
    IMG_BN_RE_STR = '[^\/\s]*\.(jpg|jpeg|png|gif|svg|bmp)'
    IMG_BN_RE = Regexp.new(IMG_BN_RE_STR)
    IMG_URL_RE  = Regexp.new(%{((https?|ftp)://)?(#{PURE_PATH_RE_STR})?(#{IMG_BN_RE_STR})(\\?(.+=.+)+)?$})
    
    ImagePath_RE = Regexp.new(%{imagePath=(#{PURE_PATH_RE_STR}#{IMG_BN_RE_STR})})


    def self.is_a_image_url?(str)
        nil != (IMG_URL_RE =~ str)
    end

    def self.is_a_image_fp?(fp)
        self.is_a_image_url? fp
    end

    def self.basen_in_url(url)
        if self.is_a_image_url? url
            begin
                uri = URI(url)
            rescue URI::InvalidURIError
                uri = nil
            end

            if nil != uri
                # special: image in query params
                if nil != uri.query
                    # @@logger.debug uri
                    li = uri.query.split('&').select {|i| i =~ ImagePath_RE}
                    # @@logger.debug li
                    # STDIN.gets
                    if  li.length > 0
                        return File.basename(ImagePath_RE.match(url)[1])
                        # @@logger.debug url
                        # STDIN.gets
                    end
                end
                
                if nil != uri.path
                    bn = File.basename(uri.path)
                    if bn =~ IMG_BN_RE
                        return bn
                    end
                end
            end
        end
        nil
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
