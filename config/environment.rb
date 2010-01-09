# coding: utf-8
# Be sure to restart your server when you modify this file.

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here

  # Skip frameworks you're not going to use (only works if using vendor/rails)
  config.frameworks -= [ :active_resource, :active_record ]

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/models )

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  config.action_controller.session = {
    :session_key => '_csv2onix_session',
    :secret      => '02f14b66e95659064a2c91cfc95827fc'
  }

  config.gem "mime-types", :version => "1.16", :lib => "mime/types"
  config.gem "jeremyevans-exception_notification", :version => "1.0.20100106", :lib => "exception_notifier"
  config.gem "onix",  :version => "0.7.8"
  config.gem "ean13", :version => "1.4"
  config.gem "upc",   :version => "1.0"
  config.gem "chronic", :version => "0.2.3"
  config.gem "formtastic", :version => "0.9.1"

  # FasterCSV is included in 1.9, but called CSV. Alias it to
  # the FasterCSV constant so our app won't know the difference
  #
  # This shim borrowed from Gregory Brown
  # http://ruport.blogspot.com/2008/03/fastercsv-api-shim-for-19.html
  if RUBY_VERSION < "1.9"
    config.gem "fastercsv",       :version => "1.5.0"
  else
    require "csv"
    unless defined? FasterCSV
      class Object
        FCSV = FasterCSV = CSV
        alias_method :FasterCSV, :CSV
      end
    end
  end
end

require 'bigdecimal'
require 'fileutils'
require 'yaml'
