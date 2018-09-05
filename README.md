# Wp2jekyll

This ruby gem is used for importing posts to jekyll:
1. Import Wordpress exported markdown file (yaml + markdown + xhtml) to jekyll post markdown format. (try & hint usr confirming for duplicat posts, using similarity algorithm. e.g. diff/lcs)
2. Transform xhtml elements inside imported markdown, as more as possible, to plain jekyll markdown format. (e.g. <a> <p> <table> etc.)
3. Modify image and image link insde imported markdown, to plain jekyll markdown format. (e.g. <img src> --> ![img]({{src | relative_url}}))
    supported images refering source are:
        - `wp-content/uploads` in Wordpress's file storage.
        - blogger post, saved by crawler script, as separate parts: `title`, `author`, `timestamp`, `body`, `images/o[img-file-name]`.
        - local `~/.wp2jekyll/usr/[usrname]/google-photo-api-credentials.json` identified Google Photo Library. (by image file name)
    if image is missing from all sources, then importer does not modify url of image.


## Installation

As ordinary bundled gem.

Add this line to your application's Gemfile:

```ruby
gem 'wp2jekyll'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install wp2jekyll

## Setup
- Google Photo API client credential
request a OAuth2 client credential, as described at https://developers.google.com/photos/library/guides/get-started#request-id, 
then put json file to 
`~/.wp2jekyll/usr/$USER/google-photo-api-oauth2-client-credentials.json`


## Usage

For details see the code.

Overview:

- import posts: `Wp2jekyll::MarkdownFilesMerger.new.merge_dir(d, File.join(source_dir, '_posts/'))`
- `**/*.md` to jekyll format: `Wp2jekyll.process_wordpress_md_dir(source_dir)`
- import posts saved as separated parts (in dirs), checking Google Photo: `Wp2jekyll::BloggerGrabbedImporter.new.import(blogspot_archive_dir,File.join(source_dir, '_posts'),File.join(source_dir, '_images'))`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/wp2jekyll.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
