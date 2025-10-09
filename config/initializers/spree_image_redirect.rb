# Force Spree images to use redirect mode instead of proxy
# This ensures images are served directly from R2 instead of proxied through Rails

Rails.application.config.to_prepare do
  # Override the proxy route to redirect instead
  module ActiveStorage
    module Representations
      class ProxyController < BaseController
        include ActiveStorage::SetBlob

        def show
          # Instead of proxying, redirect to the service URL
          expires_in ActiveStorage.service_urls_expire_in
          redirect_to @representation.url(disposition: params[:disposition]), allow_other_host: true
        end
      end
    end
  end
end
