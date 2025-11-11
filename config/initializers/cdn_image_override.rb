# Override Spree's cdn_image route to generate direct Cloudflare R2 URLs
#
# This must be in an initializer (not routes.rb) because Spree calls
# Spree::Core::Engine.draw_routes at the end of its routes file, which
# would override any direct :cdn_image definitions in our routes.rb

Rails.application.config.after_initialize do
  Rails.application.routes.draw do
    direct :cdn_image do |model, options|
      # For Cloudflare R2, generate direct public URLs to bypass Rails completely
      if model.blob.service_name.to_s == 'cloudflare'
        public_url_base = ENV.fetch('CLOUDFLARE_PUBLIC_URL', nil)
        bucket = ENV.fetch('CLOUDFLARE_BUCKET', 'spree-production')

        if public_url_base.present?
          # Get the blob key (file path in R2)
          if model.respond_to?(:key)
            # This is a blob variant/representation
            key = model.key
          else
            # This is an attachment
            key = model.blob.key
          end

          # Generate direct R2 URL: https://media.smarthomeiq.com.au/bucket-name/blob-key
          "#{public_url_base}/#{bucket}/#{key}"
        else
          # If CLOUDFLARE_PUBLIC_URL not set, fall back to redirect
          opts = options.slice(:protocol, :host, :port)
          opts[:host] = Spree.cdn_host if Spree.cdn_host.present?
          opts[:host] ||= Rails.application.routes.default_url_options[:host]
          opts[:host] ||= Spree::Store.current.url_or_custom_domain if Spree::Store.current.present?
          opts[:only_path] = true if opts[:host].blank?

          if model.respond_to?(:signed_id)
            route_for(:rails_service_blob_redirect, model.signed_id, model.filename, opts)
          else
            route_for(:rails_blob_representation_redirect, model.blob.signed_id, model.variation.key, model.blob.filename, opts)
          end
        end
      elsif model.blob.service_name == 'cloudinary' && defined?(Cloudinary)
        # Cloudinary support
        if model.class.method_defined?(:has_mvariation)
          Cloudinary::Utils.cloudinary_url(model.blob.key,
            width: model.variation.transformations[:resize_to_limit].first,
            height: model.variation.transformations[:resize_to_limit].last,
            crop: :fill
          )
        else
          Cloudinary::Utils.cloudinary_url(model.blob.key)
        end
      else
        # Fallback for local storage - use redirect routes
        opts = options.slice(:protocol, :host, :port)
        opts[:host] = Spree.cdn_host if Spree.cdn_host.present?
        opts[:host] ||= Rails.application.routes.default_url_options[:host]
        opts[:host] ||= Spree::Store.current.url_or_custom_domain if Spree::Store.current.present?
        opts[:only_path] = true if opts[:host].blank?

        if model.respond_to?(:signed_id)
          route_for(:rails_service_blob_redirect, model.signed_id, model.filename, opts)
        else
          route_for(:rails_blob_representation_redirect, model.blob.signed_id, model.variation.key, model.blob.filename, opts)
        end
      end
    end
  end
end
