require "test_helper"
require "logger"

class MediaItemStoreTest < MiniTest::Test
  # make_my_diffs_pretty!
  # include PrettyDiffs
  include Wp2jekyll
  
  def test_JSON
    s = %{
        {
            'a': 'va',
            'b': 'vb',
            'mediaItem': {
                'id': '123'
            }
        }
    }
    assert(JSON.parse(s).is_a? JSON)
  end


end