# TODO : save / load JSON

require 'json'

module Wp2jekyll

    class MediaItemStore
        
        attr_reader :store_file
        attr_reader :json

        def initialize(store_file)
            @store_file = store_file
            @json = JSON.load(File.read(store_file))
        end

        # @return Object
        # Remove the json data from storage for the given ID.
        def delete(_id)
        end

        # @return String
        # Load the json data from storage for the given ID.
        def load(_id)
        end

        # @return Object
        #Put the json data into storage for the given ID.
        def store(_id, _json)
        end

    end
end