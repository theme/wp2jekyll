require 'fileutils'
require 'logger'

require 'colorize'

module Wp2jekyll
  
  class BloggerPost
    attr_accessor :post
    attr_accessor :images

    def initialize(post_dir)
      @logger = Logger.new(STDERR)
      @logger.level = Logger::DEBUG

      @post = {}
      @post['title'] = ''
      @post['author'] = ''
      @post['date'] = ''
      @post['body'] = ''

      @images = []
      read_grabbed_post_dir(post_dir)
    end
    
    def date_str
      @post['date']
    end

    def date
      Date.parse(date_str)
    end

    def to_s
      s = "---\n"
      @post.each do |k, v|
        # @logger.debug "BloggerPost.to_s #{k}: #{v}"
        s << "#{k}: \'#{v}\'\n" if 'body' != k
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
    def rename_image_files!(post_dir, img_sub_dir = 'images')  # TODO : rename none regualr image file name, like append .jpg
      # @logger.info 'BloggerPost.rename_image_files'.yellow
      img_dir = File.join(post_dir, img_sub_dir)
      if File.directory?(img_dir)
        Dir.glob(File.join(img_dir, '*')).each do |img|
          img_bn_new = File.basename(img).gsub(/^o/, '')
          img_new = File.join(img_dir, img_bn_new)
          begin
            File.rename(img, img_new)
            @logger.info "Rename image \n#{img} \n#{img_new}.".red
          rescue => e
            @logger.info "Error #{e.class} #{e.message} renaming blogger image file #{img}."
          end
        end
      end
    end

    # scan image files in post/images dir,
    # then register those used in the post body.
    # @images: [Array] list of images that is a file && used in post.
    def read_images(post_dir)
      # @logger.info 'BloggerPost.read_images'.yellow
      img_dir = File.join(post_dir, 'images')
      if File.directory?(img_dir)
        Dir.glob(File.join(img_dir, '*')).each do |i|
          img_bn = File.basename(i).gsub(/^o/, '') # in case of image files that is forgotten to be renamed.
          if @post['body'].include?(img_bn)
            @images.append(i)
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

    def replace_meta(rm)
      if rm.is_a? Hash
        rm.each do |k,v|
          @post[k] = v
        end
      else
        @@logger.info "blogger post replace meta needs a Hash object as argument."
      end
    end

  end

end
