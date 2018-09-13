module Image
    FP_WILDCARD="**/*.{jpg,jpeg,png,gif,svg,bmp}"
    FP_RE=/.*\.(jpg|jpeg|png|gif|svg|bmp)$/

    def self.is_image_fpath?(str)
        nil != (FP_RE =~ str)
    end
end