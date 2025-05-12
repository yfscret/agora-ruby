module Agora
  class Config
    attr_accessor :app_id, :customer_id, :customer_certificate,
                  :oss_vendor, :oss_region, :oss_bucket,
                  :oss_access_key, :oss_secret_key,
                  :base_url

    def initialize
      @base_url = 'https://api.agora.io'
      # oss_vendor 不再设置默认值，需在配置文件中指定
      # 其他如 app_id, customer_id 等也由用户配置，此处不设默认值
    end
  end
end