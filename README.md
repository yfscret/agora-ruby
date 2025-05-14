# 声网（Agora）Ruby 客户端

[![Gem Version](https://badge.fury.io/rb/agora-ruby.svg)](https://badge.fury.io/rb/agora-ruby) <!-- 发布后可更新 -->

本 Ruby gem 提供了对接声网 Agora RESTful API 的客户端，当前聚焦于云端录制功能。它简化了录制任务的发起、停止、查询，以及录制文件上传到第三方云存储平台（如阿里云 OSS、Amazon S3 等）的流程。

## 安装

在你的 Gemfile 中添加：

```ruby
gem 'agora-ruby'
```

然后执行：

```bash
$ bundle install
```

或者直接安装：

```bash
$ gem install agora-ruby
```

## 配置

在使用本 gem 前，你需要配置声网和第三方云存储的相关参数。推荐在 Rails 项目中放在 `config/initializers/agora.rb`，普通 Ruby 项目可在初始化阶段配置：

```ruby
Agora.configure do |config|
  # 声网相关配置（必填）
  config.app_id = '你的声网 App ID'
  config.customer_key = '你的声网 RESTFUL API 客户 ID'
  config.customer_secret = '你的声网 RESTFUL API 客户密钥'

  # 第三方云存储平台配置（必填，vendor 需根据实际平台填写）
  # 支持的 vendor 及编号如下：
  # 1：Amazon S3
  # 2：阿里云 OSS
  # 3：腾讯云 COS
  # 5：Microsoft Azure
  # 6：谷歌云 GCS
  # 7：华为云 OBS
  # 8：百度智能云 BOS
  config.oss_vendor = 2 # 2 表示阿里云 OSS
  config.oss_region = 1 # 区域编号，具体见官方文档 https://doc.shengwang.cn/doc/cloud-recording/restful/api/reference
  config.oss_bucket = '你的云存储 bucket 名称'
  config.oss_access_key = '你的云存储 Access Key'
  config.oss_secret_key = '你的云存储 Secret Key'
  config.oss_filename_prefix = ["directory1","directory2"] # 录制文件在第三方云存储中的存储位置, directory1/directory2/xxx.m3u8
end
```

**安全提示：** 强烈建议通过环境变量或 Rails credentials 等安全方式管理密钥，不要将密钥明文写入代码。

## 使用方法

配置完成后，可通过 `Agora::CloudRecording::Client` 管理云端录制。

### 典型场景：直播连线录制

假设你在直播间（频道名：`"live-chat-123"`）与用户连线，需要录制用户的视频、用户音频和你的音频，录制文件自动上传到阿里云 OSS。

```ruby
# 确保已完成上述配置
begin
  client = Agora::CloudRecording::Client.new
  cname = "live-chat-123"
  my_uid = "1888"       # 你的 UID
  recording_bot_uid = "#{my_uid}#{rand(1000)}" # 录制机器人 UID，需唯一
  record_uid = "110560" # 需要录制的用户 UID

  # 1. 获取录制资源 resourceId
  # acquire 的 clientRequest 可为空，除非有特殊需求
  puts "获取录制资源..."
  acquire_response = client.acquire(cname, recording_bot_uid)
  resource_id = acquire_response["resourceId"]
  puts "resourceId: #{resource_id}"

  # 2. 获取 token
  # 你需要为 recording_bot_uid 生成一个有效的声网 Token（可用你自己的 Token 服务）
  app_id = 'xxxxxxx'
  app_certificate = 'xxxxxxxx'
  token_expiration_in_seconds = 3600
  privilege_expiration_in_seconds = 3600
  token = Agora::AgoraDynamicKey2::RtcTokenBuilder.build_token_with_uid(
    app_id, app_certificate, cname, recording_bot_uid,
    Agora::AgoraDynamicKey2::RtcTokenBuilder::ROLE_PUBLISHER,
    token_expiration_in_seconds, privilege_expiration_in_seconds
  )

  # 3. 启动录制
  recording_config = {
    streamTypes: 2,  # 录制音视频
    channelType: 1,  # 直播模式
    audioProfile: 2, # 音频质量, 音频编码，双声道，编码码率约 192 Kbps。
    # 只录制指定用户的视频，和你与用户的音频
    subscribeVideoUids: [record_uid],
    subscribeAudioUids: [my_uid, record_uid],
    transcodingConfig: {
      width: 720,
      height: 1280,
      bitrate: 3420,
      fps: 30
    }
  }

  recording_file_config = {
    avFileType: %w[hls mp4] # 同时录制 HLS 和 MP4
  }

  puts "启动录制..."
  start_response = client.start(
    resource_id,
    cname,
    recording_bot_uid,
    token,
    'mix', # 合流录制，若需单流录制可用 'individual'
    recording_config,
    recording_file_config
  )
  sid = start_response["sid"] # 录制会话 ID
  puts "录制已启动，SID: #{sid}"

  # 录制中（实际业务中可根据需求控制时长）
  puts "录制中..."

  # 4. 可选：查询录制状态
  puts "查询录制状态..."
  query_response = client.query(resource_id, sid)
  puts "状态查询结果: #{query_response}"
  # 可根据 query_response["serverResponse"]["status"] 判断录制状态

  # 5. 停止录制
  puts "停止录制..."
  stop_response = client.stop(resource_id, sid, cname, recording_bot_uid, 'mix', { async_stop: true })
  puts "停止结果: #{stop_response}"
  # 文件上传 OSS 可能有延迟，可通过 stop_response["serverResponse"]["fileList"] 获取文件列表

  puts "录制流程结束，请到 OSS 查看文件: #{Agora.config.oss_bucket}/#{stop_response["serverResponse"]["fileList"][0]['fileName']}"

rescue Agora::Errors::ConfigurationError => e
  puts "配置错误: #{e.message}"
rescue Agora::Errors::APIError => e
  puts "API 错误: #{e.message}"
  puts "响应码: #{e.response&.code}"
  puts "响应体: #{e.response&.body}"
rescue StandardError => e
  puts "发生未知错误: #{e.message}"
  puts e.backtrace.join("\n")
end
```

### API 方法说明

`Agora::CloudRecording::Client` 提供如下方法：

*   `acquire(cname, uid, client_request = {})`：获取录制资源 resourceId。
*   `start(resource_id, cname, uid, token, mode = 'mix', recording_config = {}, recording_file_config = {}, storage_config = {})`：启动录制。
    *   `mode`：'mix'（合流，默认）或 'individual'（单流）。
    *   `recording_config`：录制参数（如 streamTypes、subscribeVideoUids、subscribeAudioUids、transcodingConfig 等，详见官方文档）。
    *   `recording_file_config`：输出文件类型（如 avFileType: ["hls", "mp4"]）。
    *   `storage_config`：云存储参数（如 fileNamePrefix，可覆盖默认值）。
*   `query(resource_id, sid, mode = 'mix')`：查询录制状态。
*   `stop(resource_id, sid, cname, uid, mode = 'mix', client_request = {})`：停止录制。

详细参数和更多高级用法请参考 [声网云端录制 RESTful API 文档](https://doc.shengwang.cn/doc/cloud-recording/restful/cloud-recording/operations/post-v1-apps-appid-cloud_recording-acquire)。

## 开发与贡献

克隆本仓库后，运行 `bin/setup` 安装依赖。测试可用 `rake spec`（建议补充测试用例）。你也可以用 `bin/console` 进入交互式环境。

本地安装 gem 可用 `bundle exec rake install`。如需发布新版本，修改 `version.rb` 后执行 `bundle exec rake release`，会自动打 tag 并推送到 RubyGems（需先配置好发布信息）。

## 贡献

欢迎通过 Pull Request 或 Issue 反馈和贡献代码，详见 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)。

## 许可证

本项目基于 [MIT License](https://opensource.org/licenses/MIT) 开源。

## 行为准则

所有参与本项目的人都需遵守 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)。
