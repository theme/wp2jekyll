
module Wp2jekyll

    # calculated tasks, each one describe import of one post
    class ImportingTask

        attr_accessor :src_fp # source file path
        attr_accessor :converted_fpli # [String] of converted file path

        attr_accessor :dst_dir # directory into which src_fp file will be imported
        attr_accessor :dst_fp

        attr_accessor :status # :new | :converting | :skip | :imported

        def initialize(fp:, to_dir:)
            if !Dir.exist? to_dir
                raise RuntimeError.new "error init ImportingTask. destination dir does not exist: #{to_dir}"
            end
            if !File.exist? fp
                raise RuntimeError.new "error init ImportingTask. source file does not exist: #{fp}"
            end

            @src_fp = fp
            @converted_fpli = []
            @dst_dir = to_dir
            @dst_fp = File.join(File.dirname(to_dir), File.basename(src_fp))
            @status = :new
        end

        def fpath
            @src_fp
        end

        def jekyll_posts_dir
            @dst_dir
        end

    end

end