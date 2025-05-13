require 'spec_helper'
require 'webmock/rspec' # 用于 stub HTTP 请求

RSpec.describe Agora::CloudRecording::Client do
  let(:app_id) { 'test_app_id' } # 替换为虚拟 App ID
  let(:customer_key) { 'test_customer_key' }
  let(:customer_secret) { 'test_customer_cert' }
  let(:base_url) { 'https://api.agora.io' } # 假设的基础 URL
  let(:oss_vendor) { 1 } # 假设 OSS 类型 (e.g., 1 for Alibaba)
  let(:oss_region) { 'cn-hangzhou' }
  let(:oss_bucket) { 'my-bucket' }
  let(:oss_access_key) { 'my_access_key' }
  let(:oss_secret_key) { 'my_secret_key' }
  let(:oss_prefix) { ['recordings'] }

  let(:cname) { 'test-channel' }
  let(:uid) { '12345' }
  let(:resource_id) { 'test_resource_id' }
  let(:sid) { 'test_sid' }
  let(:token) { 'dummy_rtc_token' }
  let(:mode) { 'mix' }

  let(:agora_config) do
    instance_double(Agora::Config,
                    app_id: app_id,
                    customer_key: customer_key,
                    customer_secret: customer_secret,
                    base_url: base_url,
                    oss_vendor: oss_vendor,
                    oss_region: oss_region,
                    oss_bucket: oss_bucket,
                    oss_access_key: oss_access_key,
                    oss_secret_key: oss_secret_key,
                    oss_filename_prefix: oss_prefix)
  end

  # 在测试开始前配置 Agora
  before do
    allow(Agora).to receive(:config).and_return(agora_config)
    WebMock.disable_net_connect! # 禁用实际的网络连接
  end

  # 清理 WebMock
  after do
    WebMock.allow_net_connect!
  end

  subject(:client) { described_class.new } # 创建 client 实例

  describe '#initialize' do
    it 'initializes with valid config' do
      expect { client }.not_to raise_error
      expect(client.app_id).to eq(app_id)
      expect(client.customer_key).to eq(customer_key)
      # ... 可以添加更多属性检查
    end

    it 'raises error if config is incomplete' do
      allow(agora_config).to receive(:app_id).and_return(nil)
      expect { described_class.new }.to raise_error(Agora::Errors::ConfigurationError, /App ID.+必须配置/)
    end

    it 'raises error if OSS config is incomplete' do
      allow(agora_config).to receive(:oss_bucket).and_return(nil)
      expect { described_class.new }.to raise_error(Agora::Errors::ConfigurationError, /Bucket.+必须配置/)
    end
  end

  describe '#acquire' do
    let(:acquire_path) { "#{base_url}/v1/apps/#{app_id}/cloud_recording/acquire" }
    let(:success_response) { { 'resourceId' => resource_id }.to_json }

    it 'sends acquire request and returns resource ID' do
      stub_request(:post, acquire_path)
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: success_response, headers: { 'Content-Type' => 'application/json' })

      response = client.acquire(cname, uid)
      expect(response['resourceId']).to eq(resource_id)
    end

    it 'raises APIError on failure' do
      stub_request(:post, acquire_path)
        .to_return(status: 400, body: { reason: 'Bad Request' }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect { client.acquire(cname, uid) }.to raise_error(Agora::Errors::APIError, /声网 API 错误: 400/)
    end
  end

  describe '#start' do
    let(:start_path) { "#{base_url}/v1/apps/#{app_id}/cloud_recording/resourceid/#{resource_id}/mode/#{mode}/start" }
    let(:success_response) { { 'sid' => sid }.to_json }

    it 'sends start request and returns SID' do
      stub_request(:post, start_path)
        .to_return(status: 200, body: success_response, headers: { 'Content-Type' => 'application/json' })

      response = client.start(resource_id, cname, uid, token, mode)
      expect(response['sid']).to eq(sid)
    end
  end

  describe '#query' do
    let(:query_path) { "#{base_url}/v1/apps/#{app_id}/cloud_recording/resourceid/#{resource_id}/sid/#{sid}/mode/#{mode}/query" }
    let(:success_response) { { 'serverResponse' => { 'status' => 5 } }.to_json } # 5: Recording has stopped

    it 'sends query request and returns status' do
      stub_request(:get, query_path)
        .to_return(status: 200, body: success_response, headers: { 'Content-Type' => 'application/json' })

      response = client.query(resource_id, sid, mode)
      expect(response['serverResponse']['status']).to eq(5)
    end
  end

  describe '#stop' do
    let(:stop_path) { "#{base_url}/v1/apps/#{app_id}/cloud_recording/resourceid/#{resource_id}/sid/#{sid}/mode/#{mode}/stop" }
    let(:success_response) { { 'serverResponse' => { 'fileListMode' => 'string', 'fileList' => 'file_list_details.json' } }.to_json }

    it 'sends stop request and returns file list info' do
      stub_request(:post, stop_path)
        .to_return(status: 200, body: success_response, headers: { 'Content-Type' => 'application/json' })

      response = client.stop(resource_id, sid, cname, uid, mode)
      expect(response['serverResponse']['fileList']).to eq('file_list_details.json')
    end
  end

end