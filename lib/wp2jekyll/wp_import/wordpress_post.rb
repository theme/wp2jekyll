require 'fileutils'
require 'tempfile'
require 'cgi'
require 'uri'
require 'logger'

require 'nokogiri'
require 'colorize'

module Wp2jekyll
  class WordpressMarkdown < Post
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
      return md_pieces
    end

    def is_uri?(str)
      begin
        URI(str)
        return true
      rescue
        return false
      end
    end

    def modify_md_link(txt)
      MarkdownLink.extract(txt).each do |mdlk|

        # recursive process embedded markdown link in link cap
        mdlk.cap = modify_md_link(mdlk.cap)

        if is_url_suspicious? mdlk.link then
          @@logger.warn 'suspicious: ' + mdlk.link.red
          txt.gsub!(mdlk.parsed_str, '') # delete to prevent being published
        end
        
        # relative
        if is_uri?(mdlk.link) and should_url_relative?(mdlk.link) then
          @@logger.debug 'url should be relative: ' + mdlk.link.green
          mdlk.link = LiquidUrl.new(uri: mdlk.link).to_liquid_relative!.to_s
          txt.gsub!(mdlk.parsed_str, mdlk.to_s)
        end

        # drop tail {}
        txt.gsub!(mdlk.parsed_str, mdlk.to_s)

      end

      return txt
    end

    def patch_code(txt, indent = 4) # -> String
      txt.scan(CodeSegmenter::RE).each do |m|
        @@code_cnt += 1

        code = m[1]
        # code.gsub!(/^[ \t\r\f]*/m, " "*indent) # indent code
        # code.gsub!(/^/m, " "*indent) # indent code
        code.rstrip!
        code = "```\n" + code + "\n```\n"
        code.gsub!(/^\s*$\n/m, '') # empty line (this is Ruby ~)
        code.gsub!(/(?=^\s*)\\#/m, "#")
        txt.gsub!(m[0], code)
      end

      # @@logger.debug "patch_code => #{txt} ".yellow
      return txt
    end

    def patch_md_img(txt)
      # markdown link src has precedence
      txt.scan(/(\[(.*?)\]\((.*?)\))/).each do |md_ln|
        frag = Nokogiri::HTML::DocumentFragment.parse(md_ln[0])
        n = frag.css('img').first
        if !!n and n.type == Nokogiri::XML::Node::ELEMENT_NODE and n.name == 'img'
          src = md_ln[2]
          n['src'] = src if !src.empty?
          txt.gsub!(md_ln[0], frag.to_s)
        end
      end
      txt
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
      txt.gsub!(/^`\s*$/, '```')
      return txt
    end

    def process_md_header(header)
      # process header
      header.gsub!(/^permalink:/, 'permalink_wp:') # wordpress exported
      header = patch_unescape_html_char(header)
    end

    def process_md_body(body_str)
      cs = CodeSegmenter.new(body_str)

      cs.li.each { |o| o[:text] = patch_md_img(o[:text]) if !!o[:text]}

      # body_str  = patch_md_img(body_str)

      # body_str  = parse_html_to_md_array(body_str).join
      cs.li.each { |o| o[:text] = parse_html_to_md_array(o[:text]).join if !!o[:text] }

      # markdown link
      # body_str = modify_md_link(body_str)
      cs.li.each { |o| o[:text] = modify_md_link(o[:text]) if !!o[:text] }
      #
      # markdown quote
      # body_str = patch_quote(body_str)
      cs.li.each { |o| o[:text] = patch_quote(o[:text]) if !!o[:text] }

      # # markdown list
      # body_str = patch_list_like(body_str, '*', true)
      cs.li.each { |o| o[:text] = patch_list_like(o[:text], '*', true) if !!o[:text] }
      #
      # # pre formatted
      # body_str = patch_code(body_str)
      cs.li.each { |o| o[:code] = patch_code(o[:code]) if !!o[:code] }
      #
      # # section titles
      # body_str = patch_unescape_html_char(body_str)
      cs.li.each { |o| o[:text] = patch_unescape_html_char(o[:text]) if !!o[:text] }
      cs.li.each { |o| o[:code] = patch_unescape_html_char(o[:code]) if !!o[:code] }

      # body_str = patch_h1h2_space(body_str)
      cs.li.each { |o| o[:text] = patch_h1h2_space(o[:text]) if !!o[:text] }

      # @@logger.debug "cs.join #{cs.join}".cyan

      cs.join
    end

    def process_md!(fulltxt)
      split_fulltxt(fulltxt)

      # @@logger.debug 'yaml_front_matter: ' + yaml_front_matter
      @yaml_front_matter_str =process_md_header(@yaml_front_matter_str) if !!@yaml_front_matter_str

      # @@logger.debug 'body_str: ' + body_str
      @body_str =process_md_body(@body_str) if !!@body_str

      patch_char(@yaml_front_matter_str + @body_str)
    end

    def wp_2_jekyll_md_file(i, o)
      # @@logger.info "wp_2_jekyll_md_file > #{ o }"

      wp_md = File.read(o)
      wp_md = process_md!(wp_md)
      File.write(o, wp_md)
    end

    def write_jekyll_md!
      if !has_yaml_header?(@fp) then
        @@logger.info "! #{@fp} has no yaml header"
      else
        @dir = File.dirname(@fp)
        @ext = File.extname(@fp)
        @base = File.basename(@fp, @ext)

        tmpf = Tempfile.new('wpmd_tmp')
        
        FileUtils.cp(@fp, tmpf.path, :verbose => false)
        wp_2_jekyll_md_file(tmpf.path, @fp)

        tmpf.unlink
        
      end
    end
  end
end

