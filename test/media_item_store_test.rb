require "test_helper"
require "logger"
require "fileutils"

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

  def test_store_file
    f = File.expand_path('../sample/json_store.json', __FILE__)
    mis = MediaItemStore.new(f)

    assert(mis.load('a') == 'va')

    h = {
        "id" => 44534,
        "type" => "photo",
        "url" => "https://host.domain/path/to/fn.jpg" 
    }

    mis.store('test_store_id', h)

    assert(mis.load('test_store_id')['id'] == 44534)

    assert(mis.delete('test_store_id')['id'] == 44534)

  end

end
