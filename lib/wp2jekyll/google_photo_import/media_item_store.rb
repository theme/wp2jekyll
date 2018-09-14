# TODO : save / load JSON


require 'json'

module Wp2jekyll

    class MediaItemStore
        
        attr_reader :store_file
        attr_reader :json_h

        def initialize(store_file)
            @store_file = store_file

            f = File.new(store_file, 'a+')
            @json_h = JSON.load(f)
            if nil == @json_h
                @json_h = {}
            end
            f.close
        end

        # @return [Hash]
        # Remove the json data from storage for the given ID.
        def delete(_id)
            o = @json_h[_id]
            @json_h.delete(_id)
            write_file
            o
        end

        # @return [Hash]
        # Load the json data from storage for the given ID.
        def load(_id)
            @json_h[_id]
        end

        # @return [Hash]
        # Put the json data into storage for the given ID.
        def store(_id, _hash)
            @json_h[_id] = _hash
            write_file # TODO: delay write
        end

        def write_file
            File.write(@store_file,JSON.dump(@json_h))
        end

    end
end
