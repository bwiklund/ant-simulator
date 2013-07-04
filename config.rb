require 'slim'

set :css_dir, 'css'
set :js_dir, 'js'
set :images_dir, 'images'

set :slim, :layout_engine => :slim

configure :build do
  # For example, change the Compass output style for deployment
  activate :minify_css

  # Minify Javascript on build
  activate :minify_javascript

  # Enable cache buster
  activate :asset_hash

  # Use relative URLs
  activate :relative_assets

  # Or use a different image path
  # set :http_path, "/Content/images/"
end
