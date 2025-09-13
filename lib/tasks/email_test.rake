namespace :email do
  desc "Test SMTP email configuration"
  task test: :environment do
    puts "Testing SMTP email configuration..."
    
    # Check if SMTP is configured
    if ENV['SMTP_ADDRESS'].blank?
      puts "❌ SMTP_ADDRESS environment variable is not set"
      puts "Please configure SMTP settings. See .env.example for details."
      exit 1
    end
    
    # Display current configuration (without passwords)
    puts "\n📧 Current SMTP Configuration:"
    puts "Address: #{ENV['SMTP_ADDRESS']}"
    puts "Port: #{ENV.fetch('SMTP_PORT', 587)}"
    puts "Username: #{ENV['SMTP_USERNAME']}"
    puts "Domain: #{ENV.fetch('SMTP_DOMAIN', 'not set')}"
    puts "Authentication: #{ENV.fetch('SMTP_AUTHENTICATION', 'plain')}"
    puts "STARTTLS: #{ENV.fetch('SMTP_ENABLE_STARTTLS_AUTO', 'true')}"
    
    # Check for admin user to send test email to
    admin_user = Spree.admin_user_class.first
    if admin_user.blank?
      puts "\n❌ No admin user found to send test email to"
      puts "Create an admin user first: bin/rails g spree:admin:user"
      exit 1
    end
    
    begin
      # Create a simple test mailer
      test_email = ActionMailer::Base.mail(
        to: admin_user.email,
        from: ENV.fetch('SMTP_USERNAME', 'noreply@example.com'),
        subject: "SMTP Test Email - #{Time.current.strftime('%Y-%m-%d %H:%M')}",
        body: <<~BODY
          This is a test email to verify your SMTP configuration is working correctly.
          
          Configuration used:
          - SMTP Server: #{ENV['SMTP_ADDRESS']}
          - Port: #{ENV.fetch('SMTP_PORT', 587)}
          - Authentication: #{ENV.fetch('SMTP_AUTHENTICATION', 'plain')}
          
          If you received this email, your SMTP setup is working correctly!
          
          Sent from: #{Rails.application.class.module_parent_name}
          Environment: #{Rails.env}
          Time: #{Time.current}
        BODY
      )
      
      puts "\n📤 Sending test email to: #{admin_user.email}"
      test_email.deliver_now
      puts "✅ Test email sent successfully!"
      puts "Check your inbox for the test message."
      
    rescue StandardError => e
      puts "\n❌ Failed to send test email:"
      puts "Error: #{e.message}"
      puts "\nCommon issues:"
      puts "- Check your SMTP credentials are correct"
      puts "- Verify the SMTP server address and port"
      puts "- Ensure your email provider allows SMTP access"
      puts "- Check if you need an app password (Gmail, Outlook)"
      exit 1
    end
  end
end