require 'fileutils'
require 'pathname'
require 'logger'
require 'colorize'

require 'uri'
require 'tempfile'
require 'json'
require 'date'

module Wp2jekyll
  # [Concepts:](https://developers.google.com/photos/library/guides/overview)
  #   Library: media stored in the user's Google Photos account.
  #   Albums: media collections which can be shared with other users.
  #   Media items: photos, videos, and their metadata.
  #   Sharing: feature that enables users to share their media with other users.
  class GooglePhotoClient < RestClient

    @@logger = @@logger = Logger.new(STDERR)
    @@logger.level = Logger::DEBUG

    attr_accessor :known_images

    def initialize
      super
      @known_images = {} # img_fn => img_id
    end
    
    private :search_image_in_one_year
    # TODO: no api to search by image file name, now fetching one year's.
    # @param [Date] date The date one year range end at.
    # @return [Hash] {image_filename =>`media item ID`} of Google Photo Images in one year before `date`.
    def search_image_in_one_year(date, img_fn)
      uri = URI('https://photoslibrary.googleapis.com/v1/mediaItems:search')
      req = Net::HTTP::Get.new(uri)
      req['Content-type'] = 'application/json'
      req['Authorization'] = "Bearer #{OAUTH2_TOKEN}" #TODO

      to_date = Date.parse(date)

      req_body_hash = {
        "pageSize":"100",
        "filters": {
          "mediaTypeFilter": {
            "mediaTypes": [ "PHOTO" ]
          },
          "dateFilter": {
            "ranges": [
              {
                "startDate": {
                  "year": date.year - 1,
                  "month": date.month,
                  "day": date.day
                },
                "endDate": {
                  "year": date.year,
                  "month": date.month,
                  "day": date.day
                }
              }
            ]
          }
        }
      }

      # query Google Photo Library for image items
      media_items = []
      loop do
        req.body = JOSN.generate(req_body_hash)

        res = Net::HTTP.start(uri.hostname, uri.port) {|http|
          http.request(req)
        }

        if res.is_a?(Net::HTTPSuccess)
          res_hash = JSON.parse res.body
          media_items.append res_hash['mediaItems']

          nextPageToken = res_hash['nextPageToken']
          if nil != nextPageToken
            req_body_hash["pageToken"] = nextPageToken
          else
            req_body_hash.delete "pageToken"
            break
          end
        else
          @@logger.debug "!Got #{res.inspect} when search Google Photo Image."
          break
        end
      end

      # process returned items
      images = {}
      media_items.each do |i|
        @known_images[i['filename']] = i['id']
        images[img_fn] = i['id'] if i['filename'].include? img_fn
      end

      return images
    end

    def get_img(img_id)
      uri = URI('https://photoslibrary.googleapis.com/v1/mediaItems')
      tmp_img_f = Tempfile.new('google_photo_tmp_img')

      Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
        req = Net::HTTP::Get.new uri

        http.request req do |response|
          open tmp_img_f.path, 'w' do |io|
            response.readbody do |chunk|
              io.write chunk
            end
          end
        end

      end
    end
  end
end

