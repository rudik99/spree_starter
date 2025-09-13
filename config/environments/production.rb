require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  # https://guides.rubyonrails.org/caching_with_rails.html#activesupport-cache-rediscachestore
  if ENV['REDIS_CACHE_URL'].present?
    cache_servers = ENV['REDIS_CACHE_URL'].split(',') # if multiple instances are provided
    config.cache_store = :redis_cache_store, {
      url: cache_servers,
      connect_timeout:    30,  # Defaults to 1 second
      read_timeout:       0.2, # Defaults to 1 second
      write_timeout:      0.2, # Defaults to 1 second
      reconnect_attempts: 2,   # Defaults to 1
    }
  else
    config.cache_store = :memory_store
  end

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :sidekiq

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { 
    host: ENV.fetch('MAILER_DEFAULT_HOST', 'localhost'),
    protocol: ENV.fetch('MAILER_DEFAULT_PROTOCOL', 'https')
  }
  
  # Set default from address for Action Mailer
  config.action_mailer.default_options = {
    from: ENV.fetch('SPREE_MAIL_FROM', 'noreply@example.com')
  }

  # Configure email delivery method
  if ENV['AWS_ACCESS_KEY_ID'].present? && ENV['AWS_SECRET_ACCESS_KEY'].present?
    # Use AWS SES API (bypasses SMTP port restrictions)
    require_relative '../../lib/aws_ses_delivery_method'
    config.action_mailer.delivery_method = AwsSesDeliveryMethod
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true
    
    config.action_mailer.aws_ses_delivery_method_settings = {
      region: ENV.fetch('AWS_REGION', 'ap-southeast-2'),
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    }
  elsif ENV['SMTP_ADDRESS'].present?
    # Fallback to SMTP (may not work on Railway due to port restrictions)
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true
    
    # Use MAILER_DEFAULT_HOST as fallback for SMTP_DOMAIN if not specified
    smtp_domain = ENV.fetch('SMTP_DOMAIN', ENV.fetch('MAILER_DEFAULT_HOST', 'localhost'))
    
    config.action_mailer.smtp_settings = {
      address: ENV['SMTP_ADDRESS'],
      port: ENV.fetch('SMTP_PORT', 587).to_i,
      domain: smtp_domain,
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD'],
      authentication: ENV.fetch('SMTP_AUTHENTICATION', 'plain').to_sym,
      enable_starttls_auto: ENV.fetch('SMTP_ENABLE_STARTTLS_AUTO', 'true') == 'true',
      openssl_verify_mode: ENV.fetch('SMTP_OPENSSL_VERIFY_MODE', 'peer')
    }
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
