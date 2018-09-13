require 'fileutils'
require 'tempfile'

module Wp2jekyll

    class FileTransactionHistory
        attr_accessor :his

        def initialize
            @his = []
        end

        def add(from: nil, to: nil)
            @his.append FileTransaction.new(from: from, to: to)
        end

        def has_trans?(fn)
            @his.each do |r|
                if File.basename(fn) == r.fn && nil != r.to
                    return true
                end
            end
            false
        end

        def has_skip?(fn)
            @his.each do |r|
                if File.basename(rn) == r.fn && nil == r.to
                    return true
                end
            end
            false
        end

        def length
            @his.length
        end
    end

end