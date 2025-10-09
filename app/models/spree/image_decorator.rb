# Override Spree image URL generation to use direct R2 URLs
module Spree
  module ImageDecorator
    # Override the cdn_image_url method to return direct R2 URLs
    def cdn_image_url(attachment_or_variant)
      return unless attachment_or_variant.attached?

      # Get the variant or attachment
      variant = attachment_or_variant.is_a?(ActiveStorage::Variant) ||
                attachment_or_variant.is_a?(ActiveStorage::VariantWithRecord) ?
                attachment_or_variant :
                attachment_or_variant

      # Return direct service URL instead of going through Rails routes
      if variant.respond_to?(:service_url)
        variant.service_url(expires_in: 1.hour, disposition: 'inline')
      elsif variant.respond_to?(:url)
        variant.url
      else
        attachment_or_variant.url
      end
    end
  end
end

# Apply the decorator
Spree::Image.prepend(Spree::ImageDecorator) if defined?(Spree::Image)
