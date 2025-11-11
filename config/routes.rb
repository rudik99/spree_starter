require "sidekiq/web" # require the web UI

Rails.application.routes.draw do
  Spree::Core::Engine.add_routes do
    # Storefront routes
    scope '(:locale)', locale: /#{Spree.available_locales.join('|')}/, defaults: { locale: nil } do
      devise_for(
        Spree.user_class.model_name.singular_route_key,
        class_name: Spree.user_class.to_s,
        path: :user,
        controllers: {
          sessions: 'spree/user_sessions',
          passwords: 'spree/user_passwords',
          registrations: 'spree/user_registrations'
        },
        router_name: :spree
      )
    end

    # Admin authentication
    devise_for(
      Spree.admin_user_class.model_name.singular_route_key,
      class_name: Spree.admin_user_class.to_s,
      controllers: {
        sessions: 'spree/admin/user_sessions',
        passwords: 'spree/admin/user_passwords'
      },
      skip: :registrations,
      path: :admin_user,
      router_name: :spree
    )
  end
  # This line mounts Spree's routes at the root of your application.
  # This means, any requests to URLs such as /products, will go to
  # Spree::ProductsController.
  # If you would like to change where this engine is mounted, simply change the
  # :at option to something different.
  #
  # We ask that you don't use the :as option here, as Spree relies on it being
  # the default of "spree".
  mount Spree::Core::Engine, at: '/'

  # Override Spree's cdn_image direct route to generate direct R2 URLs
  # IMPORTANT: This must be defined AFTER mounting Spree::Core::Engine
  # because Spree also defines this route and would override our definition
  direct :cdn_image do |model, options|
    # For Cloudflare R2, generate direct public URLs to bypass Rails completely
    if model.blob.service_name.to_s == 'cloudflare'
      public_url_base = ENV.fetch('CLOUDFLARE_PUBLIC_URL', 'https://media.smarthomeiq.com.au')
      bucket = ENV.fetch('CLOUDFLARE_BUCKET', 'spree-production')

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
        route_for(
          :rails_service_blob_redirect,
          model.signed_id,
          model.filename,
          opts
        )
      else
        signed_blob_id = model.blob.signed_id
        variation_key  = model.variation.key
        filename       = model.blob.filename

        route_for(
          :rails_blob_representation_redirect,
          signed_blob_id,
          variation_key,
          filename,
          opts
        )
      end
    end
  end

  mount Sidekiq::Web => "/sidekiq" # access it at http://localhost:3000/sidekiq

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "spree/home#index"
end
