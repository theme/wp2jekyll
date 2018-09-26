
module Wp2jekyll
  class MarkdownLink
    include DebugLogger

    # TODO embedded link
    RE = %r~((\!)?\[([^\n]*)\]\(\s*?([^"\s]*?)\s*?("([^"]*?)")?\)(\{.*?\})?)~
    #E = %r~12--2  [3---3 ] (    4--------4    5-6------6-5  )7 {----}7 1~
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
      "MarkdownLink: #{@is_img ? '!' : ''}[#{(@cap || '').red}](#{(@link || '').green} \"#{(@title || '').blue}\")#{(@tail || '').magenta}"
    end

    # @return
    #   - [String] for plain text part
    #   - [Struct] ASTnode, AST tree for parsed markdown link # WIP
    def self.parse(str)
      if m = RE.match(str) # TOOD: this is not possible in theory
        o = self.new(
          is_img: ('!' == m[2]) ? true : false,
          cap: m[3],
          link: m[4],
          title: m[6],
          tail: m[7]
        )
        o.parsed_str = str
        @@logger.debug o.info

        return o
      end
      nil
    end

    # return [Array] of inner most MarkdownLink
    def self.extract_inner(str)
      # TODO : refactoring : include useage of this function
      li = []
      str.scan(RE).each do |m|  # TOOD: this is not possible in theory
        mdlk = self.parse m[0]
        li.append mdlk if nil != mdlk
      end
      return li
    end

    def test?(str)
      nil != RE.match(str)
    end

  end # class MarkdownLink

  

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
      :TAIL => [/\{[^\}]*\}/],
      :CAP => [
        ['[', :CAP_STR, ']'],
        ['[', :MLINK, ']']
      ],
      :CAP_STR => [/[^\]]*/],
      :LINK => [
        ['(', :URL, ')'],
        ['(', :URL, :TITLE_STR, ')']
      ],
      :TITLE_STR => [/(\'[^\']*\'|\"[^\"]*\")/],
      :URL => [
        [:URL_PLAIN_STR],
        [:URL_LIQUID]
      ],
      :URL_PLAIN_STR => [URI.regexp],
      :URL_LIQUID => [['{{', :URL_PLAIN_STR, '|', :URL_LIQUID_TYPE_STR, '}}']],
      :URL_LIQUID_TYPE_STR => [/(relative_url|absolute_url)/]
    }

    ASTnode = Struct.new(:symbol, :parent, :children, :offset_s, :offset_e, keyword_init: true)

    # def first_markdown_link_in_ast(ast)
    #   deep_first_traverse_ast(ast) do |ast_node|
    #     if :MLINK == ast_node.symbol
    #       # construct
    # end

    # def deep_first_traverse_ast(ast)
    #   if ast.children.length > 0 then
    #     for c in ast.children
    #       traverse_ast c
    #     end
    #   end
    #   yield ast
    # end

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

          offset = ast.offset_e
          offset_s = ast.offset_e
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
      ast_node = ASTnode.new(symbol:symbol, parent: ast_parent, children:[], offset_s:offset, offset_e:nil)

      for ru in grammar[symbol] # will any rule match ?
        offset_e = match_rule(rule: ru, txt: in_txt, offset: offset, ast_parent: ast_node)
        if nil != offset_e # rule is matched
          if nil != ast_parent
            ast_parent.children.append(ast_node)
          end
          update_ast_offset_e(ast:ast_node, offset_e: offset_e)
          return ast_node
        else
          next # rule
        end
      end

      # no rule is matched
      nil
    end

    # @return
    #   - offset (of matching end + 1)
    #   - nil (else)
    def match_rule(rule:, txt:, offset:, ast_parent:)
      return nil if nil == rule

      for component in rule
        offset = match_rule_component(component: component, txt: txt, offset:offset, ast_parent:ast_parent)
        if nil == offset # mismatched
          return nil
        end
      end

      return offset # the whole rule is matched
    end

    # @return
    #   - offset (of matching end)
    #   - nil (else)
    def match_rule_component(component:, txt:, offset:, ast_parent:)
      return nil if nil == component

      case component
      when Regexp
        m = txt[offset..-1].match(component)
        if nil != m and m.offset(0)[0] == offset
          return m.offset(0)[1]
        end
      when String
        offset_e = offset + component.length
        if txt[offset..offset_e] == component
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

