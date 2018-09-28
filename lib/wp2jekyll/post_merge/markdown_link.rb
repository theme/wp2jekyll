
module Wp2jekyll
  class MarkdownLink
    include DebugLogger

    attr_accessor :cap
    attr_accessor :link
    attr_accessor :title
    attr_accessor :is_img
    attr_accessor :tail
    attr_accessor :parsed_str
    
    # simple constructor
    def initialize(is_img: false, cap: '', link:, title: '', tail: '')
      @cap = cap
      @link = link
      @title = title
      @is_img = is_img
      @tail = tail
    end

    def to_s
      if @is_img
        # @@logger.info "![#{@cap}](#{@link})".cyan
        return "![#{@cap}](#{@link})"
      else # not image
        if nil == @title || @title.empty?
          return "[#{@cap}](#{@link})"
        else
          return "[#{@cap}](#{@link} \"#{title}\")"
        end
      end
    end
    
    def info
      "MarkdownLink: #{@is_img ? '!' : ''}[#{(@cap || '').red}](#{(@link || '').green} \"#{(@title || '').blue}\"){#{(@tail || '').magenta}}"
    end


    def self.parse_to_ast(str)
      parsed_li = MarkdownLinkParser.new.parse(symbol: :MLINK, in_txt:str.strip)
      if (1 == parsed_li.length) && parsed_li.first.is_a?(ASTnode) # matched
        return parsed_li.first
      else
        @@logger.debug "MarkdownLink.parse_to_ast li.length = #{parsed_li.length}".red
        parsed_li.each { |i|
          @@logger.debug "item #{i}".red
        }
      end
      nil
    end

    # parse possible single markdown link
    def self.parse(str)
      ast = self.parse_to_ast(str)
      if nil != ast
        tq = ast.first_v(:TITLE_QUOTE)
        if nil != tq
          tq.gsub!(/^[\'\"]*/, '')
          tq.gsub!(/[\'\"]*$/, '')
        end
        
        o = self.new(
          is_img: (nil != ast.first_v(:IMG_MARK)),
          cap: ast.first_v(:CAP_STR),
          link: ast.direct_child(:LINK).first_v(:URL).strip,
          title: tq,
          tail: ast.first_v(:TAIL_STR)
        )
        o.parsed_str = str
        @@logger.debug o.info

        return o
      end
      nil
    end

    def test?(str)
      nil != self.parse(str)
    end

  end # class MarkdownLink

  class ASTnode
    include DebugLogger
    attr_accessor :symbol, :parent, :children, :offset_s, :offset_e, :str
    def initialize(symbol:, parent:, children:, offset_s:, offset_e:, str:)
      @symbol = symbol
      @parent = parent
      @children = children || []
      @offset_s = offset_s
      @offset_e = offset_e
      @str = str
    end

    def gen_str
      @children.map {|c| c.to_s } .join
    end

    def update_str
      @str = gen_str
    end

    def update_str_all_p
      p = @parent
      loop do
        if nil != p
          p.update_str
          p = p.parent
        else
          break
        end
      end
    end

    def to_s
      if nil != @str
        @str
      else
        gen_str
      end
    end

    def replace_child(from_obj:, to_obj:)
      index = @children.find_index(from_obj)
      if (nil != index) && to_obj.is_a?(ASTnode)
        @children[index] = to_obj
        return index
      end
      nil
    end

    def drop_child(obj)
      @children.delete_if { |co|
        co.equal? obj
      }
    end

    def drop_all_symbol_in_children(symbol)
      @children.delete_if { |c|
        c.symbol == symbol
      }
    end

    def direct_child(symbol)
      @children.each { |c|
        if c.symbol == symbol
          return c
        end
      }
      nil
    end

    # return
    #   - [ASTnode] first parent ASTnode of symbol
    #   - nil
    def first_p(symbol)
      p = @parent
      loop do
        if nil == p
          return nil
        else
          if symbol == p.symbol
            return p
          else
            p = p.parent
          end
        end
        # @@logger.debug p
      end
    end

    # return
    #   - [ASTnode] first ASTnode of symbol (nearest from traverse root)
    #   - nil
    def first_c(symbol, order: :pre)
      traverse(order: order) { |ast_node|
        # @@logger.debug "traverse #{ast_node.symbol}"
        if ast_node.symbol == symbol
          return ast_node
        end
      }
      nil
    end

    def all_c_of_symbol(symbol)
      li = []
      traverse() { |ast_node|
        if ast_node.symbol == symbol
          li.append ast_node
        end
      }

      return li
    end

    # return
    #   - [String] first value of symbol (nearest from traverse root)
    #   - nil
    def first_v(symbol, order: :pre)
      # @@logger.debug "v #{symbol}"
      node = first_c(symbol, order: order)
      if nil != node
        return node.to_s
      end
      nil
    end

    def traverse(order: :pre, &block)
      # @@logger.debug "traverse #{self.symbol}"

      if :pre == order
        block.call self
      end

      self.children.each { |c|
        if c.is_a? ASTnode
          c.traverse(order: order, &block)
        end
      }

      if :post == order
        block.call self
      end

    end
  end

  class MarkdownLinkParser
    include DebugLogger

    # modified URI.regexp
    RE_PATH = /
    \/(?:[\-_.!~*'()a-zA-Z\d:@&=+$,]|%[a-fA-F\d]{2})*(?:;(?:[\-_.!~*'()a-zA-Z\d:@&=+$,]|%[a-fA-F\d]{2})*)*(?:\/(?:[\-_.!~*'()a-zA-Z\d:@&=+$,]|%[a-fA-F\d]{2})*(?:;(?:[\-_.!~*'()a-zA-Z\d:@&=+$,]|%[a-fA-F\d]{2})*)*)*                    (?# 7: path)
    [^\{\"\'\)\]]  (?# patch: for url markdown link)
    /x
    RE_URI_MOD = /
    ([a-zA-Z][\-+.a-zA-Z\d]*):                           (?# 1: scheme)
    (?:
       ((?:[\-_.!~*'()a-zA-Z\d;?:@&=+$,]|%[a-fA-F\d]{2})(?:[\-_.!~*'()a-zA-Z\d;\/?:@&=+$,\[\]]|%[a-fA-F\d]{2})*)                    (?# 2: opaque)
    |
       (?:(?:
         \/\/(?:
             (?:(?:((?:[\-_.!~*'()a-zA-Z\d;:&=+$,]|%[a-fA-F\d]{2})*)@)?        (?# 3: userinfo)
               (?:((?:(?:[a-zA-Z0-9\-.]|%\h\h)+|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|\[(?:(?:[a-fA-F\d]{1,4}:)*(?:[a-fA-F\d]{1,4}|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})|(?:(?:[a-fA-F\d]{1,4}:)*[a-fA-F\d]{1,4})?::(?:(?:[a-fA-F\d]{1,4}:)*(?:[a-fA-F\d]{1,4}|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))?)\]))(?::(\d*))?))? (?# 4: host, 5: port)
           |
             ((?:[\-_.!~*'()a-zA-Z\d$,;:@&=+]|%[a-fA-F\d]{2})+)                 (?# 6: registry)
           )
         |
         (?!\/\/))                           (?# XXX: '\/\/' is the mark for hostport)
         (\/(?:[\-_.!~*'()a-zA-Z\d:@&=+$,]|%[a-fA-F\d]{2})*(?:;(?:[\-_.!~*'()a-zA-Z\d:@&=+$,]|%[a-fA-F\d]{2})*)*(?:\/(?:[\-_.!~*'()a-zA-Z\d:@&=+$,]|%[a-fA-F\d]{2})*(?:;(?:[\-_.!~*'()a-zA-Z\d:@&=+$,]|%[a-fA-F\d]{2})*)*)*)?                    (?# 7: path)
       )(?:\?((?:[\-_.!~*'()a-zA-Z\d;\/?:@&=+$,\[\]]|%[a-fA-F\d]{2})*))?                 (?# 8: query)
    )
    (?:\#((?:[\-_.!~*'()a-zA-Z\d;\/?:@&=+$,\[\]]|%[a-fA-F\d]{2})*))?                  (?# 9: fragment)
    [^\{\"\'\)\]]  (?# patch: for url markdown link)
  /x

    # :TOKEN => [rule, rule]
    # rule := [parts, of, conjunction]
    GRAMMAR = {
      :MLINK => [
        [:IMG_MARK, :CAP, :LINK, :TAIL],
        [:IMG_MARK, :CAP, :LINK],
        [:CAP, :LINK, :TAIL],
        [:CAP, :LINK]
      ],
      :IMG_MARK => [
        ['!']
      ],
      :CAP => [
        ['[', /\s*/, :MLINK, /\s*/, ']'],
        ['[', /\s*/, :CAP_STR, /\s*/, ']']
      ],
      :CAP_STR => [[/[^\]]*/]],
      :LINK => [
        ['(', /\s*/, :URL, /\s*/, ')'],
        ['(', /\s*/, :URL, /\s*/, :TITLE_QUOTE, /\s*/, ')']
      ],
      :TITLE_QUOTE => [[/(\'[^\']*\'|\"[^\"]*\")/]],
      :URL => [
        [:URL_STR],
        [:URL_LIQUID]
      ],
      :URL_STR => [
        [RE_PATH], # local
        [RE_URI_MOD] # remote
      ],
      :URL_LIQUID => [['{{', /\s*['"]/, :URL_STR, /['"]\s*/, '|', /\s*/, :URL_LIQUID_TYPE_STR, /\s*/, '}}']],
      :URL_LIQUID_TYPE_STR => [[/(relative_url|absolute_url)/]],
      :TAIL => [
        ['{', /\s*/, :TAIL_STR, /\s*/, '}'],
      ],
      :TAIL_STR => [[/[^\}]*/]]
    }

    attr_accessor :bts # backtrace stack
    attr_accessor :txt
    attr_accessor :offset
    attr_accessor :str_s

    def initialize
      reset
    end

    def reset
      @bts = []
      @txt = ''
      @offset = 0
      @str_s = 0
    end



    # return [Array] of 
    #   - ASTnode : of every markdown link
    #   - String : rest of text
    def parse(symbol: :MLINK, in_txt:)
      li = []
      str_s = 0
      str_e = in_txt.length - 1
      offset = 0
      loop do
        ast = expand_and_match(symbol: :MLINK, in_txt:in_txt, offset: offset, ast_parent:nil)
        if nil != ast
          if str_s < ast.offset_s - 1 # some text is here
            # @@logger.debug "txt piece #{in_txt[str_s..(ast.offset_s -1)]}".blue
            # @@logger.debug "str_s => #{str_s}, ast.offset_s - 1 => #{ast.offset_s - 1}".blue
            li.append in_txt[str_s..(ast.offset_s - 1)]
          end

          li.append ast # symbol derived ast tree
          str_s = ast.offset_e + 1

          offset = ast.offset_e + 1
        else
          offset += 1 # scan text
        end

        # @@logger.debug "offset => #{offset}, str_s => #{str_s}".blue

        if offset >= in_txt.length # reached text end
          if str_s < str_e # some text is here
            li.append in_txt[str_s..str_e]
          end
          break
        end
      end

      return li
    end

    def update_ast_offset_e(ast:, offset_e:)
      node = ast
      loop do
        node.offset_e = offset_e
        node = node.parent
        if nil == node
          break
        end
      end
    end

    # recursive decent backtracking parsing
    # return
    #   - ast (if matched)
    #   - nil (else)
    def expand_and_match(symbol:, in_txt:, offset:, ast_parent:)
      # @@logger.debug "expand_and_match #{symbol} offset #{offset}".green
      ast_node = ASTnode.new(symbol:symbol, parent: nil, children:[], offset_s:offset, offset_e:nil, str:nil)

      for ru in GRAMMAR[symbol] # will any rule match ?
        offset_e = match_rule(rule: ru, txt: in_txt, offset: offset, ast_parent: ast_node)
        if nil != offset_e # rule is matched
          if nil != ast_parent
            ast_parent.children.append(ast_node)
          end

          ast_node.parent = ast_parent
          update_ast_offset_e(ast:ast_node, offset_e: offset_e)
          ast_node.str = in_txt[offset..offset_e]

          # @@logger.debug "matched #{symbol} #{ast_node}".white
          return ast_node
        else
          next # rule
        end
      end

      # no rule is matched
      nil
    end

    # @return
    #   - offset (of matching end)
    #   - nil (else)
    def match_rule(rule:, txt:, offset:, ast_parent:)
      return nil if nil == rule

      # @@logger.debug "match_rule #{rule} <-> offset #{offset} #{txt[offset..offset]}".green

      if nil != ast_parent
        fake_parent = ASTnode.new(symbol: ast_parent.symbol, parent: nil, children:[], offset_s:offset, offset_e:nil, str:nil)
      end

      offset_e = offset
      rule.each { |component|
        offset_e = match_rule_component(component: component, txt: txt, offset:offset, ast_parent:fake_parent)
        if nil == offset_e # mismatched
          return nil
        end
        offset = offset_e + 1
      }

      # the whole rule is matched

      # put back every node under fake_parent node
      if nil != ast_parent
        fake_parent.children.each { |c|
          if c.is_a? ASTnode
            c.parent = ast_parent
          end

          ast_parent.children.append c
          update_ast_offset_e(ast: c, offset_e: c.offset_e)
          # @@logger.debug "append to #{ast_parent.symbol}".red
        }
      end

      return offset_e
    end

    # @return
    #   - offset (of matching end)
    #   - nil (else)
    def match_rule_component(component:, txt:, offset:, ast_parent:)
      return nil if nil == component
      # @@logger.debug "match_rule_component #{component} offset #{offset}"
      case component
      when Regexp
        m = component.match(txt, offset)
        # m = txt[offset..-1].match(component)
        if nil != m and m.offset(0)[0] == offset
          offset_e = m.offset(0)[1] - 1

          if nil != ast_parent
            ast_parent.children.append ASTnode.new(symbol:component, parent: ast_parent, children:[],
              offset_s:offset, offset_e:offset_e, str:txt[offset..offset_e])
          end

          return offset_e
        end
      when String
        if component.length > 0
          offset_e = offset + component.length - 1 # 'abc'[0..0] => 'a'
          # @@logger.debug "match_rule_component #{component} <-> #{txt[offset..offset_e]}".green
          if txt[offset..offset_e] == component # 'abc'[0..0] => 'a'

            if nil != ast_parent
              ast_parent.children.append ASTnode.new(symbol:component, parent: ast_parent, children:[], 
                offset_s:offset, offset_e:offset_e, str:txt[offset..offset_e])
            end

            return offset_e
          end
        end
      when Symbol
        ast_node = expand_and_match(symbol: component, in_txt: txt, offset: offset, ast_parent: ast_parent)
        if nil != ast_node
          return ast_node.offset_e
        end
      else
        @@logger.debug "Unknown Grammar rule component. #{component.inspect}".yellow
      end
      # @@logger.debug "match_rule_component fail offset #{offset}".red
      nil
    end

  end # class MarkdownLinkParser
end

