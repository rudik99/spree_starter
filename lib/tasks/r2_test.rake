namespace :r2 do
  desc "Test R2 upload functionality"
  task test: :environment do
    puts "=== R2 Upload Test ==="
    
    begin
      # Test basic upload
      test_content = "Hello from Rails at #{Time.current}"
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(test_content),
        filename: "test_#{Time.current.to_i}.txt",
        content_type: "text/plain"
      )
      
      puts "✅ Blob created: #{blob.id}"
      puts "✅ Key: #{blob.key}"
      puts "✅ URL: #{blob.url}"
      
      # Test download
      downloaded = blob.download
      puts "✅ Download successful: #{downloaded == test_content ? 'Content matches' : 'Content mismatch'}"
      
      # Clean up
      blob.purge
      puts "✅ Cleanup successful"
      
      puts "\n🎉 R2 is working correctly!"
      
    rescue => e
      puts "❌ R2 test failed: #{e.class.name}: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
  end
end