require 'fileutils'
require 'pathname'
require 'logger'
require 'colorize'



module Wp2jekyll
  # [Concepts:](https://developers.google.com/photos/library/guides/overview)
  #   Library: media stored in the user's Google Photos account.
  #   Albums: media collections which can be shared with other users.
  #   Media items: photos, videos, and their metadata.
  #   Sharing: feature that enables users to share their media with other users.
  class GooglePhotoClient < RestClient
    def initialize(credential, config)
      super
    end

    # [return] bool : is `filename` image in the Google photo album ?
    def search_image(filename)
    end
  end
end

