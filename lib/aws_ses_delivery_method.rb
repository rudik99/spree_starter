require 'aws-sdk-sesv2'

class AwsSesDeliveryMethod
  attr_accessor :settings

  def initialize(settings = {})
    @settings = settings
  end

  def deliver!(mail)
    ses_client = Aws::SESV2::Client.new(
      region: settings[:region] || 'ap-southeast-2',
      access_key_id: settings[:access_key_id],
      secret_access_key: settings[:secret_access_key]
    )

    # Prepare email content
    destination = {
      to_addresses: Array(mail.to),
      cc_addresses: Array(mail.cc || []),
      bcc_addresses: Array(mail.bcc || [])
    }

    content = {
      simple: {
        subject: {
          data: mail.subject.to_s,
          charset: 'UTF-8'
        },
        body: {}
      }
    }

    # Handle both text and HTML parts
    if mail.multipart?
      mail.parts.each do |part|
        case part.content_type
        when /text\/plain/
          content[:simple][:body][:text] = {
            data: part.body.decoded,
            charset: 'UTF-8'
          }
        when /text\/html/
          content[:simple][:body][:html] = {
            data: part.body.decoded,
            charset: 'UTF-8'
          }
        end
      end
    else
      # Single part email
      if mail.content_type =~ /text\/html/
        content[:simple][:body][:html] = {
          data: mail.body.decoded,
          charset: 'UTF-8'
        }
      else
        content[:simple][:body][:text] = {
          data: mail.body.decoded,
          charset: 'UTF-8'
        }
      end
    end

    # Send email
    ses_client.send_email({
      from_email_address: mail.from.first,
      destination: destination,
      content: content
    })

    Rails.logger.info "Email sent successfully via AWS SES API to: #{mail.to.join(', ')}"
  rescue => e
    Rails.logger.error "Failed to send email via AWS SES API: #{e.message}"
    raise
  end
end