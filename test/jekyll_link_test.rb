require "test_helper"
require "logger"

class JekyllLink < MiniTest::Test
  # make_my_diffs_pretty!
  # include PrettyDiffs
  include Wp2jekyll

  def test_RE
    m = JekyllLink::RE.match('{{ "/assets/style.css" | relative_url }}')
    assert(nil != m)
  end


end

