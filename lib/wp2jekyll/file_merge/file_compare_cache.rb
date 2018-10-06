
module Wp2jekyll

    class FileCompareCache < FileSimilarityStore

        def initialize
            super
        end

        def record_similarity(a,b,similarity)
            super(a,b,similarity)
        end

        def get_similarity(a,b)
            ca = File.ctime(a)
            cb = File.ctime(b)
            super(a,b, ctime: (ca > cb ? ca : cb))
        end

    end
    
end