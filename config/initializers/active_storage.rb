# Use direct routes for public storage (R2), proxy for local/private storage
if ENV['CLOUDFLARE_PUBLIC_URL'].present?
  Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_redirect
else
  Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_proxy
end

Rails.application.config.active_storage.variant_processor = :vips
