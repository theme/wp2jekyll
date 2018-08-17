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
    RE = %r{((\!)?\[(.*)\]\(([^"]*?)("([^"]*?)")?\)(\{.*?\})?)}m
    #E = %r{12--2---3--3----4------45-6------6-5---7-------7-1}m
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
        @cap = !!m[3] ? m[3] : ''
        @link = !!m[4] ? m[4] : ''
        @title = !!m[6] ? m[6] : ''
        @is_img = ('!' == m[2]) ? true : false
        @init_valid = true
        @tail = m[7] ? m[7] : ''
        @logger.debug "#{@is_img ? '!' : ''}[#{@cap.red}](#{@link.green} #{@title.blue})#{@tail.magenta}"
      end
    end

    def to_s
      if !@link || @link.empty?
        return ''
      else
        return "#{@is_img ? '!' : ''}[#{@cap}](#{@link})" 
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

    def img_md_from_xml(img_xml)
      img = Nokogiri::XML::DocumentFragment.parse(img_xml).css('img').first
      cap = xml_to_md(img['alt'])
      img_md  = '!' + md_link(cap, img['src'])
      @logger.debug 'img_md: ' + img_md
      img_md
    end

    def xml_figure_to_md_s(txt)
      frag = Nokogiri::XML::DocumentFragment.parse(txt) do |config|
        config.nonet.recover
      end

      fig = frag.css("figure").first
        cap = fig.css("figcaption").text
        img = fig.css("img").first
        figure_md  = '!' + md_link(cap, img['src'])
        @logger.debug 'xml_figure ' + figure_md
        return figure_md
    end

    def md_link(cap, url) # a mark down link
      if !should_url_relative?(url) then
        return "[#{cap}](#{url})"
      else
        return "[#{cap}]({{ \"#{url_to_relative(url)}\" | relative_url }})"
      end
    end

    def xml_to_md(txt, embed_lv = 0, expand_match = true)
      if expand_match then
        xml_re = %r{(<(\w+)\b[^>]*>(.*)</\2>)}m
      else
        xml_re = %r{(<(\w+)\b[^>]*>(.*?)</\2>)}m
      end
      # pair tag
      txt.scan(xml_re).each do |tag|
        case tag[1]
        when 'figure' then
          txt.gsub!(tag[0], xml_figure_to_md_s(tag[0]))

        when 'p' then
          @logger.debug '<p>...</p>'
          txt.gsub!(tag[0], xml_to_md(tag[2], embed_lv + 1, false))
        when 'a' then
          a_ng = Nokogiri::XML::DocumentFragment.parse(tag[0]).css("a")[0]

          a_cap_md = xml_to_md(tag[2], embed_lv + 1, false)

          a_md = md_link(a_cap_md, a_ng['href'])

          txt.gsub!(tag[0],a_md)

        when 'div' then # TODO is indentation needed ?
          @logger.debug '<div>...</div>'
          txt.gsub!(tag[0], xml_to_md(tag[2], embed_lv + 1, false))

        when 'table' then
          table_ng = Nokogiri::XML::DocumentFragment.parse(tag[2])
          table_md = ''
          table_ng.css('tr').each do |tr|
            rowdata_a = []
            tr.css('td').each do |td|
              rowdata_a.append(xml_to_md(td.inner_html).gsub!("\n", ' ')) # better no newline in markdown table cell
            end
            table_md += '| ' + rowdata_a.join(' | ') + " |\n"
          end
          @logger.debug table_md
          txt.gsub!(tag[0], table_md )
        when 'span' then
          @logger.debug '<span>...</span>'
          span_txt = Nokogiri::XML::DocumentFragment.parse(tag[2]).inner_text
          txt.gsub!(tag[0], span_txt )
        when 'del' then
          @logger.debug '<del>...</del>'
          patched_tag = Nokogiri::XML::DocumentFragment.parse(tag[2]).inner_text

          txt.gsub!(tag[0], '~~' + patched_tag + '~~')
        else
          @logger.debug "unknown el pair : #{tag[0]}"
        end
      end

      # other single <img/>
      txt.scan(%r{(<(\w+)\b[^>]*/>)}m).each do |tag|
        case tag[1]
        when 'img' then
          # [<img ...>](xxx) -> [![img]()](xxx)
          txt.gsub!(tag[0], img_md_from_xml(tag[0]))
        when 'br' then
          txt.gsub!(tag[0], "\n\n")
        end
      end

      return txt
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
        @logger.debug '========== md_modify_link ============'
        ln = m[0]
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

    def str_patch_group(dst_string) # helper func
      # patch leftover xml pieces
      dst_string = xml_to_md(dst_string) # xml

      # mardown link
      dst_string = md_modify_link(dst_string)
      # @logger.debug ('dst_string: ' + dst_string).yellow
      # @logger.debug '^^^^^^^^^^ str_patch_group: md_modify_link ^^^^^^^^^^^^'
      #
      # # markdown quote
      # dst_string = patch_quote(dst_string)
      # # markdown list
      # dst_string = patch_list_like(dst_string, '*', true)
      #
      # # pre formatted
      # dst_string = patch_code(dst_string)
      #
      # # section titles
      dst_string = patch_unescape_xml_char(dst_string)
      # dst_string = patch_h1h2_space(dst_string)

      @logger.debug dst_string.cyan
      dst_string
    end

    def line_patch_group(line) # helper func
      line.gsub!(/^permalink:/, 'permalink_wp:') # wordpress exported
      line.gsub!('{{}}', '{ {} }') # liquid template engine of jekyll
      line.gsub!('&#8211;', '-') # the original text is mangled by wp
      line.gsub!('&#8212;', '--')
      line.gsub!('&#8212;', '--')
      line.gsub!(/^\s*?&nbsp;\s*?$/, '') # a blank line
      line.gsub!('&nbsp;', ' ')
      return line
    end

    def wp_2_jekyll_md_file(i, o)
      @logger.info "wp_2_jekyll_md_file > #{ o }"

      # patch by line
      dst = File.open(o,'w+')
      src = File.open(i,'r')
      src.each { |line|
        line = line_patch_group(line)
        dst.puts(line)
      }
      src.close
      dst.close

      # patching by file
      dst_string = File.read(o)
      dst_string = str_patch_group(dst_string)
      File.write(o, dst_string)

    end


    # indent code section in for jekyll markdown
    def patch_code(txt, indent = 8) # -> String
      match = txt.scan(%r{(\[code\](.*?)\[/code\])}m)
      for m in match do 
        # debug
        @@code_cnt += 1
        # barlen = 75
        # cap = " patching code #{@@code_cnt} "
        # bar = "="* ((barlen - cap.length)/2)
        # puts  bar + cap + bar
        # =================================

        if !!m then
          code = m[1]
          code.strip!
          code.gsub!(/^[ \t\r\f]*/m, " "*indent) # indent code

          txt.gsub!(m[0], "\n" + code + "\n\n")
          # puts "\n" + code + "\n\n"
        end

        # puts "=" * barlen
        # =================================
      end

      return txt
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

