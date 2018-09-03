require 'fileutils'
require 'logger'

require 'colorize'

module Wp2jekyll
  
  class BloggerPost
    attr_accessor :post
    attr_accessor :images

    def initialize()
      @logger = Logger.new(STDERR)
      @logger.level = Logger::DEBUG

      @post = {}
      @post['title'] = ''
      @post['author'] = ''
      @post['date'] = ''
      @post['body'] = ''

      @images = []
    end
    
    def date_str
      @post['date']
    end

    def to_s
      s = "---\n"
      @post.each do |k, v|
        # @logger.debug "BloggerPost.to_s #{k}: #{v}"
        s << "#{k}: #{v}\n" if 'body' != k
      end
      s << "---\n"
      s << @post['body']
      s
    end

    def read_post(post_dir)
      # @logger.info 'BloggerPost.read_post'.yellow
      if File.directory?(post_dir)
        @post.each do |k, v|
          begin
            if 'date' == k
              @post[k] = File.read(File.join(post_dir, 'timestamp')).strip
            else
              @post[k] = File.read(File.join(post_dir, k)).strip
            end
          rescue
            @logger.info "Reading #{post_dir}/#{k} error."
          end
        end
      end
    end

    def info
      @post['date'] + ' ' + @post['title']
    end

    # get rid of leading 'o', left by python grabber
    def rename_image_files!(post_dir, img_sub_dir = 'images')
      # @logger.info 'BloggerPost.rename_image_files'.yellow
      img_dir = File.join(post_dir, img_sub_dir)
      if File.directory?(img_dir)
        Dir.glob(File.join(img_dir, '*')).each do |img|
          img_bn_new = File.basename(img).gsub(/^o/, '')
          begin
            File.rename(img, File.join(img_dir, img_bn_new))
          rescue => e
            @logger.info "Error #{e.class} #{e.message} renaming blogger image file #{img}."
          end
        end
      end
    end

    def read_images(post_dir)
      # @logger.info 'BloggerPost.read_images'.yellow
      img_dir = File.join(post_dir, 'images')
      if File.directory?(img_dir)
        Dir.glob(File.join(img_dir, '*')).each do |oimg|
          img_bn = File.basename(oimg).gsub(/^o/, '')
          if @post['body'].include?(img_bn)
            @images.append(oimg)
            @logger.info "Image #{img_bn} in Blogger post #{info}"
          else
            @logger.info "? Image #{img_bn} NOT in Blogger post #{info}".yellow
          end
        end
      end
    end

    def read_grabbed_post_dir(dir)
      rename_image_files!(dir)
      read_post(dir)
      read_images(dir)
    end

  end

end

