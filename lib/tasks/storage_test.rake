namespace :storage do
  desc "Test Active Storage configuration and R2 connectivity"
  task test: :environment do
    puts "=== Active Storage Configuration Test ==="
    puts "Environment: #{Rails.env}"
    puts "Active Storage Service: #{Rails.application.config.active_storage.service}"
    
    # Check environment variables
    puts "\n=== Environment Variables ==="
    r2_vars = %w[CLOUDFLARE_ENDPOINT CLOUDFLARE_ACCESS_KEY_ID CLOUDFLARE_SECRET_ACCESS_KEY CLOUDFLARE_BUCKET]
    r2_vars.each do |var|
      value = ENV[var]
      if value.present?
        puts "#{var}: #{value.length > 20 ? value[0..20] + '...' : value}"
      else
        puts "#{var}: NOT SET"
      end
    end
    
    # Test storage service
    puts "\n=== Storage Service Test ==="
    begin
      service = ActiveStorage::Blob.service
      puts "Active service class: #{service.class.name}"
      
      if service.is_a?(ActiveStorage::Service::S3Service)
        puts "S3 Service detected - R2 should work"
        puts "Bucket: #{service.bucket.name}"
        puts "Region: #{service.client.config.region}"
        
        # Test basic connectivity
        puts "\n=== Testing R2 Connectivity ==="
        test_key = "test/connectivity_test_#{Time.current.to_i}.txt"
        test_content = "Hello from Rails at #{Time.current}"
        
        service.upload(test_key, StringIO.new(test_content), checksum: Digest::MD5.base64digest(test_content))
        puts "✅ Upload test successful"
        
        downloaded = service.download(test_key)
        puts "✅ Download test successful: #{downloaded}"
        
        service.delete(test_key)
        puts "✅ Delete test successful"
        
      elsif service.is_a?(ActiveStorage::Service::DiskService)
        puts "Disk Service detected - using local storage"
        puts "Root path: #{service.root}"
      else
        puts "Unknown service: #{service.class.name}"
      end
      
    rescue => e
      puts "❌ Error testing storage: #{e.class.name}: #{e.message}"
      puts e.backtrace.first(3).join("\n")
    end
    
    puts "\n=== Test Complete ==="
  end
end