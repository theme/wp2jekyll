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
        # Remove the token data from storage for the given ID.
        def delete(_id)
        end

        # @return String
        # Load the token data from storage for the given ID.
        def load(_id)
        end

        # @return Object
        #Put the token data into storage for the given ID.
        def store(_id, _token)
        end

    end
end