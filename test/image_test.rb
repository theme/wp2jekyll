require "test_helper"
require "logger"

class ImageTest < MiniTest::Test
  # make_my_diffs_pretty!
  # include PrettyDiffs
  include Wp2jekyll
  
  def test_RE
    assert(Image.is_a_image_url?("http://host.com/path/to/a/img.jpg"))
    assert(Image.is_a_image_url?("https://host.com/path/to/a/img.jpg"))
    assert(Image.is_a_image_url?("ftp://host.com/path/to/a/img.jpg"))
    assert(Image.is_a_image_url?("ftp://host.com/path/to/a/img.jpg?para=value&para2=v2"))
    assert(Image.is_a_image_url?("../path/to/a/img.png"))
    assert(Image.is_a_image_url?("/path/to/a/img.gif"))
    assert(!Image.is_a_image_url?("../path/to/a/img.pdf"))
  end

  def test_bn_in_para
    assert('10050478415.jpg' == Image.basen_in_url('http://ameblo.jp/public/image/displayimage.do?imagePath=/user_images/04/1d/10050478415.jpg'))
  end

end