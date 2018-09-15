# Wp2jekyll

This ruby gem is used for importing posts to jekyll:
1. Import Wordpress exported markdown file (yaml + markdown + xhtml) to jekyll post markdown format. (try & hint usr confirming for duplicat posts, using similarity algorithm. e.g. diff/lcs)
2. Transform xhtml elements inside imported markdown, as more as possible, to plain jekyll markdown format. (e.g. `<a>` `<p>` `<table>`etc.)
3. Modify image and image link insde imported markdown, to plain jekyll markdown format. (e.g. `<img src>` --> ![img]({{src | relative_url}}))
    supported images refering source are:
        - `wp-content/uploads` in Wordpress's file storage.
        - blogger post, saved by crawler script, as separate parts: `title`, `author`, `timestamp`, `body`, `images/o[img-file-name]`.
        - Google Photo Library, identified by local `~/.wp2jekyll/usr/[usrname]/google-photo-api-credentials.json`  . (search by image file name)


## Setup

### Google Photo API client credential

request a OAuth2 client credential, as described at https://developers.google.com/photos/library/guides/get-started#request-id,
then put json file to
`~/.wp2jekyll/usr/$USER/google-photo-api-oauth2-client-credentials.json`

### Gemfile

`gem "wp2jekyll", path: "../wp2jekyll"`


## Usage

Sample Rakefile:

```

require 'wp2jekyll'

task :rn_wp_md do
  Wp2jekyll.rename_md_posts_indir(wp_md_dir)
end

task :import_wp_post do
  Wp2jekyll.merge_markdown_posts(from_dir: wp_md_dir, to_jekyll_posts_dir: jekyll_post_dir)
end

task :wp_to_jekyll_md do # NOTE: modify posts inplace
  Wp2jekyll.process_wordpress_md_in_dir(jekyll_post_dir)
end

task :import_blogger_post do
    Wp2jekyll.import_blogger_post(from_grabbed_dir: blogspot_archive_dir,
                                  to_dir: jekyll_post_dir,
                                  to_img_dir: jekyll_image_dir,
                                  replace_meta: { 'author' => 'theme' }
                                 )   
end

task :import_markdown_posts do
  merge_md_dir.each do |d| 
    Wp2jekyll.merge_markdown_posts(from_dir: d, to_jekyll_posts_dir: jekyll_post_dir)
  end 
end

task :merge_wp_files do
  Wp2jekyll.merge_files(from_dir: wp_asset_dir, to_dir:File.join(jekyll_source_dir, File.basename(wp_asset_dir)))
end

task :import_google_photo do
    Wp2jekyll.import_google_photo(posts_dir: jekyll_post_dir, image_dir: jekyll_image_dir)
end

task :merge_local_images do
  wp_img_dirs.each do |dir|
    Wp2jekyll.merge_local_images(from_dir:dir, to_image_dir:jekyll_image_dir)
  end
end

# -------------------------------------------------------------------------

task t_wp: [:merge_wp_files, :rn_wp_md, :import_wp_post, :wp_to_jekyll_md]

```
