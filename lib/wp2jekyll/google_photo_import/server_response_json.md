
https://developers.google.com/photos/library/reference/rest/v1/mediaItems/get

- MediaItem json

      {
          "id": string,
          "description": string,
          "productUrl": string,
          "baseUrl": string,
          "mimeType": string,
          "mediaMetadata": {
            object(MediaMetadata)
          },
          "contributorInfo": {
            object(ContributorInfo)
          },
          "filename": string
      }

- MediaMetadata

      {
        "creationTime": string,
        "width": string,
        "height": string,

        // Union field metadata can be only one of the following:
        "photo": {
          object(Photo)
        },
        "video": {
          object(Video)
        }
        // End of list of possible types for union field metadata.
      }

- ContributorInfo

      {
        "profilePictureBaseUrl": string,
        "displayName": string
      }

- Photo

      {
        "cameraMake": string,
        "cameraModel": string,
        "focalLength": number,
        "apertureFNumber": number,
        "isoEquivalent": number,
        "exposureTime": string
      }
