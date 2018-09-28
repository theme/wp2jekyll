require "test_helper"
require "logger"

class MarkdonwLinkTest < MiniTest::Test
  # make_my_diffs_pretty!
  # include PrettyDiffs
  include Wp2jekyll
  include DebugLogger
  
  def test_parse
    str = '![cap string](http://path/to/file.jpg "title string"){.tail}'
    mdlk = MarkdownLink.parse str
    assert(nil != mdlk)
    assert(mdlk.cap == 'cap string')
    assert(mdlk.link == 'http://path/to/file.jpg')
    assert(mdlk.title == 'title string')
    assert(mdlk.tail == '.tail')
  end

  def test_parse2
    assert (nil != MarkdownLink.parse('![Alice Liddell]({{ \"/wp-content/uploads/2016/11/alice_liddell1.jpg\" | relative_url }})'))
  end
end
