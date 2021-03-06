# frozen_string_literal: true

require "aws-sdk"

module FileUploader
  class S3
    attr_reader :file, :file_name

    def initialize(file:, file_name:, content_disposition: nil, bucket_name: nil)
      @file = file
      @file_name = file_name
      @bucket_name = bucket_name
      @content_disposition = content_disposition
    end

    def call
      object = resource.bucket(bucket_name).object(file_name)

      File.open(file.tempfile, "rb") do |file_body|
        options = { body: file_body }
        options[:content_disposition] = @content_disposition if @content_disposition.present?

        object.put(options)
      end

      object.public_url
    end

    private

    def resource
      Aws::S3::Resource.new(client: client)
    end

    def bucket_name
      @bucket_name ||= ENV.fetch("S3_BUCKET_NAME")
    end

    protected

    def client
      Aws::S3::Client.new(
        region: ENV.fetch("AWS_REGION"),
        access_key_id: ENV.fetch("AWS_ACCESS_KEY_ID"),
        secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY")
      )
    end
  end
end
