# for calculating distance of two item

# For a set of same type(measure method) distance,
# a possible range is calculated for any two of them.

# example:
#   if distance(a, c, Type) == 0.1 && distance(b, c, Type) == 0.2
#   then we know 0 <= distance(a, b, Type) <= 0.3

# More info about distance can be found if relationship of Type can be defined meaningfully.


module Wp2jekyll
    # Graph {()}
    class DistanceGraph
        Node = Struct.new(:a, :b, keyword_init: true)

        public

        # add vertex
        def add_v(v)
        end

        # add edge
        def add_e(v1, v2)
        end

        # min distance
        # @return
        #   - [Integer], if a possible minimum length route can be known from graph
        #   - nil, if no such route from v1 to v2 in graph
        def min_dist(v1, v2)
        end

        private
        
    end
end
