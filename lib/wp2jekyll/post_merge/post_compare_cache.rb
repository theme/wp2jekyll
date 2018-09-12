
module Wp2jekyll

    class PostCompareCache

        attr_accessor :cache

        def initialize
            @cache = {}
        end

        def add_same(a, b)
            if nil == @cache[a] then
                @cache[a] = { b => true }
            else
                @cache[a][b] = true
            end
        end

        def add_diff(a, b)
            if nil == @cache[a] then
                @cache[a] = { b => false }
            else
                @cache[a][b] = false
            end
        end

        def same?(a, b)
            if nil != @cache[a] && @cache[a][b] = true
                true
            else
                nil
            end
        end

        def diff?(a, b)
            if nil != @cache[a] && @cache[a][b] = false
                true
            else
                nil
            end
        end
    end
    
end