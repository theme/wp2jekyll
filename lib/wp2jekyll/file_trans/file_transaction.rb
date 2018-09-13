require 'fileutils'
require 'tempfile'

module Wp2jekyll

    class FileTransaction
        attr_reader :from
        attr_reader :to
        attr_reader :time

        attr_reader :fn

        def initialize(from: nil, to: nil)
            @from = from
            @to = to
            @time = Time.now
            @fn = File.basename(from)
        end

    end

end