require "test_helper"
require "logger"

class JekyllMarkdownTest < MiniTest::Test
  # make_my_diffs_pretty!
  # include PrettyDiffs
  include Wp2jekyll
  include DebugLogger
  
  def test_relink_image
    jkp = JekyllMarkdown.new(File.expand_path('../sample/post relink img.md', __FILE__))
    jkp2 = JekyllMarkdown.new(File.expand_path('../sample/post relink img 2.md', __FILE__))

    jkp.relink_image('relink.jpg', 'parth/to/')

    assert(jkp.to_s == jkp2.to_s)
  end

end