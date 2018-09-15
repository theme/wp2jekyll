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

  class NotFileError < StandardError
    attr_reader :f

    def initialize(msg: "Not a file.", f:)
      super "#{msg} #{f}"
      @f = f
    end
  end

  class FileCompare
    include DebugLogger

    SIMILAR_LV_USER_SAME = 2.0

    SIMILAR_LV_AUTO = 0.9

    SIMILAR_LV_HINT = 0.618

    SIMILAR_LV_USER_DIFF = -1.0

    BINARY_SAMPLE_POINTS_NUM = 100

    attr_reader :a
    attr_reader :b
    attr_accessor :similarity

    attr_accessor :user_judge
    
    @@cache = FileCompareCache.new

    def initialize(a, b)
      if !File.file?(a)
        raise NotFileError.new(f:a)
      else
        @a = a
      end
      if !File.file?(b)
        raise NotFileError.new(f:b)
      else
        @b = b
      end
      @similarity = nil
    end

    def file_info(f)
      "File #{File.path f} size #{File.size f} mtime #{File.mtime f}"
    end

    def hint_file_contents(f)
      @@logger.info file_info f
    end

    def ask_usr_same?
      puts "- #{@a}".yellow
      hint_file_contents  @a
      puts "+ #{@b}".yellow
      hint_file_contents  @b

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

      # step for scan file
      sa = File.size(@a)
      sb = File.size(@b)
      step_a = sa / BINARY_SAMPLE_POINTS_NUM
      step_b = sb / BINARY_SAMPLE_POINTS_NUM
      step = step_a < step_b ? step_a : step_b
      if step == 0
        step = 1
      end

      min_size = sa < sb ? sa : sb

      fda = File.open(@a, 'rb')
      fdb = File.open(@b, 'rb')

      bytes_read = 0
      bytes_same = 0
      loop {
        char_a = fda.read(1)
        char_b = fdb.read(1)

        bytes_read += 1

        if char_a == char_b
          bytes_same += 1
        end

        fda.seek(step, :CUR)
        fdb.seek(step, :CUR)

        if bytes_read == BINARY_SAMPLE_POINTS_NUM || fda.eof? || fdb.eof?
          fda.close
          fdb.close
          break
        end
      }

      @similarity = 1.0 * bytes_same / bytes_read
      @@cache.record_similarity(@a, @b, @similarity)

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
        return false
      end

      # uncertain
      ask_usr_same?
      raise UncertainSimilarityError.new(msg:"Uncertain similarity of files", a:@a, b:@b, user_judge:@user_judge)
    end

  end
end
