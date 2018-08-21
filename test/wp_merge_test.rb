require "test_helper"
require "logger"

class TestPatchingRegex < MiniTest::Test
  make_my_diffs_pretty!
  include PrettyDiffs
  include Wp2jekyll

  def test_debug
    MarkdownFilesMerger.new.hint_post_contents(File.expand_path('../sample/post.md', __FILE__))
  end

  def test_debug
    fa = File.expand_path('../sample/post.md', __FILE__)
    fb = File.expand_path('../sample/post.md', __FILE__)
    
    assert(MarkdownFilesMerger.new.is_post_same_date(fa, fb))
  end

  def test_diff
    fa = File.expand_path('../sample/post.md', __FILE__)
    fb = File.expand_path('../sample/post 2.md', __FILE__)
    
    assert(!MarkdownFilesMerger.new.is_post_similar(fa, fb))
  end

end
