# Claude Code Rules for Spree Commerce Development

## Documentation Organization

### Documentation Structure

All project documentation must be organized within the `docs/` directory following this structure:

```
docs/
├── guides/          # User guides and how-to documentation
├── setup/           # Installation and setup documentation
├── deployment/      # Deployment and infrastructure documentation
└── development/     # Development guidelines and API documentation
```

### Documentation Rules

1. **Location**: All documentation files must be placed in the appropriate subdirectory under `docs/`
2. **Naming**: Use lowercase with underscores for file names (e.g., `ruby_installation.md`, `aws_ses_setup.md`)
3. **Format**: All documentation must be in Markdown format (.md extension)
4. **Organization**:
   - `docs/guides/`: End-user guides, feature documentation, and how-to articles
   - `docs/setup/`: Installation guides, environment setup, and initial configuration
   - `docs/deployment/`: Deployment processes, infrastructure setup, and production configuration
   - `docs/development/`: API documentation, development workflows, and technical architecture

5. **Content Guidelines**:
   - Start each document with a clear title and brief description
   - Use consistent heading hierarchy (# for title, ## for main sections, ### for subsections)
   - Include code examples with proper syntax highlighting
   - Add a table of contents for documents longer than 3 sections
   - Keep documentation up-to-date with code changes

6. **Cross-referencing**: Use relative links when referencing other documentation files:
   ```markdown
   See [Ruby Installation Guide](../setup/ruby_installation.md)
   ```

## General Development Guidelines

### Framework & Architecture

- Spree is built on Ruby on Rails and follows MVC architecture
- All Spree code must be namespaced under `Spree::` module
- Spree is distributed as Rails engines with separate gems (core, admin, api, storefront, emails, etc.)
- Follow Rails conventions and the Rails Security Guide
- Prefer Rails idioms and standard patterns over custom solutions

### Code Organization

- Place all models in `app/models/spree/` directory
- Place all controllers in `app/controllers/spree/` directory  
- Place all views in `app/views/spree/` directory
- Place all services in `app/services/spree/` directory
- Place all mailers in `app/mailers/spree/` directory
- Place all API serializers in `app/serializers/spree/` directory
- Place all helpers in `app/helpers/spree/` directory
- Place all jobs in `app/jobs/spree/` directory
- Place all presenters in `app/presenters/spree/` directory
- Use consistent file naming: `spree/product.rb` for `Spree::Product` class
- Group related functionality into concerns when appropriate
- Do not call `Spree::User` directly, use `Spree.user_class` instead
- Do not call `Spree::AdminUser` directly, use `Spree.admin_user_class` instead

## Naming Conventions & Structure

### Classes & Modules

```ruby
# ✅ Correct naming
module Spree
  class Product < Spree.base_class
  end
end

module Spree
  module Admin
    class ProductsController < ResourceController
    end
  end
end

# ❌ Incorrect - missing namespace
class Product < ApplicationRecord
end
```

Always inherit from `Spree.base_class` when creating models.

### File Paths

- Models: `app/models/spree/product.rb`
- Controllers: `app/controllers/spree/admin/products_controller.rb`
- Views: `app/views/spree/admin/products/`
- Decorators: `app/models/spree/product_decorator.rb`

## Model Development

### Model Patterns

- Use ActiveRecord associations appropriately, always pass `class_name` and `dependent` options
- Implement concerns for shared functionality
- Use scopes for reusable query patterns
- Include `Spree::Metadata` concern for models that need metadata support

```ruby
# ✅ Good model structure
class Spree::Product < ApplicationRecord
  include Spree::Metadata
  
  has_many :variants, class_name: 'Spree::Variant', dependent: :destroy
  has_many :product_properties, class_name: 'Spree::ProductProperty', dependent: :destroy
  has_many :properties, through: :product_properties, source: :property
  
  scope :available, -> { where(available_on: ..Time.current) }
  
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: spree_base_uniqueness_scope }
end
```

For uniqueness validation, always use `scope: spree_base_uniqueness_scope`

## Controller Development

### Controller Inheritance

- Admin controllers inherit from `Spree::Admin::ResourceController` which handles most of CRUD operations
- API controllers inherit from `Spree::Api::V2::BaseController`
- Storefront controllers inherit from `Spree::StoreController`

### Parameter Handling

- Always use strong parameters
- Always use `Spree::PermittedAttributes` to define allowed parameters for each resource

```ruby
# ✅ Proper parameter handling
def permitted_product_params
  params.require(:product).permit(Spree::PermittedAttributes.product_attributes)
end
```

## Customization & Extensions

### Decorators (Use Sparingly)

- Decorators should be a last resort - they make upgrades difficult
- Use `Module.prepend` pattern for decorators
- Name decorator files with `_decorator.rb` suffix

```ruby
# ✅ Proper decorator structure
module Spree
  module ProductDecorator
    def custom_method
      # Custom functionality
      name.upcase
    end
    
    def existing_method
      # Extend existing method
      result = super
      # Additional logic
      result
    end
  end

  Product.prepend(ProductDecorator)
end
```

## Testing

### Test Application

To run tests you need to create test app with `bundle exec rake test_app` in every gem directory (eg. admin, api, core, etc.)

This will create a dummy rails application and run migrations. If there's already a dummy app in the gem directory, you can skip this step.

### Test Structure

- Use RSpec for testing
- Create test app with `bundle exec rake test_app` in every gem directory (eg. admin, api, core, etc.)
- Place specs in appropriate directories matching app structure
- Use Spree's factory bot definitions
- For controller specs always add `render_views` to the test
- For controller spec authentication use `stub_authorization!`

```ruby
# ✅ Proper spec structure
require 'spec_helper'

RSpec.describe Spree::Product, type: :model do
  let(:product) { create(:product) }
  
  describe '#custom_method' do
    it 'returns expected result' do
      expect(product.custom_method).to eq('EXPECTED')
    end
  end
end
```

### Factory Usage

- Use `create` for persisted objects in tests
- Use `build` for non-persisted objects, recommended as it's much faster than `create`
- Add new factories in `lib/spree/testing_support/factories/`

```ruby
# ✅ Proper factory usage
let(:product) { create(:product, name: 'Test Product') }
let(:variant) { build(:variant, product: product) }
```

## Security

### Authentication & Authorization

- Follow Rails Security Guide principles
- Use strong parameters consistently
- Implement proper authorization checks
- Validate all user inputs
- In Admin controllers inheriting from `Spree::Admin::ResourceController` will automatically secure all actions
- We use CanCanCan for authorization
- Authentication is handled by app developers, by default we provide Devise installer

### Parameter Security

- Never permit mass assignment without validation
- Use allowlists, not blocklists for parameters
- Sanitize user inputs appropriately

## Database & Migrations

### Migration Patterns

- Follow Rails migration conventions
- Use proper indexing for performance
- Do not include foreign key constraints
- Use descriptive migration names with timestamps
- Try to limit number of migrations to 1 per feature
- Avoid using default values in migrations
- Always add `null: false` to required columns
- Add unique indexes to columns that are used for uniqueness validation
- By default add `deleted_at` column to all tables that have soft delete functionality (we use `paranoia` gem)

```ruby
# ✅ Proper migration structure
class CreateSpreeMetafields < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_metafields do |t|
      t.string :key, null: false
      t.text :value, null: false
      t.string :kind, null: false
      t.string :visibility, null: false
      t.references :owner, polymorphic: true, null: false
      t.timestamps
    end
    
    add_index :spree_metafields, [:owner_type, :owner_id, :key, :visibility], 
              name: 'index_spree_metafields_on_owner_and_key_and_visibility'
  end
end
```

### Database Design

- Use appropriate column types and constraints
- Implement proper foreign key relationships
- Consider indexing for query performance
- Use polymorphic associations when appropriate

## Frontend Development

### Storefront Development

- Use Tailwind CSS for styling
- Follow responsive design principles
- Implement proper SEO meta tags
- Ensure accessibility compliance

### Admin Interface

- Use Spree's admin styling conventions
- Use as much as possible Turbo Rails features (Hotwire)
- Re-usable components should be helpers
- Please use `Spree::Admin::FormBuilder` methods for form fields
- Follow UX patterns established in core admin
- Use Stimulus controllers for JavaScript interactions

For create new resource form:

```erb
<!-- ✅ Proper admin form structure -->
<%= render 'spree/admin/shared/new_resource' %>
```

For edit resource form:

```erb
<%= render 'spree/admin/shared/edit_resource' %>
```

And the re-usable form partial should be in `app/views/spree/admin/products/_form.html.erb`, eg.

```erb
<div class="card mb-4">
  <div class="card-header">
    <h5 class="card-title">
      <%= Spree.t(:general_settings) %>
    </h5>
  </div>

  <div class="card-body">
    <%= f.spree_text_field :name %>
    <%= f.spree_rich_text_area :description %>
    <%= f.spree_check_box :active %>
  </div>
</div>
```

## Performance & Best Practices

### Query Optimization

- Use includes/preload to avoid N+1 queries
- Implement proper database indexing
- Use scopes for reusable query logic
- Consider caching for expensive operations

```ruby
# ✅ Optimized queries
products = Spree::Product.includes(:variants, :images)
                         .where(available_on: ..Time.current)
                         .order(:name)
```

### Caching

- Use Rails caching mechanisms appropriately
- Cache expensive calculations and queries
- Implement cache invalidation strategies
- Consider fragment caching for views

### Code Quality

- Follow Ruby style guidelines
- Keep methods small and focused
- Use meaningful variable and method names
- Write self-documenting code with appropriate comments
- Avoid deep nesting and complex conditionals

## Documentation & Comments

### Code Documentation

- Document complex business logic
- Explain non-obvious code patterns
- Use YARD documentation format for public APIs
- Keep comments up-to-date with code changes

## Error Handling

### Exception Management

- Use Rails error reporter - https://guides.rubyonrails.org/error_reporting.html
- Use appropriate exception classes
- Provide meaningful error messages
- Implement proper error recovery where possible

```ruby
# ✅ Proper error handling
def process_payment
  payment_service.call
rescue Spree::PaymentProcessingError => e
  Rails.error.report e
  flash[:error] = I18n.t('spree.payment_processing_failed')
  false
end
```

This document should be updated as Spree evolves and new patterns emerge. Always refer to the official Spree documentation for the most current practices and guidelines.

## Internationalization

- Use Rails 18n for internationalization
- Use `Spree.t` for translations
- Please keep admin translations in `admin/config/locales/en.yml`
- Please keep storefront translations in `storefront/config/locales/en.yml`
- Please keep all other translations in `config/locales/en.yml`
- Please do not repeat translations in multiple files, use `Spree.t` instead
- Please try to use existing translations as much as possible

# Essential Development Commands

## Running the Application

```bash
# Start development server with all services (Rails, Sidekiq, CSS watchers)
bin/dev

# Start individual services
bin/rails server -p 3000           # Rails server only
bundle exec sidekiq                # Background jobs worker
bin/rails dartsass:watch           # Admin CSS compilation watcher
bin/rails tailwindcss:watch        # Storefront CSS compilation watcher
```

## Testing Commands

```bash
# Run full test suite
bundle exec rspec

# Run specific test files or directories
bundle exec rspec spec/models/spree/product_spec.rb
bundle exec rspec spec/features/
bundle exec rspec spec/requests/spree/api/

# Run tests with documentation format (useful for debugging)
bundle exec rspec -f documentation

# Run single test example
bundle exec rspec spec/models/spree/product_spec.rb:15
```

## Code Quality & Linting

```bash
# Run RuboCop linting
bin/rubocop

# Auto-correct RuboCop violations
bin/rubocop -A

# Run RuboCop on specific files
bin/rubocop app/models/spree/product.rb

# Run Brakeman security analysis
bin/brakeman
```

## Database Operations

```bash
# Standard Rails database commands
bin/rails db:create
bin/rails db:migrate
bin/rails db:rollback
bin/rails db:seed

# Spree-specific sample data
bin/rails spree_sample:load

# Database console
bin/rails db:console
```

# Key Dependencies & Integrations

This Spree Starter application includes the following key dependencies:

## Core Stack
- **Ruby 3.3.0** with **Rails 8.0**
- **PostgreSQL** as primary database
- **Redis** for caching and background job storage
- **Sidekiq** for background job processing

## Spree Commerce Gems
- `spree` (~> 5.1) - Core e-commerce functionality
- `spree_admin` - Admin dashboard interface
- `spree_storefront` - Customer-facing storefront
- `spree_emails` - Email templates and delivery
- `spree_sample` - Sample data for development
- `spree_i18n` - Internationalization support

## Payment & Analytics
- `spree_stripe` - Stripe payment gateway integration
- `spree_paypal_checkout` - PayPal payment integration
- `spree_google_analytics` - Google Analytics 4 tracking
- `spree_klaviyo` - Klaviyo email marketing integration

## Authentication & Security
- `devise` - User authentication system
- `brakeman` - Static security analysis

## Frontend & Asset Pipeline
- `turbo-rails` + `stimulus-rails` - Hotwire for SPA-like experience
- `tailwindcss-rails` - Utility-first CSS framework (storefront)
- `dartsass-rails` - Sass compilation (admin interface)
- `importmap-rails` - JavaScript module management

## Development & Monitoring
- `sentry-ruby` + `sentry-rails` + `sentry-sidekiq` - Error monitoring
- `pry` - Enhanced debugging console
- `letter_opener` - Email preview in development
- `solargraph` + `ruby-lsp` - Language server support

# Deployment & Infrastructure

## Supported Platforms
This application is pre-configured for multiple deployment platforms:

### Render.com (Primary)
- Configuration: `render.yaml`
- Includes web service, worker service, and PostgreSQL database
- Automatic builds from Git commits

### Heroku
- Configuration: `app.json`, `Procfile`
- Supports web dynos and worker dynos
- Add-on support for PostgreSQL and Redis

### Docker
- `Dockerfile` for containerized deployments
- `docker-compose.yaml` for local development with services
- Multi-stage build for optimized production images

### Self-hosted/VPS
- `bin/setup` script for initial setup
- Systemd service files can be generated for production

## CI/CD
- **CircleCI** configuration in `.circleci/config.yml`
- Automated testing and security scanning
- Build and deployment pipelines

# Project-Specific Architecture

## Application Structure
```
SpreeStarter::Application
├── Spree Engine (mounted at root /)
├── Sidekiq Web UI (/sidekiq)
├── Rails Health Check (/up)
└── Custom application code in app/ directory
```

## Key Configuration Files
- `config/application.rb` - Auto-loads decorators, configures YAML classes
- `config/routes.rb` - Mounts Spree engines, configures Devise routes
- `Procfile.dev` - Multi-service development setup

## Authentication Flow
- **Storefront**: Devise-based user authentication with Spree controllers
- **Admin**: Separate admin user authentication system
- **Locale Support**: URL-based locale switching (`/:locale/path`)

## Background Jobs
- **Sidekiq** processes jobs from Redis queues
- Web UI available at `/sidekiq` in development
- Jobs should be placed in `app/jobs/` directory

## Asset Compilation
- **Admin Interface**: Dart Sass compilation (`bin/rails dartsass:watch`)
- **Storefront**: Tailwind CSS compilation (`bin/rails tailwindcss:watch`)
- **JavaScript**: Import maps for modern ES modules

## Development Workflow
1. Use `bin/dev` to start all services simultaneously
2. Access storefront at `http://localhost:3000`
3. Access admin at `http://localhost:3000/admin`
4. Monitor background jobs at `http://localhost:3000/sidekiq`
5. Run tests with `bundle exec rspec`
6. Lint code with `bin/rubocop`

## Testing Environment
- RSpec with `spree_dev_tools` integration
- Factory Bot for test data generation
- Feature specs use Capybara for integration testing
- API specs test JSON endpoints
- Request specs test controller behavior

# Documentation & Support Resources

## Official Spree Documentation
- **Primary Documentation**: https://spreecommerce.org/docs/developer/getting-started/quickstart
- **Developer Guides**: Complete guides for customization, deployment, and development
- **API Documentation**: REST API endpoints and usage examples
- **Migration Guides**: Upgrading between Spree versions

## Knowledge Base Search
- **Context7 MCP Integration**: https://context7.com/spree/spree
- Use this for searching the Spree knowledge base when you need specific answers
- Covers common issues, best practices, and implementation patterns
- Updated with community contributions and official solutions

Always refer to the official documentation first, then use the Context7 search for specific implementation questions or troubleshooting.

# Email Configuration

## SMTP Setup
The application is configured to use SMTP for email delivery in production. Configure using environment variables:

### Required Environment Variables
```bash
SMTP_ADDRESS=smtp.your-provider.com
SMTP_USERNAME=your-smtp-username  
SMTP_PASSWORD=your-smtp-password
```

### Optional Environment Variables (with defaults)
```bash
SMTP_PORT=587                          # Default: 587
SMTP_DOMAIN=yourdomain.com            # Default: app host
SMTP_AUTHENTICATION=plain             # Default: plain
SMTP_ENABLE_STARTTLS_AUTO=true        # Default: true
SMTP_OPENSSL_VERIFY_MODE=peer         # Default: peer

# Mailer URL configuration
MAILER_DEFAULT_HOST=yourdomain.com    # Default: localhost
MAILER_DEFAULT_PROTOCOL=https         # Default: https
```

### Popular SMTP Providers
See `.env.example` file for configuration examples for:
- Gmail (smtp.gmail.com)
- Outlook (smtp-mail.outlook.com) 
- AWS SES (email-smtp.region.amazonaws.com)
- Mailgun (smtp.mailgun.org)

### Railway.app Deployment
Set these environment variables in your Railway project dashboard under the Variables tab.

### Development Email
Development uses Letter Opener - emails open in browser instead of being sent.
