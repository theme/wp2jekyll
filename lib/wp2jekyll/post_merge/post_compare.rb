require 'fileutils'
require 'logger'
require 'colorize'
require 'diff/lcs'

module Wp2jekyll
  class UncertainSimilarityError < StandardError
    attr_reader :a
    attr_reader :b
    attr_reader :user_judge

    def initialize(msg:, a:, b:, user_judge:)
      super msg
      @user_judge = user_judge
      @a = a
      @b = b
    end
  end

  class PostCompare
    include DebugLogger

    SIMILAR_LV_USER_SAME = 2.0

    SIMILAR_LV_AUTO = 0.9

    SIMILAR_LV_HINT = 0.618

    SIMILAR_LV_USER_DIFF = -1.0

    attr_reader :a
    attr_reader :b
    attr_accessor :similarity

    attr_accessor :pa
    attr_accessor :pb

    attr_accessor :user_judge
    
    @@cache = PostCompareCache.new

    def initialize(a, b)
      @a = a
      @b = b
      @similarity = nil
    end

    def pa
      @pa || @pa = Post.new(@a)
    end

    def pb
      @pb || @pb = Post.new(@b)
    end

    def ask_usr_same?
      puts "- #{@a}".yellow
      pa.hint_contents
      puts "+ #{@b}".yellow
      pb.hint_contents

      user_input = ''
      until user_input == 'y' || user_input == 'n' do
        puts "Regards them as the same post ?".yellow
        user_input = STDIN.getc
        STDIN.gets # flush
      end

      case user_input
      when 'y' then
        @@cache.record_similarity(@a, @b, SIMILAR_LV_USER_SAME)
        @user_judge = true
      when 'n' then
        @@cache.record_similarity(@a, @b, SIMILAR_LV_USER_DIFF)
        @user_judge = false
      end
    end

    def get_similarity
      # query cache
      s = @@cache.get_similarity(@a, @b)
      if nil != s
        return s
      end

      # quick check
      if pa.date_str == pb.date_str && pa.title == pb.title
        @@cache.record_similarity(@a, @b, SIMILAR_LV_USER_SAME)
        return SIMILAR_LV_USER_SAME
      end

      # body diff
      lcs = Diff::LCS.lcs(pa.body_str, pb.body_str)
      similarity = lcs.length * 1.0 / [pa.body_str.length, pb.body_str.length].max
      @@cache.record_similarity(@a, @b, similarity)
      return similarity
    end

    def similar?
      s = @@cache.get_similarity(@a, @b)
      if nil == s
        s = get_similarity
      end
      # report result
      if SIMILAR_LV_AUTO <= s
        return true
      elsif (SIMILAR_LV_HINT < s) && (s < SIMILAR_LV_AUTO)
        ask_usr_same?
        raise UncertainSimilarityError.new(msg:"Uncertain similar posts", a:@a, b:@b, user_judge:@user_judge)
      else # similarity < SIMILAR_LV_HINT
        return false
      end
      
    end

  end
end