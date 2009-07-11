# Be sure to restart your server when you modify this file.

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here

  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # ActiveRecord is required in testing, as it loads fixture testing code
  if ENV["RAILS_ENV"] == "test"
    config.frameworks -= [ :active_resource, :action_mailer]
  else
    config.frameworks -= [ :active_resource, :action_mailer, :active_record ]
  end

  # Only load the plugins named here, in the order given. By default, all plugins in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named.
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  config.action_controller.session = {
    :session_key => '_csv2onix_session',
    :secret      => '02f14b66e95659064a2c91cfc95827fc'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  config.gem "onix", :version => "0.7.1"

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
require 'mime/types'
