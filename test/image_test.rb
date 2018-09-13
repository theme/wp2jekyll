require "test_helper"
require "logger"

class ImageTest < MiniTest::Test
  # make_my_diffs_pretty!
  # include PrettyDiffs
  include Wp2jekyll
  
  def test_RE
    assert(Image.is_image_fpath?("http://host.com/path/to/a/img.jpg"))
    assert(Image.is_image_fpath?("../path/to/a/img.png"))
    assert(Image.is_image_fpath?("/path/to/a/img.gif"))
  end


end