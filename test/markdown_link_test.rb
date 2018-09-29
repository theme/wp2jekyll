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

  def test_parse4
    str = "[](http://wp.docker.localhost:8000/wp-content/uploads/2016/11/aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093.jpg)"
    assert (nil != MarkdownLink.parse(str))
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

  def test_parse3
    s1 = '''[https://www.chromium.org/developers/design-documents/displaying-a-web-page-in-chrome](https://www.chromium.org/developers/design-documents/displaying-a-web-page-in-chrome "https://www.chromium.org/developers/design-documents/displaying-a-web-page-in-chrome")'''
    s2 = '''[https://www.chromium.org/developers/design-documents/displaying-a-web-page-in-chrome](https://www.chromium.org/developers/design-documents/displaying-a-web-page-in-chrome "https://www.chromium.org/developers/design-documents/displaying-a-web-page-in-chrome")'''

    ast = MarkdownLink.parse_to_ast(s1)
    assert nil != ast
    
    assert_equal(s2, ast.to_s)
  end

  def test_parse3
    str = "![](///home/theme/Downloads/How%20Chromium%20Displays%20Web%20Pages-%20Conceptual%20application%20layers.svg)"
    s2  = "![](///home/theme/Downloads/How%20Chromium%20Displays%20Web%20Pages-%20Conceptual%20application%20layers.svg)"
    ast = MarkdownLink.parse_to_ast(str)
    assert_equal(s2, ast.to_s)
  end

  def test_embeded_link
    txt = "some text [![](http://wp.docker.localhost:8000/wp-content/uploads/2016/12/screenshot-from-2016-12-01-22-43-261.png)](http://wp.docker.localhost:8000/wp-content/uploads/2016/12/screenshot-from-2016-12-01-22-43-261.png)"
    parsed_li = MarkdownLinkParser.new.parse(in_txt:txt)
    url_str_c = 0
    mlink_c = 0
    parsed_li.each { |i|
      @@logger.debug "parsed_li i \n #{i}".white
      if i.is_a? ASTnode
        i.all_c_of_symbol(:URL_STR).each { |url_plain_str_node|
          url_str_c += 1
        }
        i.all_c_of_symbol(:MLINK).each { |mlink_node|
          mlink_c += 1
        }
      end
    }
    assert(2 == url_str_c)
    assert(2 == mlink_c)
  end
end

# ![Alice Liddell]({{ "/wp-content/uploads/2016/11/alice_liddell1.jpg" | relative_url }})
