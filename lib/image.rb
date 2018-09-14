require 'fileutils'

module Image
    FP_WILDCARD="**/*.{jpg,jpeg,png,gif,svg,bmp}"
    IMG_URL_RE=/((https?|ftp):)?([^\s]*)?(\.|\/)*([^\s]*)(jpg|jpeg|png|gif|svg|bmp)\??(.*=.*)*$/

    def self.is_a_image_url?(str)
        nil != (IMG_URL_RE =~ str)
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