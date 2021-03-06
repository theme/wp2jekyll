require 'fileutils'
require 'tempfile'
require 'cgi'
require 'uri'
require 'logger'

require 'nokogiri'
require 'colorize'

module Wp2jekyll
  class WordpressMarkdown < JekyllMarkdown
    attr_accessor :suspicious_url_contains
    attr_accessor :relative_url_contains

    def initialize(fp = '')
      super(fp)
      @@code_cnt = 0
      @suspicious_url_contains = [ "/home/#{ENV['USER']}" ]
      @relative_url_contains = ['wp-content']
    end

    def is_url_suspicious?(ln)
      # @@logger.debug 'suspicious? ' + ln
      for s in @suspicious_url_contains do
        if ln.include? s then
          return true
        end
      end
      false
    end

    def should_url_relative?(ln)
      # @@logger.debug 'relative? ' + ln
      for r in @relative_url_contains do
        if ln.include? r then
          return true
        end
      end
      false
    end

    def url_to_relative(ln)
      return URI(ln).path
    end
    
    ####
    # the wordpress exported md is got by the following ruby script ,
    # exported md will have some bug for jekyll, so I have to patch it.
    ####
    #gem install unidecode sequel mysql2 xmlentities
    #
    #
    #echo ######## now import ... ( wp > jekyll ) ###############
    #
    #ruby -rubygems -e 'require "jekyll-import";
    #JekyllImport::Importers::WordPress.run({
    #"dbname"   => "wordpress",
    #"user"     => "wordpress",
    #"password" => "wordpress",
    #"host"     => "localhost",
    #"port"     => "3306",
    #"socket"   => "",
    #"table_prefix"   => "wp_",
    #"site_prefix"    => "",
    #"clean_entities" => true,
    #"comments"       => true,
    #"categories"     => true,
    #"tags"           => true,
    #"more_excerpt"   => true,
    #"more_anchor"    => true,
    #"extension"      => "xml",
    #"status"         => ["publish"]
    #  })'
    ###

    def patch_unescape_html_char(txt)
      return CGI::unescapeHTML(txt)
    end

    def patch_list_like(txt, lead = '*', compress = false)
      # @@logger.debug 'patch_list_like: ' + lead
      txt2 = txt
      re = Regexp.new('(?:(?:^' + '\\' + lead + '.*?\n)(?:^\s\s\n)?)+',
      Regexp::MULTILINE)
      # none capture group is needed
      match_li = txt.scan(re)
      for i in match_li do 
        # link segmented quotes in to one block
        if !compress then
          j = i.gsub(/\n\s\s\n/m, "\n" + lead + "\n")
        else
          j = i.gsub(/\n\s\s\n/m, "\n")
        end

        # insert 2 blank line around "> ...." quote block
        txt2.gsub!(i, "\n" + j + "\n")
      end

      return txt2
    end

    def patch_h1h2_space(txt)
      txt.gsub!(/\ \ \n(?=\-+$)/m, "")
      txt.gsub!(/\ \ \n(?=\=+$)/m, "")
      return txt
    end

    def patch_quote(txt)
      patch_list_like(txt, '>')
    end


    def fname_in_url(url)
      p = URI(url).path
      e = File.extname(p)
      b = File.basename(p, e) # base name
      return b
    end

    def html_figure_to_md(txt)
      frag = Nokogiri::HTML::DocumentFragment.parse(txt) do |config|
        config.nonet.recover
      end

      fig = frag.css("figure").first
        cap = fig.css("figcaption").text
        img = fig.css("img").first
        src = img['src']
        # markdown link src has precedence
        if m = fig.inner_html.match(/\[.*?\]\((.*?)\)/)
          src = m[1] if !m[1].empty?
        end
        figure_md  = '!' + md_link(cap, src)
        @@logger.debug 'xml_figure ' + figure_md.light_cyan
        return figure_md
    end

    # construct markdown link from caption and url (aware of relative )
    def md_link(cap, url)
      return '' if nil == url
      # @@logger.debug 'md_link: '.green + url
      if !should_url_relative?(url) then
        return "[#{cap}](#{url})"
      else
        return "[#{cap}]({{ \"#{url_to_relative(url)}\" | relative_url }})"
      end
    end

    def parse_html_to_md_array(html)
      frag = Nokogiri::HTML::DocumentFragment.parse(html)

      md_pieces = [ ]

      frag.children.each do |n|
        case n.type
        when Nokogiri::XML::Node::TEXT_NODE
          md_pieces.append n
          # puts n.text.yellow
          # @@logger.debug "Nokogiri:...:TEXT_NODE #{n.text}".yellow
        when Nokogiri::XML::Node::ELEMENT_NODE
          # @@logger.debug "Nokogiri:...:ELEMENT_NODE <#{n.name}>".yellow
          case n.name
          when "figure"
            md_pieces.append html_figure_to_md(n.to_s)
          when "img"
            md_pieces.append '!' + md_link(n['alt'], n['src'])
          when 'pre'
            md_pieces.append "\n```\n" + n + "\n```\n"
          when 'table'
            trs_md = []
            n.css('tr').each do |tr|
              rowdata_a = []
              tr.css('td').each do |td|
                td_md = parse_html_to_md_array(td.inner_html.strip).join
                td_md.gsub!("\n", '')
                rowdata_a.append(td_md) if !td_md.empty?
              end
              trs_md.append ('| ' + rowdata_a.join(' | ') + " |")
            end
            md_pieces.append "\n" + trs_md.join("\n") + "\n"
          when 'ol'
            ol_md = []
            count = 0
            n.css('li').each do |li|
              count +=1
              ol_md.append( count.to_s + '. ' + parse_html_to_md_array(li.inner_html.strip).join)
            end
            md_pieces.append ol_md.join
            @@logger.debug ol_md.join.cyan
            # exit 1
          when 'a'
            a_cap = parse_html_to_md_array(n.inner_html).join
            a_link = n['href'] || ''
            a_md = "[#{a_cap}](#{a_link})"
            md_pieces.append a_md
          when 'br'
            md_pieces.append "\n\n"
          when 'div'
            md_pieces.append parse_html_to_md_array(n.inner_html.gsub(/(^\s*)|(\s*$)/, "\n").strip).join
          when 'span'
            md_pieces.append parse_html_to_md_array(n.inner_html.strip).join.gsub("\n", '')
          when 'del'
            md_pieces.append '~~'+ parse_html_to_md_array(n.inner_html.strip).join + '~~'
          else
            md_pieces.append parse_html_to_md_array(n.inner_html.strip).join
          end
        end
      end
      # @@logger.debug "md_pieces.join \n#{md_pieces.join}".red
      return md_pieces
    end

    def modify_md_link(txt)
      # @@logger.debug "modify_md_link \n#{txt.red}"
      parsed_li = MarkdownLinkParser.new.parse(in_txt:txt)
      parsed_li.each { |i|
        # @@logger.debug "parsed_li i #{i}"
        if i.is_a? ASTnode

          i.all_c_of_symbol(:URL_STR).each { |url_plain_str_node|
            @@logger.debug url_plain_str_node.to_s.cyan
            
            p = url_plain_str_node.parent
            url = url_plain_str_node.to_s

            if is_url_suspicious?(url)
              @@logger.warn 'suspicious: ' + url.red
              url_plain_str_node.str = ''
              if nil != (pmlk = url_plain_str_node.first_p(:MLINK))
                pmlk.str = ''
              end
              next
            end

            if should_url_relative?(url)

              @@logger.debug 'url should be relative: ' + url.green
              # construct liquid url node
              lqurl = LiquidUrl.new(url: url)
              lqurl.to_liquid_relative!
              @@logger.debug "to_liquid_relative #{lqurl.to_s}"

              # is this already a liquid link?
              if nil != (lqlk_node = url_plain_str_node.first_p(:URL_LIQUID)) # inside a liquid node
                # change liquid filter to relative
                lqlk_node.first_c(:URL_LIQUID_TYPE_STR).str = 'relative_url'
                # change link to relative
                lqlk_node.first_c(:URL_STR).str = lqurl.url.to_s
                lqlk_node.update_str
                lqlk_node.update_str_all_p
              else # not inside a liquid node
                tmp_ast = MarkdownLink.parse_to_ast("[tmp_ast](#{lqurl.to_s})") # new node
                new_node = tmp_ast.first_c(:URL_LIQUID)
                if nil != new_node && nil != p
                  # replace url node with new node
                  @@logger.debug "replace_child \n#{url_plain_str_node.to_s} \n-> #{new_node.to_s}"

                  p.replace_child(from_obj:url_plain_str_node, to_obj:new_node)
                  p.update_str
                  p.update_str_all_p
                end
              end

            end
          }

          # drop tail
          i.all_c_of_symbol(:TAIL).each { |tail_node|
            tail_node.str = ''
            tail_node.update_str_all_p
          }
        end
      }
      
      parsed_li.map {|i| i.to_s } .join
    end

    def patch_code(txt, indent = 4) # -> String
      txt.scan(CodeSegmenter::RE).each do |m|
        @@code_cnt += 1

        code = m[1]
        code.rstrip!

        # code.gsub!(/^[ \t\r\f]*/m, " "*indent) # indent code
        tab = 1
        code.each_line { |line|
          lm = line.match /^\s*/
          if 0 == lm[0].size # if there is no indent
            tab_bak = 0
            if line =~ /^\s*[\}\)]\s*;?,?\s*$/
              tab_bak += 1
            end
            code.gsub!(line, " "*indent*(tab - tab_bak) + line) # indent code
            tab += line.scan(/\{/).count
            tab += line.scan(/\(/).count
            tab -= line.scan(/\}/).count # simple indent code
            tab -= line.scan(/\)/).count # simple indent code
          end
        }

        code.gsub!(/^\s*$\n/m, '') # empty line (note Ruby ~/m meaning)
        code.gsub!(/(?=^\s*)\\#/m, "#")

        code = "\n```\n" + code + "\n```\n"

        txt.gsub!(m[0], code)
      end

      # @@logger.debug "patch_code => #{txt} ".yellow
      return txt
    end

    # TODO
    def patch_char(txt) # helper func
      txt.gsub!('{{}}', '{ {} }') # liquid template engine of jekyll
      txt.gsub!('&#8211;', '-') # the original text is mangled by wp
      txt.gsub!('&#8212;', '--')
      txt.gsub!('&#8212;', '--')
      txt.gsub!(/^\s*?&nbsp;\s*?$/, '') # a blank txt
      txt.gsub!('&nbsp;', ' ')
      txt.gsub!('\_', '_')
      txt.gsub!(/^`\s*$/, "\n```\n")
      return txt
    end

    def process_md_header(header)
      # process header
      header.gsub!(/^permalink:/, 'permalink_wp:') # wordpress exported
      header = patch_unescape_html_char(header)
    end

    def process_md_body(content)
      cs = CodeSegmenter.new(content)

      cs.li.each { |o| o[:text] = parse_html_to_md_array(o[:text]).join if !!o[:text] }

      # markdown link
      cs.li.each { |o| o[:text] = modify_md_link(o[:text]) if !!o[:text] }
      
      # markdown quote
      cs.li.each { |o| o[:text] = patch_quote(o[:text]) if !!o[:text] }

      # markdown list
      cs.li.each { |o| o[:text] = patch_list_like(o[:text], '*', true) if !!o[:text] }
      
      # pre formatted
      cs.li.each { |o| o[:code] = patch_code(o[:code]) if !!o[:code] }
      #
      cs.li.each { |o| o[:text] = patch_unescape_html_char(o[:text]) if !!o[:text] }
      cs.li.each { |o| o[:code] = patch_unescape_html_char(o[:code]) if !!o[:code] }

      # section titles
      cs.li.each { |o| o[:text] = patch_h1h2_space(o[:text]) if !!o[:text] }

      # @@logger.debug "cs.join #{cs.join}".cyan

      cs.join
    end

    # test helper
    def process_md!(fulltxt)
      parse!(fulltxt)

      # @@logger.debug 'yaml_front_matter: ' + @yaml_front_matter_str.yellow
      if !!@yaml_front_matter_str
        @yaml_front_matter_str = process_md_header(@yaml_front_matter_str)
        @yaml_front_matter_str = patch_char(@yaml_front_matter_str)
      end

      # @@logger.debug 'content: ' + @content.green
      if !!@content
        @content = process_md_body(@content)
        @content = patch_char(@content)
      end

      # @@logger.debug to_s.cyan
      to_s
    end

    def write_jekyll_md!
      if !JekyllMarkdown.has_yaml_header?(@fp) then
        @@logger.info "write_jekyll_md! skip: #{@fp} : has no yaml header."
      elsif 'home' == @style || 'page' == @style
        @@logger.info "write_jekyll_md! skip: #{@fp} : it should be already in jekyll style."
      else
        File.write(@fp, process_md!(to_s))
      end
    end

    def path
      @fp
    end
  end
end

