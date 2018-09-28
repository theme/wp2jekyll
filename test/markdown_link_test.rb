require "test_helper"
require "logger"

class MarkdonwLinkTest < MiniTest::Test
  # make_my_diffs_pretty!
  # include PrettyDiffs
  include Wp2jekyll
  include DebugLogger

  def test_RE
    str = 'https://host.com/wp-content/uploads/2016/11/alice_liddell1.jpg'
    assert(nil != URI.regexp.match(str))
    assert(nil != MarkdownLinkParser::RE_URI_MOD.match(str))
  end
  
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
    path_str = "/wp-content/uploads/2016/11/alice_liddell1.jpg"
    str = '![Alice Liddell]({{ "' + path_str + '" | relative_url }})'
    # @@logger.debug str.red
    # assert (nil != URI.regexp.match(str))
    assert (nil != MarkdownLinkParser::RE_PATH.match(path_str))
    assert (nil != MarkdownLink.parse(str))
  end
end
# ![Alice Liddell]({{ "/wp-content/uploads/2016/11/alice_liddell1.jpg" | relative_url }})