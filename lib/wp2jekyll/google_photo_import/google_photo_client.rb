require 'fileutils'
require 'pathname'

require 'uri'
require 'tempfile'
require 'json'
require 'yaml'
require 'date'

require 'net/http'

require 'googleauth'
require 'googleauth/stores/file_token_store'

module Wp2jekyll
  # [Concepts:](https://developers.google.com/photos/library/guides/overview)
  #   Library: media stored in the user's Google Photos account.
  #   Albums: media collections which can be shared with other users.
  #   Media items: photos, videos, and their metadata.
  #   Sharing: feature that enables users to share their media with other users.
  class GooglePhotoClient
    include DebugLogger

    attr_accessor :known_images
    attr_reader   :secret_dir
    attr_reader   :credential_fpath
    attr_reader   :token_store_fp
    attr_reader   :key_store_fp

    attr_reader   :media_item_store

    # https://developers.google.com/photos/library/guides/authentication-authorization
    OAuth2_SCOPE_read_photo = 'https://www.googleapis.com/auth/photoslibrary.readonly'

    def initialize
      @known_images = {} # img_fn => img_id
      @secret_dir = "#{ENV['HOME']}/.wp2jekyll/usr/#{ENV['USER']}"
      @credential_fpath = "#{secret_dir}/google-photo-api-oauth2-client-credentials.json"

      @token_store_fp = "#{secret_dir}/tokens.yaml"
      @key_store_fp = "#{secret_dir}/apikeys.yaml"

      @media_item_store = MediaItemStore.new("#{secret_dir}/media_item_store.json")
      # File.delete @token_store_fp # TODO debug
    end

    OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'

    def get_api_key
      YAML.load(File.read(@key_store_fp))['google_photo']
    end

    # get authorized for Google Photo API
    def get_credentials
      client_id = Google::Auth::ClientId.from_file(credential_fpath)
      token_store = Google::Auth::Stores::FileTokenStore.new( :file => token_store_fp)
      authorizer = Google::Auth::UserAuthorizer.new(client_id, OAuth2_SCOPE_read_photo, token_store)
      
      user_id = ENV['USER']
      credentials = authorizer.get_credentials(user_id)
      if credentials.nil?
        url = authorizer.get_authorization_url(base_url: OOB_URI )
        puts "Open #{url} in your browser and enter the resulting code:"
        code = gets
        credentials = authorizer.get_and_store_credentials_from_code(
          user_id: user_id, code: code, base_url: OOB_URI)
      end
      
      # OK to use credentials
      @@logger.debug "Google API credentials : #{credentials.inspect}"
      credentials
    end
    
    # TODO: no api to search by image file name, now fetching one year's.
    # @param [Date] date The date one year range end at.
    # @return [Hash] {image_filename =>`media item ID`} of Google Photo Images in one year before `date`.
    def search_image_in_period(img_fn, from_date, to_date)
      uri = URI('https://photoslibrary.googleapis.com/v1/mediaItems:search')
      # uri = URI('https://content-photoslibrary.googleapis.com/v1/mediaItems:search')

      cred = get_credentials
      # params = {
      #   :key => get_api_key,
      #   :access_token => cred.access_token
      # }
      # uri.query = URI.encode_www_form(params)

      # [Google Photo API: mediaitem::search need POST method](https://developers.google.com/photos/library/reference/rest/)
      req = Net::HTTP::Post.new(uri)

      req['Content-type'] = 'application/json'
      req['Authorization'] = "Bearer #{cred.access_token}"

      req_body_hash = {
        "pageSize": "100",
        "filters": {
          "mediaTypeFilter": {
            "mediaTypes": [ "PHOTO" ]
          },
          "dateFilter": {
            "ranges": [
              {
                "startDate": {
                  "year": from_date.year,
                  "month": from_date.month,
                  "day": from_date.day
                },
                "endDate": {
                  "year": to_date.year,
                  "month": to_date.month,
                  "day": to_date.day
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

        http = Net::HTTP.new(uri.hostname, uri.port)
        # http.set_debug_output($stderr)
        http.use_ssl= true
        res = http.start {|http|
          http.request(req)
        }

        if res.is_a?(Net::HTTPSuccess)
          res_hash = JSON.parse res.body
          
          # inspect respond to find image
          img_id = nil

          res_hash['mediaItems'].each do |mih|
            @media_item_store.store mih['id'], mih

            if mih['filename'].include? img_fn
              @@logger.info "!found #{mih['filename']}, search Google Photo for #{img_fn}".green
              img_id = mih['id']
            end
          end

          return img_id if nil != img_id

          # image not found, continue quering next page
          nextPageToken = res_hash['nextPageToken']
          if nil != nextPageToken
            req_body_hash["pageToken"] = nextPageToken
          else
            req_body_hash.delete "pageToken"
            break
          end
        else
          @@logger.debug "!Got #{res.inspect} when search Google Photo Image.".yellow
          @@logger.debug res.body.yellow
          break
        end
      end

      nil
    end

    # @img_fn [String]: image file name to search in Google Library
    # @from_date [String]: "YYYY-mm-dd" start date of search time range
    # @to_date [String]: "YYYY-mm-dd" end date of search time range
    #
    # @return
    #   - [String]: image mediaItem id
    #   - [nil]; image not found
    def search_img_id(img_fn:, from_date:, to_date:)
      id = @media_item_store.load(img_fn)

      return id if nil != id
      
      id = search_image_in_period(img_fn, Date.parse(from_date), Date.parse(to_date))
    end

    def stream_image(img_uri, sav_fpath)
      uri = URI(img_uri)
      Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
        req = Net::HTTP::Get.new uri

        http.request req do |response|
          open sav_fpath, 'w' do |io|
            response.readbody do |chunk|
              @@logger.info "...download image #{io.write chunk}"
            end
          end

        end
      end

      system "open #{sav_fpath}" # TODO DEBUG
      sav_fpath
    end

    def download_image_by_id(img_id, fpath)
      uri = URI('https://photoslibrary.googleapis.com/v1/mediaItems')
      req = Net::HTTP::Post.new(uri)
      req['Content-type'] = 'application/json'
      req['Authorization'] = "Bearer #{get_credentials.access_token}"
      req_body_hash = { 'mediaItemId' => img_id }
      req.body = JSON.generate(req_body_hash)

      http = Net::HTTP.new(uri.hostname, uri.port)
      # http.set_debug_output($stderr)
      http.use_ssl= true
      res = http.start {|http|
        http.request(req)
      }

      if res.is_a?(Net::HTTPSuccess)
        res_hash = JSON.parse res.body
        img_meta = res_hash['mediaMetadata']
        original_uri = res_hash['baseUrl'] + "=w#{img_meta['width']}-h#{img_meta['height']}"
        return stream_image(original_uri, fpath)
      else
        @@logger.warn "!Save image to #{fpath} failed."
        return nil
      end
    end

    def search_and_download(img_fn:, from_date:, to_date:, to_path:)
      if id = search_img_id(img_fn: img_fn, from_date: from_date, to_date: to_date)
        download_image_by_id(id, to_path)
      end
    end

  end

end

