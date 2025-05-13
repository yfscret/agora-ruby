require 'spec_helper'

RSpec.describe Agora::AgoraDynamicKey do
  let(:app_id) { '970ca35de60c44645bbae8a215061b33' } # 替换为虚拟 App ID
  let(:app_certificate) { '5cfd2fd1755d40ecb72977518be15d3b' } # 替换为虚拟证书
  let(:channel_name) { 'testChannel' }
  let(:user_id_int) { 123456789 }
  let(:user_account_str) { "test_user_account" }
  let(:expire_time_in_seconds) { 3600 }
  let(:current_timestamp) { Time.now.to_i }
  let(:expire_timestamp) { current_timestamp + expire_time_in_seconds }

  describe Agora::AgoraDynamicKey::RTCTokenBuilder do
    it 'builds RTC token with UID' do
      payload = {
        app_id: app_id,
        app_certificate: app_certificate,
        channel_name: channel_name,
        uid: user_id_int,
        role: Agora::AgoraDynamicKey::RTCTokenBuilder::Role::PUBLISHER,
        privilege_expired_ts: expire_timestamp
      }
      token = Agora::AgoraDynamicKey::RTCTokenBuilder.build_token_with_uid(payload)
      expect(token).to be_a(String)
      expect(token).not_to be_empty
      # 基础格式检查 (V1 Token 以 '006' 开头)
      expect(token).to start_with('006')
    end

    it 'builds RTC token with account (uses account as uid internally)' do
       payload = {
        app_id: app_id,
        app_certificate: app_certificate,
        channel_name: channel_name,
        account: user_account_str, # V1 使用 account 参数，内部转换为 uid
        role: Agora::AgoraDynamicKey::RTCTokenBuilder::Role::SUBSCRIBER,
        privilege_expired_ts: expire_timestamp
      }
      token = Agora::AgoraDynamicKey::RTCTokenBuilder.build_token_with_account(payload)
      expect(token).to be_a(String)
      expect(token).not_to be_empty
      expect(token).to start_with('006')
    end
  end

  describe Agora::AgoraDynamicKey::RTMTokenBuilder do
    it 'builds RTM token' do
      payload = {
        app_id: app_id,
        app_certificate: app_certificate,
        account: user_account_str,
        role: Agora::AgoraDynamicKey::RTMTokenBuilder::Role::RTM_USER, # RTM 只有一个角色
        privilege_expired_ts: expire_timestamp
      }
      token = Agora::AgoraDynamicKey::RTMTokenBuilder.build_token(payload)
      expect(token).to be_a(String)
      expect(token).not_to be_empty
      expect(token).to start_with('006')
    end
  end
end