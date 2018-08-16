require 'fileutils'
require 'cgi'
require 'uri'
require 'logger'

require 'nokogiri'

module Wp2jekyll
  
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
    def initialize(fp = '')
      super(fp)
      @@code_cnt = 0
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


    def rm_bug_img(txt)
      txt.gsub(%r{!\[\]\(.*?/home/theme/.*?\)}m, '')
    end

    def patch_link_bug(txt) # [](){.xxxx} -> []()
      match_li = txt.scan(%r|((\[.*?\]\(.*?\)){.*?})|m)
      #atch_li = txt.scan(%r|01--------------)-----)|m)
      match_li.each do |m|
        txt.gsub!(m[0], m[1])
      end
      return txt
    end

    def fname_in_url(url)
      p = URI(url).path
      e = File.extname(p)
      b = File.basename(p, e) # base name
      return b
    end

    def img_md_from_xml(img_xml)
      @logger.debug 'img_md_from_xml'
      frag = Nokogiri::XML::DocumentFragment.parse(img_xml) do |config|
        config.nonet.recover
      end
      img_md = ''
      frag.css("img").each do |img|
        img_path = URI(img["src"]).path
        basen = fname_in_url(img["src"])
        alt = img["alt"]

        if !!alt && alt.include?(basen) then
          alt = basen # hack
        end

        img_md  = "![#{alt}]({{ \"#{img_path}\" | relative_url }})"
        @logger.debug img_md
      end
      img_md
    end

    # [<img ...>](xxx) -> [![img]()](xxx)
    def p_md_ln_img(txt)
      @logger.debug 'p_md_ln_img'
      txt.scan(%r{(\[(<img\ .*?>)\]\((.*?)\))}m).each do |md_ln, img_xml, md_url|
      #xt.scan(%r{\[((----------)\]\((---)\))}m).each do |md_ln, img_xml, md_url|
        p = URI(md_url).path

        new_md_url = md_url
        if md_url.include?(p) then
          new_md_url = "{{ \"#{p}\" | relative_url }}"
        end

        new_md = "[#{img_md_from_xml(img_xml)}](#{new_md_url})"
        txt.gsub!(md_ln, new_md)
      end
      return txt
    end

    def xml_figure_to_md_s(txt)
      frag = Nokogiri::XML::DocumentFragment.parse(txt) do |config|
        config.nonet.recover
      end

      md_s = []
      frag.css("figure").each do |fig|
        @logger.debug 'xml_figure_to_md_s'
        cap = fig.css("figcaption").text
        img = fig.css("img").first
        img_path = URI(img['src']).path

        figure_md  = "![#{cap}]({{ \"#{img_path}\" | relative_url }})"
        @logger.debug figure_md

        md_s.append(figure_md)
      end
      return md_s.join("\n")
    end

    def patch_xml_leftovers(txt, embed_lv = 0)
      # pair tag
      txt.scan(%r{(<(\w+)\b[^>]*>(.*)</\2>)}m).each do |tag|
      #xt.scan(%r{(<(---)------->(--)</-->)}m).each do |tag|
      #xt.scan(%r{0<1---1------->2--2</-->0}m).each do |tag|
        case tag[1]
        when 'figure' then
          patched_tag = xml_figure_to_md_s(tag[0])
          txt.gsub!(tag[0], patched_tag)
        when 'p' then
          @logger.debug '<p>...</p>'
          patched_tag = patch_xml_leftovers(tag[2], embed_lv + 1)
          txt.gsub!(tag[0], patched_tag)
          @logger.debug txt
        when 'div' then
          @logger.debug '<div>...</div>'
          patched_tag = patch_xml_leftovers(tag[2], embed_lv + 1)
          txt.gsub!(tag[0], patched_tag)
          @logger.debug txt
        else
          @logger.debug "unknown el pair : #{tag[0]}"
        end
      end

      # img in md link
      txt = p_md_ln_img(txt)

      # other single <img/>
      txt.scan(%r{(<(\w+)\b[^>]*/>)}m).each do |tag|
        case tag[1]
        when 'img' then
          txt.gsub!(tag[0], img_md_from_xml(tag[0]))
        when 'br' then
          txt.gsub!(tag[0], "\n\n")
        end
      end

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

    # def p_unfold_divs(txt)
    #   @logger.debug 'p_unfold_divs'
    #   div_re = %r{(<div.*?>(.*?)</div>)}m
    #   #iv_re = %r{0-----1----------}m
    #
    #   loop do
    #     match = txt.scan(div_re)
    #     if 0 == match.length then
    #       break
    #     end
    #
    #     for m in match do 
    #       txt.gsub!(m[0], m[1])
    #     end
    #
    #   end
    #   @logger.debug txt
    #   return compress_blank_lines(txt)
    # end

    def str_patch_group(dst_string) # helper func
      # patch leftover xml pieces
      dst_string = patch_xml_leftovers(dst_string) # xml
      # dst_string = p_unfold_divs(dst_string)

      # mardown link
      dst_string = rm_bug_img(dst_string)
      dst_string = patch_link_bug(dst_string)

      # markdown quote
      dst_string = patch_quote(dst_string)
      # markdown list
      dst_string = patch_list_like(dst_string, '*', true)

      # pre formatted
      dst_string = patch_code(dst_string)

      # section titles
      dst_string = patch_unescape_xml_char(dst_string)
      dst_string = patch_h1h2_space(dst_string)

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

