require "test_helper"
require "logger"

class ImageLinkTest < MiniTest::Test
  # make_my_diffs_pretty!
  # include PrettyDiffs
  include Wp2jekyll

  def test_RE
    m = ImageLink::RE.match('{{ "/assets/style.css" | relative_url }}')
    assert(nil != m)
  end
  #
  # def test_RE_https
  #   m = ImageLink.https_re('gumo-766687.jpg').match('http://4.bp.blogspot.com/_vVKXQaa0h-I/RtgU-j6TR7I/AAAAAAAAAJ4/vInSlvEB2-4/s320/gumo-766687.jpg')
  #   assert(nil != m)
  #   m2 = ImageLink.https_re('gumo-766687.jpg').match('https://4.bp.blogspot.com/_vVKXQaa0h-I/RtgU-j6TR7I/AAAAAAAAAJ4/vInSlvEB2-4/s320/gumo-766687.jpg')
  #   assert(nil != m2)
  # end

end