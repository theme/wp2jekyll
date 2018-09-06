require 'fileutils'
require 'pathname'
require 'logger'
require 'colorize'

require 'uri'
require 'tempfile'
require 'json'
require 'date'

require 'net/http'

require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'httpclient'

module Wp2jekyll
  # [Concepts:](https://developers.google.com/photos/library/guides/overview)
  #   Library: media stored in the user's Google Photos account.
  #   Albums: media collections which can be shared with other users.
  #   Media items: photos, videos, and their metadata.
  #   Sharing: feature that enables users to share their media with other users.
  class GooglePhotoClient

    @@logger = Logger.new(STDERR)
    @@logger.level = Logger::DEBUG

    attr_accessor :known_images

    def initialize
      @known_images = {} # img_fn => img_id
    end

    OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'

    # get authorized for Google Photo API
    def get_credentials
      secret_dir = "#{ENV['HOME']}/.wp2jekyll/usr/#{ENV['USER']}"
      credential_fpath = "#{secret_dir}/google-photo-api-oauth2-client-credentials.json"


      # https://developers.google.com/photos/library/guides/authentication-authorization
      scope = 'https://www.googleapis.com/auth/photoslibrary.readonly'

      client_id = Google::Auth::ClientId.from_file(credential_fpath)
      token_store_fp = "#{secret_dir}/tokens.yaml"
      token_store = Google::Auth::Stores::FileTokenStore.new( :file => token_store_fp)
      authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)
      
      user_id = Process.uid
      credentials = authorizer.get_credentials(user_id)
      if credentials.nil?
        url = authorizer.get_authorization_url(base_url: OOB_URI )
        puts "Open #{url} in your browser and enter the resulting code:"
        code = gets
        credentials = authorizer.get_and_store_credentials_from_code(
          user_id: user_id, code: code, base_url: OOB_URI)
      end
      
      # OK to use credentials
      @@logger.debug "Google API credentials : #{credentials}"
      credentials
    end
    
    # TODO: no api to search by image file name, now fetching one year's.
    # @param [Date] date The date one year range end at.
    # @return [Hash] {image_filename =>`media item ID`} of Google Photo Images in one year before `date`.
    def search_image_in_one_year(date, img_fn)
      uri = URI('https://photoslibrary.googleapis.com/v1/mediaItems:search')
      cred = get_credentials
      @@logger.debug "Bearer #{cred.access_token}"

      clnt = HTTPClient.new
      header = {
        'Content-type' => 'application/json',
        'Authorization' => "Bearer #{cred.access_token}"
      }

      ###
      req = Net::HTTP::Get.new(uri)
      req['Content-type'] = 'application/json'
      req['Authorization'] = "Bearer #{cred.access_token}" #TODO
      
      clnt.debug_dev=STDOUT
      debug_uri = URI('https://photoslibrary.googleapis.com/v1/mediaItems')
      debug_body_hash = {
        "pageSize":"100",
      }
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
      count = 0
      loop do
        @@logger.debug "#{count = count + 1 } query Google Photo Library for image items"
        req.body = JSON.generate(req_body_hash)

        res = clnt.get(debug_uri, :header => header, :body => JSON.generate(debug_body_hash))
        # res = clnt.get(uri, :header => header, :body => JSON.generate(req_body_hash))
        @@logger.debug res.body
        # res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
        #   http.request(req)
        # }

        # if res.is_a?(Net::HTTPSuccess)
        #   res_hash = JSON.parse res.body
        #   media_items.append res_hash['mediaItems']

        #   nextPageToken = res_hash['nextPageToken']
        #   if nil != nextPageToken
        #     req_body_hash["pageToken"] = nextPageToken
        #   else
        #     req_body_hash.delete "pageToken"
        #     break
        #   end
        # else
        #   @@logger.debug "!Got #{res.inspect} when search Google Photo Image.".yellow
        #   @@logger.debug res.body.yellow
        #   break
        # end

        res_hash = JSON.parse res.body
        media_items.append res_hash['mediaItems']

        nextPageToken = res_hash['nextPageToken']
        if nil != nextPageToken
          req_body_hash["pageToken"] = nextPageToken
        else
          req_body_hash.delete "pageToken"
          break
        end
      end

      # process returned items
      images = {}
      media_items.each do |i|
        @@logger.debug i
        @known_images[i['filename']] = i['id']
        images[img_fn] = i['id'] if i['filename'].include? img_fn
      end
      return images
    end

    def search_img_id(img_fn, date)
      hash = search_image_in_one_year(date, img_fn)
      id = hash[img_fn]
      if nil != id
        @@logger.info "Image found in Google Photo: #{img_fn} => id: #{id}"
      end
      return id
    end

    def save_img(img_id, fpath)
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

