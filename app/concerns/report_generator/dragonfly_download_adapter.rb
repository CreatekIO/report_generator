module ReportGenerator::DragonflyDownloadAdapter
  extend ActiveSupport::Concern
  require 'dragonfly'

  included do
    extend Dragonfly::Model

    dragonfly_accessor :file
  end

  def expiring_link(expires_in: ReportGenerator::Download::MAX_EXPIRY)
    # This mirrors the logic used by Fog to calculate the `X-Amz-Expires`
    # header, so that we always get a valid value.
    # See: https://github.com/fog/fog-aws/blob/v2.0.0/lib/fog/aws/storage.rb#L178-L185
    if expires_in == ReportGenerator::Download::MAX_EXPIRY
      now = defined?(Fog) ? Fog::Time.now : Time.now
      expires_at = now + ReportGenerator::Download::EXPIRY_OFFSET
      expires_at -= 60.seconds while (expires_at.to_i - now.to_i) > ReportGenerator::Download::MAX_EXPIRY
    else
      expires_at = expires_in.from_now
    end

    file.remote_url(expires: expires_at)
  end
end
