# Force Spree images to use redirect mode instead of proxy
# This ensures images are served directly from R2 instead of proxied through Rails

Rails.application.config.to_prepare do
  # Override ActiveStorage variant URL generation
  module ActiveStorageRedirectOverride
    def url(**options)
      # For redirect mode, use service_url directly with expiring signature
      service_url(**options)
    end
  end

  # Apply to all variant types
  ActiveStorage::VariantWithRecord.prepend(ActiveStorageRedirectOverride) if defined?(ActiveStorage::VariantWithRecord)
end
