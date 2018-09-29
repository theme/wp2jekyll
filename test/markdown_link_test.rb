require "test_helper"
require "logger"

class MarkdonwLinkTest < MiniTest::Test
  # make_my_diffs_pretty!
  # include PrettyDiffs
  include Wp2jekyll
  include DebugLogger

  @@wp = WordpressPost.new(File.expand_path('../sample/post.md', __FILE__))

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
    @@logger.debug "test_embeded_link".white
    txt = 'some text [![aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093](http://wp.docker.localhost:8000/wp-content/uploads/2016/11/aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093.jpg)](http://wp.docker.localhost:8000/wp-content/uploads/2016/11/aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093.jpg)'
    # txt = "some text [![](http://wp.docker.localhost:8000/wp-content/uploads/2016/12/screenshot-from-2016-12-01-22-43-261.png)](http://wp.docker.localhost:8000/wp-content/uploads/2016/12/screenshot-from-2016-12-01-22-43-261.png)"
    parsed_li = MarkdownLinkParser.new.parse(in_txt:txt)
    url_str_c = 0
    mlink_c = 0
    parsed_li.each { |i|
      @@logger.debug "parsed_li i \n #{i}".white
      if i.is_a? ASTnode
        i.all_c_of_symbol(:URL_STR).each { |url_plain_str_node|

        @@logger.debug "URL_STR in i \n #{url_plain_str_node}".white
          url_str_c += 1
        }
        i.all_c_of_symbol(:MLINK).each { |mlink_node|

        @@logger.debug "MLINK in i \n #{mlink_node}".white
          mlink_c += 1
        }
      end
    }
    assert(2 == url_str_c)
    assert(2 == mlink_c)
    # @@logger.debug "after modify_md_link \n #{@@wp.modify_md_link(txt)}".white
    # @@logger.debug "after process_md! \n #{@@wp.process_md!(txt)}".white

    @@logger.debug "\n\n"
  end

  def test_process_md
    @@logger.debug "test_process_md".white
    md_pieces =  '![Alice Liddell]({{ "/wp-content/uploads/2016/11/alice_liddell1.jpg" | relative_url }})

会想到 Littlewitch 吧

[![aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093]({{ "/wp-content/uploads/2016/11/aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093.jpg" | relative_url }})](http://wp.docker.localhost:8000/wp-content/uploads/2016/11/aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093.jpg)'
    @@logger.debug "test process_md! \n #{@@wp.process_md!(md_pieces)}".white
  end


  def test_whole_md
    @@logger.debug "test_whole_md ---------------".white
    md = <<EOS
---
id: 1132
title: 'Alice&#8217;s Adventures in Wonderland'
date: 2016-11-15T23:29:18+00:00
author: theme
layout: post
guid: http://wordpress-gits.rhcloud.com/?p=1132
permalink: /?p=1132
original_post_id:
- "1132"
categories:
- ACG
tags:
- Littlewitch
---
<figure id="attachment_1133" style="width: 400px" class="wp-caption aligncenter">[<img class="wp-image-1133 size-full" src="http://wp.docker.localhost:8000/wp-content/uploads/2016/11/alice_liddell1.jpg" alt="alice_liddell" width="400" height="500" srcset="http://wp.docker.localhost:8000/wp-content/uploads/2016/11/alice_liddell1.jpg 400w, http://wp.docker.localhost:8000/wp-content/uploads/2016/11/alice_liddell1-240x300.jpg 240w" sizes="(max-width: 400px) 85vw, 400px" />](http://wp.docker.localhost:8000/wp-content/uploads/2016/11/alice_liddell1.jpg)<figcaption class="wp-caption-text">Alice Liddell</figcaption></figure>

会想到 Littlewitch 吧

[<img class="aligncenter size-full wp-image-1140" src="http://wp.docker.localhost:8000/wp-content/uploads/2016/11/aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093.jpg" alt="aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093" width="375" height="543" srcset="http://wp.docker.localhost:8000/wp-content/uploads/2016/11/aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093.jpg 375w, http://wp.docker.localhost:8000/wp-content/uploads/2016/11/aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093-207x300.jpg 207w" sizes="(max-width: 375px) 85vw, 375px" />](http://wp.docker.localhost:8000/wp-content/uploads/2016/11/aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093.jpg)

EOS

    md_patched = <<EOS
---
id: 1132
title: 'Alice’s Adventures in Wonderland'
date: 2016-11-15T23:29:18+00:00
author: theme
layout: post
guid: http://wordpress-gits.rhcloud.com/?p=1132
permalink_wp: /?p=1132
original_post_id:
- "1132"
categories:
- ACG
tags:
- Littlewitch
---
![Alice Liddell]({{ "/wp-content/uploads/2016/11/alice_liddell1.jpg" | relative_url }})

会想到 Littlewitch 吧

[![aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093]({{ "/wp-content/uploads/2016/11/aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093.jpg" | relative_url }})]({{ "/wp-content/uploads/2016/11/aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093.jpg" | relative_url }})

EOS
    wm = @@wp
    tmp = wm.process_md!(md) # xml elements
    # tmp = wm.patch_char(tmp)

    # assert_equal(md_patched.inspect, tmp.inspect)
    assert_equal(md_patched, tmp)
  end

end
