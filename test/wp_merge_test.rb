require "test_helper"
require "logger"

class TestMergerMarkdownFile < MiniTest::Test
  # make_my_diffs_pretty!
  # include PrettyDiffs
  include Wp2jekyll

  def test_debug
    Post.new(File.expand_path('../sample/post.md', __FILE__)).hint_contents
  end

  def test_compare_date
    fa = File.expand_path('../sample/post.md', __FILE__)
    fb = File.expand_path('../sample/post.md', __FILE__)
    
    assert(PostCompare.new(fa, fb).same_date?)
  end

  def test_diff
    fa = File.expand_path('../sample/post.md', __FILE__)
    fb = File.expand_path('../sample/post 2.md', __FILE__)
    
    assert(PostCompare.new(fa, fb).similar?)
  end

end
