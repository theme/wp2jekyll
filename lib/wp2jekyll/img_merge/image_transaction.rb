require 'fileutils'
require 'tempfile'

module Wp2jekyll

    class ImageTransaction
        attr_reader :fn
        attr_reader :from
        attr_reader :to

        def initialize(fn:, from: nil, to: nil)
            @filename = fn
            @from = from
            @to = to
        end

    end

end