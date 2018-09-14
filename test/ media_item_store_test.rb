require "test_helper"
require "logger"

class MediaItemStoreTest < MiniTest::Test
  # make_my_diffs_pretty!
  # include PrettyDiffs
  include Wp2jekyll
  
  def test_JSON
    s = %{
        {
            "a": "va",
            "b": "vb",
            "mediaItem": {
                "id": 123
            },
            "array": [7,6,5],
            "true" : true,
            "false" : false,
            "null" : null
        }
    } 
    o = JSON.parse(s)
    assert(o.is_a? Object)
    assert(o['a'] == 'va')
    assert(o['array'] == [7, 6, 5])
    assert(o['true'] == true)
    assert(o['false'] == false)
    assert(o['null'] == nil)
    assert(o['mediaItem']['id'] == 123)
  end


end
