require 'fileutils'
require 'logger'
require 'colorize'
require 'diff/lcs'

module Wp2jekyll

  class PostCompare
    include DebugLogger

    SIMILAR_LV_USER_SAME = 2.0

    SIMILAR_LV_AUTO = 0.9

    SIMILAR_LV_HINT = 0.618

    SIMILAR_LV_USER_DIFF = -1.0

    attr_reader :a, :ac
    attr_reader :b
    attr_accessor :similarity

    attr_accessor :pa
    attr_accessor :pb

    attr_accessor :user_judge
    
    @@cache = PostCompareCache.new

    # @ac: converted a
    def initialize(a, b, ac: nil)
      # @@logger.info "PostCompare #{a} <-> #{b}"
      @a = a
      @b = b
      @ac = ac
      @similarity = nil
    end

    def init_pa_pb

      if nil == @pa
        if nil != @ac
          @pa = Post.new(@ac)
        else
          @pa = Post.new(@a)
        end
      end
      if nil == @pb
        @pb = Post.new(@b)
      end
    end

    def ask_usr_same?
      init_pa_pb

      puts "- #{@pa.fp}".yellow
      @pa.hint_contents
      puts "+ #{@pb.fp}".yellow
      @pb.hint_contents

      user_input = ''
      until user_input == 'y' || user_input == 'n' do
        puts "Regards them as the same post (same content)?".yellow
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

    def body_similarity
      # query cache
      s = @@cache.get_similarity(@a, @b)
      if nil != s
        return s
      end
      
      init_pa_pb

      # @@logger.debug "do lcs #{a} #{b}".red
      # body diff
      lcs = Diff::LCS.lcs(@pa.content, @pb.content)
      max_len = [@pa.content.length, @pb.content.length].max
      same_len = lcs.length
      if 0 == max_len
        @similarity = 1
      else
        @similarity = 1.0 * same_len / max_len
      end
      @@cache.record_similarity(@a, @b, similarity)
      return @similarity
    end

    def similar?
      init_pa_pb
      # meta check, incase of duplicate import
      meta_same = (@pa.title == @pb.title) && (@pa.date == @pb.date)

      bs = body_similarity

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
