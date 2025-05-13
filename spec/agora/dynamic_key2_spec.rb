require 'spec_helper'

RSpec.describe Agora::AgoraDynamicKey2 do
  let(:app_id) { '970ca35de60c44645bbae8a215061b33' } # 虚拟 App ID, 32 chars
  let(:app_certificate) { '5cfd2fd1755d40ecb72977518be15d3b' } # 虚拟证书, 32 chars
  let(:channel_name) { 'testChannelV2' }
  let(:user_id_int) { 123 }
  let(:user_account_str) { "user_account_v2" }
  let(:rtm_user_id) { "rtm_user_v2" }
  let(:chat_user_id) { "chat_user_v2" }
  let(:room_uuid) { "room_uuid_v2" }
  let(:user_uuid) { "user_uuid_v2" }
  let(:token_expire) { 3600 }
  let(:privilege_expire) { 3600 }
  let(:chat_privilege_expire) { 3600 }
  let(:education_role) { 1 } # 示例角色

  # 辅助方法检查 Token V2 (以 '007' 开头)
  def expect_valid_v2_token(token)
    expect(token).to be_a(String)
    expect(token).not_to be_empty
    expect(token).to start_with('007')
  end

  describe Agora::AgoraDynamicKey2::RtcTokenBuilder do
    it 'builds RTC token with UID' do
      token = Agora::AgoraDynamicKey2::RtcTokenBuilder.build_token_with_uid(
        app_id, app_certificate, channel_name, user_id_int,
        Agora::AgoraDynamicKey2::RtcTokenBuilder::ROLE_PUBLISHER,
        token_expire, privilege_expire
      )
      expect_valid_v2_token(token)
    end

    it 'builds RTC token with user account' do
      token = Agora::AgoraDynamicKey2::RtcTokenBuilder.build_token_with_user_account(
        app_id, app_certificate, channel_name, user_account_str,
        Agora::AgoraDynamicKey2::RtcTokenBuilder::ROLE_SUBSCRIBER,
        token_expire, privilege_expire
      )
      expect_valid_v2_token(token)
    end

    it 'builds RTC token with specific privileges' do
      token = Agora::AgoraDynamicKey2::RtcTokenBuilder.build_token_with_uid_and_privilege(
        app_id, app_certificate, channel_name, user_id_int, token_expire,
        privilege_expire, privilege_expire, privilege_expire, privilege_expire
      )
      expect_valid_v2_token(token)
    end
  end

  describe Agora::AgoraDynamicKey2::RtmTokenBuilder do
    it 'builds RTM token' do
      token = Agora::AgoraDynamicKey2::RtmTokenBuilder.build_token(
        app_id, app_certificate, rtm_user_id, token_expire
      )
      expect_valid_v2_token(token)
    end
  end

  describe Agora::AgoraDynamicKey2::FpaTokenBuilder do
    it 'builds FPA token' do
      # FPA token expire is fixed at 24 hours internally in the builder
      token = Agora::AgoraDynamicKey2::FpaTokenBuilder.build_token(app_id, app_certificate)
      expect_valid_v2_token(token)
    end
  end

  describe Agora::AgoraDynamicKey2::ChatTokenBuilder do
    it 'builds Chat user token' do
      token = Agora::AgoraDynamicKey2::ChatTokenBuilder.build_user_token(
        app_id, app_certificate, chat_user_id, chat_privilege_expire
      )
      expect_valid_v2_token(token)
    end

    it 'builds Chat app token' do
      token = Agora::AgoraDynamicKey2::ChatTokenBuilder.build_app_token(
        app_id, app_certificate, chat_privilege_expire
      )
      expect_valid_v2_token(token)
    end
  end

  # APaaS 和 Education Token Builder 的代码是相同的，测试 APaaS 即可覆盖
  describe Agora::AgoraDynamicKey2::ApaasTokenBuilder do
    it 'builds APaaS (Education) room user token' do
      token = Agora::AgoraDynamicKey2::ApaasTokenBuilder.build_room_user_token(
        app_id, app_certificate, room_uuid, user_uuid, education_role, token_expire
      )
      expect_valid_v2_token(token)
    end

    it 'builds APaaS (Education) user token' do
      token = Agora::AgoraDynamicKey2::ApaasTokenBuilder.build_user_token(
        app_id, app_certificate, user_uuid, token_expire
      )
      expect_valid_v2_token(token)
    end

    it 'builds APaaS (Education) app token' do
      token = Agora::AgoraDynamicKey2::ApaasTokenBuilder.build_app_token(
        app_id, app_certificate, token_expire
      )
      expect_valid_v2_token(token)
    end
  end
end