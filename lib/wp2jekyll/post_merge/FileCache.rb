require 'fileutils'

module Wp2jekyll
  class FileCache
    attr_accessor :cache
    def initialize
      @cache = {}
    end

    def read(fpath)
      if !@cache.has_key?(fpath)
        @cache[fpath] = File.read(fpath)
      end
      @cache[fpath]
    end

    def write(fpath, content)
      # delete item
      @cache.delete(fpath)
      # write through
      File.write(fpath, content)
    end
  end
end

