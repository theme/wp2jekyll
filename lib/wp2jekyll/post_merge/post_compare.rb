require 'fileutils'
require 'logger'
require 'colorize'
require 'diff/lcs'

module Wp2jekyll

  class PostCompare
    include DebugLogger

    SIMILAR_LV_AUTO = 0.9

    SIMILAR_LV_HINT = 0.618

    attr_reader :a
    attr_reader :b
    attr_accessor :pa
    attr_accessor :pb

    attr_accessor :user_say_same
    
    @@cache = PostCompareCache.new

    def initialize(a, b)
      @a = a
      @b = b
    end

    def pa
      @pa || @pa = Post.new(@a)
    end

    def pb
      @pb || @pb = Post.new(@b)
    end

    def ask_usr_same?
      len = 20
      puts '+'*len + @a
      pa.hint_contents
      puts '-'*len + @b
      pb.hint_contents
      puts '='*len

      user_input = ''
      until user_input == 'y' || user_input == 'n' do
        puts "Regards them as the same post ?"
        user_input = STDIN.getc
        STDIN.gets # flush
      end

      case user_input
      when 'y' then
        @@cache.add_same(@a, @b)
        @user_say_same = true
      when 'n' then
        @@cache.add_diff(@a, @b)
        @user_say_same = false
      end
    end

    def same_date?
      # @@logger.debug pa.inspect
      # @@logger.debug pb.inspect
      pa.date_str == pb.date_str
    end

    def same_title?
      # @@logger.debug pa.inspect
      # @@logger.debug pb.inspect
      pa.title == pb.title
    end

    def similar?
      if @@cache.same?(@a, @b) then return true end
      if @@cache.diff?(@a, @b) then return false end

      if same_title? && same_date? then return true end

      lcs = Diff::LCS.lcs(pa.body_str, pb.body_str)
      similarity = lcs.length * 1.0 / [pa.body_str.length, pb.body_str.length].max

      if SIMILAR_LV_AUTO < similarity
        @@cache.add_same(@a, @b)
        return true
      elsif SIMILAR_LV_HINT < similarity && similarity < SIMILAR_LV_AUTO
        return ask_usr_same?
      else # similarity < SIMILAR_LV_HINT
        @@cache.add_diff(@a, @b)
        return false
      end
      
    end

  end
end