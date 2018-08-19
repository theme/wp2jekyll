require 'fileutils'
require 'cgi'
require 'uri'
require 'logger'

require 'nokogiri'
require 'colorize'

module Wp2jekyll
  class MarkdownLink
    @cap = ''
    @link = ''
    @title = ''
    @is_img = false
    RE = %r{((\!)?\[(.*?)\]\(\s*([^"\s]*?)\s*("([^"]*?)")?\)(\{.*?\})?)}m
    #E = %r{12--2--[3--3--]-(   4--------4  5"6------6"5--)7-{----}7-1}m
    @init_valid = false
    attr_accessor :cap
    attr_accessor :title
    attr_accessor :link
    attr_accessor :is_img
    attr_accessor :re
    def initialize(str)
      @logger = Logger.new(STDERR)
      @logger.level = Logger::DEBUG
      if m = RE.match(str)
        @cap = m[3] || ''
        @link = m[4] || ''
        @title = m[6] || ''
        @is_img = ('!' == m[2]) ? true : false
        @init_valid = true
        @tail = m[7] || ''
        @logger.debug 'MarkdownLink: ' + "#{@is_img ? '!' : ''}[#{@cap.red}](#{@link.green} \"#{@title.blue}\")#{@tail.magenta}"
      end
    end

    def to_s
      if @is_img
        return "![#{@cap}](#{@link})"
      else # not image
        if @title.empty?
          return "[#{@cap}](#{@link})"
        else
          return "[#{@cap}](#{@link} \"#{title}\")"
        end
      end
    end
  end
  
  class JekyllMarkdown
    def initialize(fp = '')
      @fp = fp # file path
      @logger = Logger.new(STDERR)
      # @logger.level = Logger::INFO
      @logger.level = Logger::DEBUG
      # DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
    end

    # (from: jekyll/utils.rb)
    # Returns true if the YAML front matter is present.
    def has_yaml_header?(file)
      # !! change 0 to true
      !!(File.open(file, "rb", &:readline) =~ %r!\A---\s*\r?\n!)
    rescue EOFError
      false
    end 

  end

  class WordpressMarkdown < JekyllMarkdown
    attr_accessor :suspicious_url_contains
    attr_accessor :relative_url_contains
    def initialize(fp = '')
      super(fp)
      @@code_cnt = 0
      @suspicious_url_contains = [ '/home/theme' ]
      @relative_url_contains = ['wp-content']
    end

    def is_url_suspicious?(ln)
      # @logger.debug 'suspicious? ' + ln
      for s in @suspicious_url_contains do
        if ln.include? s then
          return true
        end
      end
      false
    end

    def should_url_relative?(ln)
      # @logger.debug 'relative? ' + ln
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

    def url_to_liquid(url)
      return "{{ \"#{url_to_relative(url)}\" | relative_url }}" 
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
    #                                                                                                        })'
    ###

    def patch_unescape_xml_char(txt)
      return CGI.unescapeHTML(txt)
    end

    def patch_list_like(txt, lead = '*', compress = false)
      # @logger.debug 'patch_list_like: ' + lead
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

    def xml_figure_to_md_s(txt)
      frag = Nokogiri::XML::DocumentFragment.parse(txt) do |config|
        config.nonet.recover
      end

      fig = frag.css("figure").first
        cap = fig.css("figcaption").text
        img = fig.css("img").first
        figure_md  = '!' + md_link(cap, img['src'])
        @logger.debug 'xml_figure ' + figure_md.light_cyan
        return figure_md
    end

    # construct markdown link from caption and url (aware of relative )
    def md_link(cap, url)
      return '' if nil == url
      @logger.debug 'md_link: '.green + url
      if !should_url_relative?(url) then
        return "[#{cap}](#{url})"
      else
        return "[#{cap}]({{ \"#{url_to_relative(url)}\" | relative_url }})"
      end
    end

    # TODO
    def parse_xml_to_md_array(xml)
      frag = Nokogiri::XML::DocumentFragment.parse(xml)

      md_pieces = [ ]

      for n in frag.children
        case n.type
        when Nokogiri::XML::Node::TEXT_NODE
          md_pieces.append n
          @logger.debug n.text.yellow
        when Nokogiri::XML::Node::ELEMENT_NODE
          @logger.debug "<#{n.name}>".yellow
          case n.name
          when "figure"
            md_pieces.append xml_figure_to_md_s(n.to_s)
          when "img"
            md_pieces.append '!' + md_link(n['alt'], n['src'])
          when 'pre'
            md_pieces.append "\n```\n" + n + "\n```\n"
          when 'table'
            trs_md = []
            n.css('tr').each do |tr|
              rowdata_a = []
              tr.css('td').each do |td|
                td_md = parse_xml_to_md_array(td).join('')
                rowdata_a.append(td_md) if !td_md.empty?
              end
              trs_md.append ('| ' + rowdata_a.join(' | ') + " |")
            end
            md_pieces.append "\n" + trs_md.join("\n") + "\n"
          when 'a'
            a_cap = parse_xml_to_md_array(n.inner_html).join()
            a_link = n['href'] || ''
            a_md = "[#{a_cap}](#{a_link})"
            md_pieces.append a_md
          else
            md_pieces.append parse_xml_to_md_array(n.inner_html.gsub(/(^\s*)|(\s*$)/, "\n").strip).join()
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

    def md_modify_link(txt)
      txt.scan(MarkdownLink::RE).each do |m|
        ln = m[0]
        @logger.debug "========== md_modify_link #{ln} ============"
        mdlk = MarkdownLink.new(m[0])
        if is_url_suspicious?(mdlk.link) then
          @logger.warn 'suspicious: ' + mdlk.link.red
          txt.gsub!(ln, '') # delete to prevent being published
          next
        end

        # relative
        if is_uri?(mdlk.link) and should_url_relative?(mdlk.link) then
          @logger.debug 'url should be relative: ' + mdlk.link.green
          mdlk.link = url_to_liquid(mdlk.link)
          txt.gsub!(ln, mdlk.to_s)
        end

        # drop tail {}
        txt.gsub!(ln, mdlk.to_s)

      end
      @logger.debug '^^^^^^^^^^ modify link ^^^^^^^^^^^^'
      return txt
    end

    def compress_blank_lines(txt)
      # leading 2 line
      txt.gsub!(/^(\s*?\n)+/m, "\n\n")
      # tail 2 line
      txt.gsub!(/(\n\s*?)+$/m, "\n\n")

      # inner lines
      re = /(\n\s*?){3,}/m
      while re.match?(txt) do
        txt.gsub!(re, "\n\n")
      end
      return txt
    end

    # indent code section in for jekyll markdown
    def patch_code(txt, indent = 8) # -> String
      match = txt.scan(%r{(\[code\](.*?)\[/code\])}m)
      for m in match do 
        @@code_cnt += 1

        if !!m then
          code = m[1]
          code.strip!
          code.gsub!(/^[ \t\r\f]*/m, " "*indent) # indent code

          txt.gsub!(m[0], "\n" + code + "\n\n")
        end
      end

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
      return txt
    end

    def process_md_header(header)
      # process header
      header.gsub!(/^permalink:/, 'permalink_wp:') # wordpress exported
      header = patch_unescape_xml_char(header)
    end

    def process_md_body(body_str)
      body_str  = parse_xml_to_md_array(body_str).join('') # xml

      # mardown link
      body_str = md_modify_link(body_str)
      #
      # markdown quote
      body_str = patch_quote(body_str)

      # # markdown list
      body_str = patch_list_like(body_str, '*', true)
      #
      # # pre formatted
      body_str = patch_code(body_str)
      #
      # # section titles
      body_str = patch_unescape_xml_char(body_str)

      body_str = patch_h1h2_space(body_str)
    end

    def process_md(fulltxt)
      m = /(^---.*?---)?(.*)/m.match(fulltxt)
      yaml_front_matter  = m[1] || ''
      body_str = m[2] || ''

      # @logger.debug 'yaml_front_matter: ' + yaml_front_matter
      yaml_front_matter = process_md_header(yaml_front_matter) if !!yaml_front_matter

      # @logger.debug 'body_str: ' + body_str
      body_str = process_md_body(body_str) if !!body_str

      patch_char(yaml_front_matter + body_str)
    end

    def wp_2_jekyll_md_file(i, o)
      @logger.info "wp_2_jekyll_md_file > #{ o }"

      wp_md = File.read(o)
      wp_md = process_md(wp_md)
      File.write(o, wp_md)
    end

    def to_jekyll_md
      if !has_yaml_header?(@fp) then
        @logger.info "! #{@fp} has no yaml header"
      else
        @dir = File.dirname(@fp)
        @ext = File.extname(@fp)
        @base = File.basename(@fp, @ext)

        tmp = @fp + '.tmp'


          if (!File.exists?(tmp)) then
            FileUtils.cp(@fp, tmp, :verbose => false)
          end
        wp_2_jekyll_md_file(tmp, @fp)
        File.delete(tmp)
      end
    end
  end
end

