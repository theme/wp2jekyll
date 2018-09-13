
module Wp2jekyll

    class PostCompareCache

        attr_accessor :cache

        def initialize
            @cache = {}
        end

        def record_similarity(a,b,similarity)
            if nil == @cache[a] then
                @cache[a] = { b => similarity }
            else
                @cache[a][b] = similarity
            end
        end

        def get_similarity(a,b)
            if nil != @cache[a]
                @cache[a][b]
            else
                nil
            end
        end
    end
    
end