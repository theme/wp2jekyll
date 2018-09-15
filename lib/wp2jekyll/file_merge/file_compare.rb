require 'fileutils'

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

  class FileCompare
    include DebugLogger

    SIMILAR_LV_USER_SAME = 2.0

    SIMILAR_LV_AUTO = 0.9

    SIMILAR_LV_HINT = 0.618

    SIMILAR_LV_USER_DIFF = -1.0

    attr_reader :a
    attr_reader :b
    attr_accessor :similarity

    attr_accessor :fa
    attr_accessor :fb

    attr_accessor :user_judge
    
    @@cache = FileCompareCache.new

    def initialize(a, b)
      @a = a
      @b = b
      @fa = File.new(@a)
      @fb = File.new(@b)
      @similarity = nil
    end

    def ask_usr_same?
      puts "- #{@a}".yellow
      @fa.hint_contents #TODO
      puts "+ #{@b}".yellow
      @fb.hint_contents #TODO

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

    def binary_similarity #TODO
      # query cache
      s = @@cache.get_similarity(@a, @b)
      if nil != s
        return s
      end
      
      # body diff
      # lcs = Diff::LCS.lcs(@pa.body_str, @pb.body_str)
      # @similarity = lcs.length * 1.0 / [@pa.body_str.length, @pb.body_str.length].max
      # @@cache.record_similarity(@a, @b, similarity)
      return @similarity
    end

    def similar?
      bs = binary_similarity

      # consider result
      if SIMILAR_LV_AUTO <= bs
        return true
      elsif (SIMILAR_LV_HINT < bs) && (bs < SIMILAR_LV_AUTO)
        nil # uncertain
      else # similarity < SIMILAR_LV_HINT
        if !meta_same
          return false
        end
      end

      # uncertain
      ask_usr_same?
      raise UncertainSimilarityError.new(msg:"Uncertain similar posts", a:@a, b:@b, user_judge:@user_judge)
    end

  end
end
