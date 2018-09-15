require "test_helper"

require 'parallel'


class ParallelTest < MiniTest::Test
    # make_my_diffs_pretty!
    # include PrettyDiffs
    include Wp2jekyll
    include DebugLogger
    
    def test_parallel
        li = [1,2,3,4,5]
        li_2 = []
        Parallel.map(li, in_threads:3) do |i|
            li_2.append i
        end
        @@logger.debug "li_2 #{li_2}".cyan
        assert(li.sort == li_2.sort)
    end
end