require "httparty"
require_relative "agora/version"
require_relative "agora/config"
require_relative "agora/errors"
require_relative "agora/cloud_recording/client"

module Agora
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Agora::Config.new # 使用 Agora::Config 类
    yield(config) if block_given?
  end

  class Configuration
    attr_accessor :app_id, :customer_id, :customer_certificate, :oss_vendor, :oss_region, :oss_bucket, :oss_access_key, :oss_secret_key

    def initialize
      # oss_vendor 不再设置默认值，需在配置文件中指定
    end
  end
end