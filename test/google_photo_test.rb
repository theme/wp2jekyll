require "test_helper"
require "logger"

class ImageLinkTest < MiniTest::Test
  # make_my_diffs_pretty!
  # include PrettyDiffs
  include Wp2jekyll

  def test_search_img_id
    img_fn = '1600FG100_029.jpg'
    client = GooglePhotoClient.new
    assert(client.search_img_id(img_fn, Date.parse("2005-06-01")))
  end


end