require "httparty"
require_relative "agora/version"
require_relative "agora/config"
require_relative "agora/errors"
require_relative "agora/cloud_recording/client"
require_relative "agora/dynamic_key"
require_relative "agora/dynamic_key2"

module Agora
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Agora::Config.new # 使用 Agora::Config 类
    yield(config) if block_given?
  end
end