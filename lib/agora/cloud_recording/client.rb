require 'httparty'
require 'json'

module Agora
  module CloudRecording
    class Client
      include HTTParty
      # base_uri 通过 Agora.config.base_url 设置

      attr_reader :app_id, :customer_key, :customer_secret, :oss_vendor, :oss_region, :oss_bucket, :oss_access_key, :oss_secret_key, :oss_filename_prefix

      def initialize
        @config = Agora.config # 使用 Agora.config 获取配置实例
        unless @config && @config.app_id && @config.customer_key && @config.customer_secret
          raise Agora::Errors::ConfigurationError, "声网 App ID, Customer ID, 和 Customer Certificate 必须配置。"
        end
        unless @config.oss_bucket && @config.oss_access_key && @config.oss_secret_key && @config.oss_region && @config.oss_vendor
          raise Agora::Errors::ConfigurationError, "云存储的 Bucket, Access Key, Secret Key, Region, 和 Vendor 必须配置。"
        end

        self.class.base_uri @config.base_url # 设置 base_uri

        @app_id = @config.app_id
        @customer_key = @config.customer_key
        @customer_secret = @config.customer_secret
        @oss_vendor = @config.oss_vendor
        @oss_region = @config.oss_region
        @oss_bucket = @config.oss_bucket
        @oss_access_key = @config.oss_access_key
        @oss_secret_key = @config.oss_secret_key
        @oss_filename_prefix = @config.oss_filename_prefix
      end

      def acquire(cname, uid, client_request = {})
        path = "/v1/apps/#{@app_id}/cloud_recording/acquire"
        body = {
          cname: cname,
          uid: uid,
          clientRequest: client_request
        }.to_json

        headers = {
          'Authorization' => basic_auth_header,
          'Content-Type' => 'application/json'
        }
        # 注意：HTTParty 的 post/get 方法是类方法
        handle_response(self.class.post(path, body: body, headers: headers))
      end

      def start(resource_id, cname, uid, token, mode = 'mix', recording_config = {}, recording_file_config = {}, storage_config = {})
        path = "/v1/apps/#{@app_id}/cloud_recording/resourceid/#{resource_id}/mode/#{mode}/start"

        default_storage_config = {
          vendor: @oss_vendor,
          region: @oss_region,
          bucket: @oss_bucket,
          accessKey: @oss_access_key,
          secretKey: @oss_secret_key,
          fileNamePrefix: @oss_filename_prefix
        }

        body = {
          cname: cname,
          uid: uid,
          clientRequest: {
            token: token,
            recordingConfig: default_recording_config.merge(recording_config),
            recordingFileConfig: default_recording_file_config.merge(recording_file_config),
            storageConfig: default_storage_config.merge(storage_config)
          }
        }.to_json

        headers = {
          'Authorization' => basic_auth_header,
          'Content-Type' => 'application/json'
        }
        handle_response(self.class.post(path, body: body, headers: headers))
      end

      def query(resource_id, sid, mode = 'mix')
        path = "/v1/apps/#{@app_id}/cloud_recording/resourceid/#{resource_id}/sid/#{sid}/mode/#{mode}/query"
        headers = { 'Authorization' => basic_auth_header }
        handle_response(self.class.get(path, headers: headers))
      end

      def stop(resource_id, sid, cname, uid, mode = 'mix', client_request = {})
        path = "/v1/apps/#{@app_id}/cloud_recording/resourceid/#{resource_id}/sid/#{sid}/mode/#{mode}/stop"
        body = {
          cname: cname,
          uid: uid,
          clientRequest: client_request
        }.to_json

        headers = {
          'Authorization' => basic_auth_header,
          'Content-Type' => 'application/json'
        }
        handle_response(self.class.post(path, body: body, headers: headers))
      end

      private

      def basic_auth_header
        "Basic " + Base64.strict_encode64("#{@customer_key}:#{@customer_secret}")
      end

      def handle_response(response)
        if response.success?
          response.parsed_response
        else
          error_message = "声网 API 错误: #{response.code}"
          parsed_body = response.parsed_response
          if parsed_body.is_a?(Hash)
            reason = parsed_body['reason']
            message = parsed_body['message']
            error_message += " - 原因: #{reason}" if reason
            error_message += " - 信息: #{message}" if message && message != reason # 避免重复信息
          end
          raise Agora::Errors::APIError.new(error_message, response)
        end
      end

      def default_recording_config
        {
          maxIdleTime: 30,
          streamTypes: 2,
          channelType: 1,
        }
      end

      def default_recording_file_config
        {
          avFileType: ["hls", "mp4"]
        }
      end

    end
  end
end