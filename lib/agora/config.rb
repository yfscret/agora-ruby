module Agora
  class Config
    attr_accessor :app_id, :customer_key, :customer_secret,
                  :oss_vendor, :oss_region, :oss_bucket,
                  :oss_access_key, :oss_secret_key,
                  :base_url, :oss_filename_prefix

    def initialize
      @base_url = 'https://api.sd-rtn.com'
    end
  end
end