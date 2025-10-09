# Use direct routes for public storage (R2), proxy for local/private storage
if ENV['CLOUDFLARE_PUBLIC_URL'].present?
  Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_redirect
else
  Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_proxy
end

Rails.application.config.active_storage.variant_processor = :vips

# Override URL generation for Cloudflare R2 to use custom public domain
Rails.application.config.after_initialize do
  if ENV['CLOUDFLARE_PUBLIC_URL'].present?
    ActiveStorage::Blob.class_eval do
      def url(expires_in: ActiveStorage.service_urls_expire_in, disposition: :inline, filename: nil, **options)
        if service_name == :cloudflare
          "#{ENV['CLOUDFLARE_PUBLIC_URL']}/#{key}"
        else
          super
        end
      end
    end
  end
end
