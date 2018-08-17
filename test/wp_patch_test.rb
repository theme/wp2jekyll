require "test_helper"
require "logger"

#
# This test file contains invisibal characters
# They are necessary, DO NOT FORMAT this file.
#

class TestPatchingRegex < MiniTest::Test
  make_my_diffs_pretty!
  include PrettyDiffs
  include Wp2jekyll
    def test_patch_code
        # a invisible character is there, DO NOT FORMAT
        s1 = '''
        [code]

         int a = sqrt(b);

    print(a);

      print(b);

   [/code]

   some text

   other code:
        [code]

         #int a = sqrt(b);

    console.log(a);

      console.log(b);

   [/code]
        '''
        # targeted effect
        s2 = '''
        
        int a = sqrt(b);
        
        print(a);
        
        print(b);



   some text

   other code:
        
        #int a = sqrt(b);
        
        console.log(a);
        
        console.log(b);


        '''
        assert_equal(s2, WordpressMarkdown.new.patch_code(s1))
    end

    def test_patch_quote
        s1 = '''
1 paragraph
> TCP fast open （TFO）
> ===================
2 paragraph
> other quotes
> other quotes
3 paragraph
> lost a >
  
> some
4 p
5 text should not be effected
  
5 text should not be effected
        '''
        # targeted effect
        s2 = '''
1 paragraph

> TCP fast open （TFO）
> ===================

2 paragraph

> other quotes
> other quotes

3 paragraph

> lost a >
>
> some

4 p
5 text should not be effected
  
5 text should not be effected
        '''
        assert_equal(s2, WordpressMarkdown.new.patch_quote(s1))
    end

    def test_unescape_xml_char
        s1 = '&lt; ' # targeted effect
        s2 = '< '
        assert_equal(s2, WordpressMarkdown.new.patch_unescape_xml_char(s1))
    end

    def test_patch_h1h2_space
        s1 = """
H1 title
  
========

some text

h2 title
  
--------

some other text
"""
        s2 = """
H1 title
========

some text

h2 title
--------

some other text
"""
        assert_equal(s2, WordpressMarkdown.new.patch_h1h2_space(s1))
    end

    def test_xml_figure_to_md_s
      s1 = '<figure id="attachment_1133" style="width: 400px" class="wp-caption aligncenter">[<img class="wp-image-1133 size-full" src="http://wp.docker.localhost:8000/wp-content/uploads/2016/11/alice_liddell1.jpg" alt="alice_liddell" width="400" height="500" srcset="http://wp.docker.localhost:8000/wp-content/uploads/2016/11/alice_liddell1.jpg 400w, http://wp.docker.localhost:8000/wp-content/uploads/2016/11/alice_liddell1-240x300.jpg 240w" sizes="(max-width: 400px) 85vw, 400px" />](http://wp.docker.localhost:8000/wp-content/uploads/2016/11/alice_liddell1.jpg)<figcaption class="wp-caption-text">Alice Liddell</figcaption></figure>
      <figure id="attachment_1133" style="width: 400px" class="wp-caption aligncenter">[<img class="wp-image-1133 size-full" src="http://wp.docker.localhost:8000/wp-content/uploads/2016/11/alice_liddell1.jpg" alt="alice_liddell" width="400" height="500" srcset="http://wp.docker.localhost:8000/wp-content/uploads/2016/11/alice_liddell1.jpg 400w, http://wp.docker.localhost:8000/wp-content/uploads/2016/11/alice_liddell1-240x300.jpg 240w" sizes="(max-width: 400px) 85vw, 400px" />](http://wp.docker.localhost:8000/wp-content/uploads/2016/11/alice_liddell1.jpg)<figcaption class="wp-caption-text">Alice Liddell</figcaption></figure>'
      s2 = '![Alice Liddell]({{ "/wp-content/uploads/2016/11/alice_liddell1.jpg" | relative_url }})
![Alice Liddell]({{ "/wp-content/uploads/2016/11/alice_liddell1.jpg" | relative_url }})'
      assert_equal(s2, WordpressMarkdown.new.str_patch_group(s1))
    end

    def test_xml_in_md_img_cap
        s1 = '''[<img class="aligncenter size-full wp-image-1153" src="http://wp.docker.localhost:8000/wp-content/uploads/2016/12/screenshot-from-2016-12-01-22-43-261.png" alt="screenshot-from-2016-12-01-22-43-26" width="659" height="367" srcset="http://wp.docker.localhost:8000/wp-content/uploads/2016/12/screenshot-from-2016-12-01-22-43-261.png 659w, http://wp.docker.localhost:8000/wp-content/uploads/2016/12/screenshot-from-2016-12-01-22-43-261-300x167.png 300w" sizes="(max-width: 709px) 85vw, (max-width: 909px) 67vw, (max-width: 984px) 61vw, (max-width: 1362px) 45vw, 600px" />](http://wp.docker.localhost:8000/wp-content/uploads/2016/12/screenshot-from-2016-12-01-22-43-261.png)'''

        s2 = '[![screenshot-from-2016-12-01-22-43-26]({{ "/wp-content/uploads/2016/12/screenshot-from-2016-12-01-22-43-261.png" | relative_url }})]({{ "/wp-content/uploads/2016/12/screenshot-from-2016-12-01-22-43-261.png" | relative_url }})'

        assert_equal(s2, WordpressMarkdown.new.str_patch_group(s1))
    end

    def test_rm_bug_img
        s1 = '''![](///home/theme/Downloads/How%20Chromium%20Displays%20Web%20Pages-%20Conceptual%20application%20layers.svg)'''
        s2 = ''

        assert_equal(s2, WordpressMarkdown.new.md_modify_link(s1))
    end

    def test_patch_link_bug
        s1 = '''[https://www.chromium.org/developers/design-documents/displaying-a-web-page-in-chrome](https://www.chromium.org/developers/design-documents/displaying-a-web-page-in-chrome "https://www.chromium.org/developers/design-documents/displaying-a-web-page-in-chrome"){.https}'''
        s2 = '''[https://www.chromium.org/developers/design-documents/displaying-a-web-page-in-chrome](https://www.chromium.org/developers/design-documents/displaying-a-web-page-in-chrome "https://www.chromium.org/developers/design-documents/displaying-a-web-page-in-chrome")'''

        assert_equal(s2, WordpressMarkdown.new.md_modify_link(s1))
    end

    def test_keep_normal_link
      s1 = '![](https://some.site.com/path/to/a.jpg)'
      s2 = '![](https://some.site.com/path/to/a.jpg)'

      assert_equal(s2, WordpressMarkdown.new.str_patch_group(s1))
    end

    def test_keep_jekyll_filter
      s1 = '![]( {{ "https://some.site.com/path/to/a.jpg" | relative_url }})'
      s2 = '![]( {{ "https://some.site.com/path/to/a.jpg" | relative_url }})'

      assert_equal(s2, WordpressMarkdown.new.str_patch_group(s1))
      assert_equal(s2, WordpressMarkdown.new.line_patch_group(s1))
    end

    def test_patch_body_seimi_jekyll_code
      s1 = 'some body text 1 = {{}} is axiom set'
      s2 = 'some body text 1 = { {} } is axiom set'

      assert_equal(s2, WordpressMarkdown.new.line_patch_group(s1))
    end

    def test_patch_xml_escape_char
      s1 = '&nbsp;'
      s2 = ''
      assert_equal(s2, WordpressMarkdown.new.line_patch_group(s1))
    end

    def test_patch_xml_escape_char2
      s1 = '''passage
      &nbsp;
      passage2'''

      s2 = '''passage

      passage2'''
      assert_equal(s2, WordpressMarkdown.new.line_patch_group(s1))
    end

    def test_p_unfold_divs
      s1 = '''
      <div id="some id" class="bvMsg">
  <div>
        passage 1
  </div>
  
  <div>
        passage 2
  </div>
</div> '''

      s2 ='''
        passage 1

        passage 2
'''
      assert_equal(s2, WordpressMarkdown.new.xml_to_md(s1))
    end

    def test_whole_md
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

[![aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093]({{ "/wp-content/uploads/2016/11/aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093.jpg" | relative_url }})]({{ \"/wp-content/uploads/2016/11/aria-vaneleef-from-girlish-grimoire-littlewitch-romanesque-4758-836436093.jpg\" | relative_url }})

EOS
      logger = Logger.new(STDERR)
      # @logger.level = Logger::INFO
      logger.level = Logger::DEBUG
      # DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN

      logger.debug "############ test_whole_md ##############"
      wm = WordpressMarkdown.new
      tmp = ''
      md.each_line do |line|
        tmp += wm.line_patch_group(line) # special chars
      end
      tmp = wm.str_patch_group(tmp) # xml elements

      assert_equal(md_patched.inspect, tmp.inspect)
      # assert_equal(md_patched, WordpressMarkdown.new.xml_to_md(md))
      logger.debug "############ end test_whole_md ##############"
    end

    def test_xml_table_a_img
      xml = <<EOS
    CLANNAD的图：
    
    <table cellspacing="0" border="0">
      <tr>
        <td>
        </td>
      </tr>
      
      <tr>
        <td valign="top">
          <a href="http://byfiles.storage.live.com/y1pOuOqrLjYZXwQLQQHARHtgE9ceFr1Ko7xiFewupeHyffx_ZL94_xQTGhktuaLMECX1eZxq8yhMOU" target="_blank" rel="WLPP;url=http://byfiles.storage.live.com/y1pOuOqrLjYZXwQLQQHARHtgE9ceFr1Ko7xiFewupeHyffx_ZL94_xQTGhktuaLMECX1eZxq8yhMOU;cnsid=cns&#033;61AD2A9245CB7941&#033;476"><img src="http://byfiles.storage.live.com/y1pOuOqrLjYZXwQLQQHARHtgKJiLCjb5pTGW5H7oVR85NNxTi8Y-XtMitykXZ6KiV_cQS5gkjpzuz8" border="0" /></a>
        </td>
        
        <td width="15">
        </td>
        
        <td valign="top">
          <a href="http://byfiles.storage.live.com/y1pOuOqrLjYZXxSr9_K-pT1-C5LTIzg3WLyMIV2Z75Swyki7cHOZzJ822mOEbDmERFtutZVR7lZc4A" target='_blank' rel="WLPP;url=http://byfiles.storage.live.com/y1pOuOqrLjYZXxSr9_K-pT1-C5LTIzg3WLyMIV2Z75Swyki7cHOZzJ822mOEbDmERFtutZVR7lZc4A;cnsid=cns&#033;61AD2A9245CB7941&#033;477"><img src="http://byfiles.storage.live.com/y1pOuOqrLjYZXxSr9_K-pT1-LxobLZDNk3ngbFhU69Eu3RAGD8TeHISQMbvuerQ6snf5AcNuKCGvCc" border="0" /></a>
        </td>
      </tr>
    </table>
EOS
    md = <<EOS
    CLANNAD的图：
    | [![](http://byfiles.storage.live.com/y1pOuOqrLjYZXwQLQQHARHtgKJiLCjb5pTGW5H7oVR85NNxTi8Y-XtMitykXZ6KiV_cQS5gkjpzuz8)](http://byfiles.storage.live.com/y1pOuOqrLjYZXwQLQQHARHtgE9ceFr1Ko7xiFewupeHyffx_ZL94_xQTGhktuaLMECX1eZxq8yhMOU) | [![](http://byfiles.storage.live.com/y1pOuOqrLjYZXxSr9_K-pT1-LxobLZDNk3ngbFhU69Eu3RAGD8TeHISQMbvuerQ6snf5AcNuKCGvCc)](http://byfiles.storage.live.com/y1pOuOqrLjYZXxSr9_K-pT1-C5LTIzg3WLyMIV2Z75Swyki7cHOZzJ822mOEbDmERFtutZVR7lZc4A) 
EOS
    assert_equal(md, WordpressMarkdown.new.xml_to_md(xml))

    end

end

