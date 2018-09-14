module Image
    FP_WILDCARD="**/*.{jpg,jpeg,png,gif,svg,bmp}"
    IMG_URL_RE=/((https?|ftp):)?([^\s]*)?(\.|\/)*([^\s]*)(jpg|jpeg|png|gif|svg|bmp)\??(.*=.*)*$/

    def self.is_a_image_url?(str)
        nil != (IMG_URL_RE =~ str)
    end
end