
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
      end
      nil
    end

    # parse possible single markdown link
    def self.parse(str)
      ast = self.parse_to_ast(str)
      if nil != ast
        tq = ast.first_v(:TITLE_QUOTE)
        tq.gsub!(/^[\'\"]*/, '')
        tq.gsub!(/[\'\"]*$/, '')
        
        o = self.new(
          is_img: ('!' == ast.children[0]) ? true : false,
          cap: ast.first_v(:CAP_STR),
          link: ast.direct_child(:LINK).first_v(:URL),
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

    def to_s
      if children.empty?
        @str
      else
        @children.map {|c| c.to_s } .join
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
      loop do
        p = @parent
        if nil == p
          return nil
        else
          if symbol == p.symbol
            return p
          else
            p = p.parent
          end
        end
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

    # :TOKEN => [rule, rule]
    # rule := [parts, of, conjunction]
    GRAMMAR = {
      :MLINK => [[:IMG_MARK, :CAP, :LINK, :TAIL]],
      :IMG_MARK => [
        ['!'],
        [nil]
      ],
      :CAP => [
        ['[', /\s*/, :CAP_STR, /\s*/, ']'],
        ['[', /\s*/, :MLINK, /\s*/, ']']
      ],
      :CAP_STR => [[/[^\]]*/]],
      :LINK => [
        ['(', /\s*/, :URL, /\s*/, ')'],
        ['(', /\s*/, :URL, /\s*/, :TITLE_QUOTE, /\s*/, ')']
      ],
      :TITLE_QUOTE => [[/(\'[^\']*\'|\"[^\"]*\")/]],
      :URL => [
        [:URL_PLAIN_STR],
        [:URL_LIQUID]
      ],
      :URL_PLAIN_STR => [[URI.regexp]],
      :URL_LIQUID => [['{{', /\s*/, :URL_PLAIN_STR, /\s*/, '|', /\s*/, :URL_LIQUID_TYPE_STR, /\s*/, '}}']],
      :URL_LIQUID_TYPE_STR => [[/(relative_url|absolute_url)/]],
      :TAIL => [
        ['{', /\s*/, :TAIL_STR, /\s*/, '}'],
      ],
      :TAIL_STR => [[/[^\}]*/]]
    }

    # return [Array] of 
    #   - ASTnode : of every markdown link
    #   - String : rest of text
    def parse(symbol: :MLINK, in_txt:)
      li = []
      offset_s = 0 # last start of parsing loop
      offset = offset_s
      loop do
        ast = expand_and_match(symbol: :MLINK, in_txt:in_txt, offset: offset, ast_parent:nil)
        if nil != ast
          if offset_s < ast.offset_s # some text is here
            li.append in_txt[offset_s, ast.offset_s]
          end

          li.append ast # symbol derived ast tree

          offset = ast.offset_e + 1
          offset_s = ast.offset_e + 1
        else
          offset += 1 # scan text
        end

        if offset >= in_txt.length
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
      # @@logger.debug "expand_and_match #{symbol} offset #{offset}"
      ast_node = ASTnode.new(symbol:symbol, parent: ast_parent, children:[], offset_s:offset, offset_e:nil, str:nil)

      for ru in GRAMMAR[symbol] # will any rule match ?
        offset_e = match_rule(rule: ru, txt: in_txt, offset: offset, ast_parent: ast_node)
        if nil != offset_e # rule is matched
          if nil != ast_parent
            ast_parent.children.append(ast_node)
          end
          update_ast_offset_e(ast:ast_node, offset_e: offset_e)
          ast_node.str = in_txt[offset..offset_e]
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

      # @@logger.debug "match_rule #{rule} offset #{offset}"
      
      offset_e = offset
      rule.each { |component|
        offset_e = match_rule_component(component: component, txt: txt, offset:offset, ast_parent:ast_parent)
        if nil == offset_e # mismatched
          return nil
        end
        offset = offset_e + 1
      }

      # the whole rule is matched
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
        offset_e = offset + component.length - 1
        # @@logger.debug "match_rule_component #{component} <-> #{txt[offset..offset_e]}"
        if txt[offset..offset_e] == component

          if nil != ast_parent
            ast_parent.children.append ASTnode.new(symbol:component, parent: ast_parent, children:[], 
              offset_s:offset, offset_e:offset_e, str:txt[offset..offset_e])
          end

          return offset_e
        end
      when Symbol
        ast_node = expand_and_match(symbol: component, in_txt: txt, offset: offset, ast_parent: ast_parent)
        if nil != ast_node
          return ast_node.offset_e
        end
      when nil
        return offset
      else
        @@logger.debug "Unknown Grammar rule component. #{component.inspect}".yellow
      end

      nil
    end

  end # class MarkdownLinkParser
end

