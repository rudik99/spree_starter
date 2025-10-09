# Use direct routes for public storage (R2), proxy for local/private storage
if ENV['CLOUDFLARE_PUBLIC_URL'].present?
  Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_redirect
  Rails.application.config.active_storage.draw_routes = false
else
  Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_proxy
end

Rails.application.config.active_storage.variant_processor = :vips

# Override URL generation for Cloudflare R2 to use custom public domain
Rails.application.config.after_initialize do
  if ENV['CLOUDFLARE_PUBLIC_URL'].present?
    # Override Blob URLs
    ActiveStorage::Blob.class_eval do
      def url(expires_in: ActiveStorage.service_urls_expire_in, disposition: :inline, filename: nil, **options)
        if service_name == :cloudflare
          "#{ENV['CLOUDFLARE_PUBLIC_URL']}/#{key}"
        else
          super
        end
      end
    end

    # Override Variant URLs to use Cloudflare Image Resizing
    # This allows serving transformed images directly from R2
    # Format: https://media.domain.com/cdn-cgi/image/width=400,quality=75/image-key
    ActiveStorage::VariantWithRecord.class_eval do
      def url(**options)
        service_url = blob.url

        # Extract transformation params
        transformations = variation.transformations
        cf_params = []

        if transformations[:resize_to_fill]
          width, height = transformations[:resize_to_fill]
          cf_params << "width=#{width}" if width
          cf_params << "height=#{height}" if height
        elsif transformations[:resize_to_limit]
          width, height = transformations[:resize_to_limit]
          cf_params << "width=#{width}" if width
          cf_params << "height=#{height}" if height
        end

        # Add quality if specified in saver options
        if transformations[:saver]&.dig(:quality)
          cf_params << "quality=#{transformations[:saver][:quality]}"
        else
          cf_params << "quality=75" # default
        end

        # Add format if specified
        if transformations[:format]
          cf_params << "format=#{transformations[:format]}"
        end

        # Build Cloudflare Image Resizing URL
        if cf_params.any? && service_url.start_with?(ENV['CLOUDFLARE_PUBLIC_URL'])
          base_url = service_url.sub(ENV['CLOUDFLARE_PUBLIC_URL'], "#{ENV['CLOUDFLARE_PUBLIC_URL']}/cdn-cgi/image/#{cf_params.join(',')}")
          base_url
        else
          service_url
        end
      end
    end
  end
end
