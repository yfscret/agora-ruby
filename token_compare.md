# 声网 AccessToken 与 AccessToken2 对比及使用指南

## 引言

声网 (Agora) 使用 Token (令牌) 机制对其服务进行用户身份验证和权限控制。随着技术的发展和安全需求的提升，声网推出了 AccessToken2（通过 `Agora::DynamicKey2` 模块提供），作为对其早期 Token 机制 (AccessToken V1，通过 `Agora::DynamicKey` 模块提供) 的升级。理解这两者之间的差异对于确保应用程序的安全性和功能的正常运行至关重要。本文档旨在详细比较 AccessToken V1 和 AccessToken2，并明确各自的使用场景。

**参考文档:**
*   [AccessToken 升级指南 (官方文档)](https://doc.shengwang.cn/doc/rtc/android/advanced-features/token-server-upgrade#%E5%8D%87%E7%BA%A7%E8%87%B3-accesstoken2)
*   [声网 Ruby Token 生成库 (GitHub)](https://github.com/AgoraIO/Tools/tree/master/DynamicKey/AgoraDynamicKey/ruby) - 请注意，本项目已将这两个版本的代码整合。

## 核心差异对比

| 特性             | AccessToken V1 (`Agora::DynamicKey`)                     | AccessToken2 (`Agora::DynamicKey2`)                                 | 说明与影响                                                                                                                                                                                                                                 |
| :--------------- | :------------------------------------------------------- | :---------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **核心模块/类**  | `Agora::DynamicKey::AccessToken`<br>`Agora::DynamicKey::RtcTokenBuilder`<br>`Agora::DynamicKey::RtmTokenBuilder` | `Agora::DynamicKey2::AccessToken`<br>`Agora::DynamicKey2::RtcTokenBuilder`<br>`Agora::DynamicKey2::RtmTokenBuilder`<br>以及 Chat, FPA, Education, APaaS Token Builder | 升级时需要修改服务端代码引用的模块和类名。V2 提供了更丰富的 Token 类型支持。                                                                                                                                                              |
| **生成方法 (RTC)** | `Agora::DynamicKey::RtcTokenBuilder.build_token_with_uid(...)` | `Agora::DynamicKey2::RtcTokenBuilder.build_token_with_uid(...)`<br>`Agora::DynamicKey2::RtcTokenBuilder.build_token_with_user_account(...)`<br>以及带特定权限设置的方法 | 升级时需修改调用的类名和确认方法签名。V2 增加了对 User Account 的直接支持和更细粒度的权限生成方法。                                                                                                                                                           |
| **有效期参数**   | `privilege_expired_ts` (Integer, **绝对过期时间戳**, 秒) | `token_expire` (Integer, **相对时长**, 秒)<br>`privilege_expire` (Integer, **相对时长**, 秒) | **重大变化**: <br> - V1 使用 **绝对过期时间戳** (秒)。<br> - V2 使用两个 **相对有效期时长** (秒)：Token 本身的有效期和权限（如发流）的有效期。<br> - V2 提供了更灵活的控制，可以将 Token 的有效期和具体权限（如发布流）的有效期分开设置。                                     |
| **时间戳计算**   | 需要手动获取当前时间戳 (`Time.now.to_i`)，然后加上有效期时长得到 `privilege_expired_ts`。 | 直接传入 Token 和权限的**有效时长**（例如 3600 代表 1 小时）。库内部处理时间计算。                               | V2 的方式更简洁，减少了手动计算时间戳的步骤和潜在错误。                                                                                                                                                                                          |
| **用户角色 (RTC Role)** | 在 `Agora::DynamicKey::RtcTokenBuilder` 中定义常量：<br>`Role_Attendee = 0` (废弃)<br>`Role_Publisher = 1`<br>`Role_Subscriber = 2`<br>`Role_Admin = 101` (废弃) | `Agora::DynamicKey2::RtcTokenBuilder` 接受**数字参数**代表角色 (如 `1` 代表发布者, `2` 代表订阅者)。代码内定义了 `ROLE_PUBLISHER = 1`, `ROLE_SUBSCRIBER = 2` 可供使用。<br>旧的 `Attendee` 和 `Admin` 角色已废弃。 | V2 简化了角色定义，`ROLE_PUBLISHER` 拥有发布和订阅权限，`ROLE_SUBSCRIBER` 仅拥有订阅权限（需后台配置生效）。升级时需要使用 V2 的常量或数字，并移除对废弃角色的使用。                                                                            |
| **支持的服务类型** | 主要支持 RTC, RTM | 支持 RTC, RTM, **FPA, Chat (User/App), Education (RoomUser/User/App), APaaS (RoomUser/User/App)** | AccessToken2 极大地扩展了支持的声网服务范围，为不同场景提供专门的 Token 构建器。                                                                                                                                                           |
| **安全性与控制** | 相对基础的权限控制。                                       | 更精细的权限控制（通过分离 Token 和权限有效期），内部结构更模块化。 | AccessToken2 提供了更现代、更灵活、可能更安全的鉴权机制。                                                                                                                                                                                  |
| **兼容性**       | 旧版本 SDK 和服务广泛支持。                                  | 新版本 SDK 推荐使用。**注意**: 文档提示，如果同时使用 RTC 扩展产品或服务（如云录制、旁路推流），升级前**建议联系声网技术支持**确认兼容性或进行必要配置。 | 升级到 AccessToken2 可能需要确保所有使用的声网服务（包括扩展服务）都兼容新版 Token。                                                                                                                                                             |

## 使用场景与建议

### 何时使用 AccessToken V1 (`Agora::DynamicKey`)

*   **维护现有旧项目**: 如果你的项目已经在使用 V1 Token (`Agora::DynamicKey`) 并且运行稳定，暂时没有计划或资源进行升级。
*   **特定扩展服务的兼容性要求**: 在极少数情况下，如果使用的某个声网扩展服务（如较旧版本的云录制或旁路推流配置）尚未完全适配 AccessToken2，或者声网技术支持建议暂时维持 V1 Token 以确保兼容性，则可能需要继续使用 V1。**但在采取此方案前，务必与声网官方确认。**

**注意**: AccessToken V1 是旧版机制，除非有明确的兼容性原因，否则不建议在新项目中使用，并推荐将现有项目升级到 AccessToken2 (`Agora::DynamicKey2`)。

### 何时使用 AccessToken2 (`Agora::DynamicKey2`, 推荐)

*   **所有新项目**: 对于所有新开发的、需要集成声网服务的应用程序，**强烈推荐**直接使用 AccessToken2 (`Agora::DynamicKey2`)。
*   **升级现有项目**: 为了获得更好的安全性、更灵活的权限控制、更广泛的服务支持以及与声网最新功能和优化的兼容性，建议将使用 V1 的现有项目升级到 V2。
*   **需要精细化权限有效期控制**: 当你需要 Token 本身的有效期与用户具体操作权限（如发布流）的有效期分开管理时，AccessToken2 是必需的。
*   **需要使用 FPA, Chat, Education, APaaS 服务**: AccessToken2 提供了这些服务的专用 Token 生成器。

**核心优势**: AccessToken2 (`Agora::DynamicKey2`) 提供了更精细、更安全、更易于管理、支持服务更广泛的鉴权方式，是声网推荐的标准实践。

## 从 V1 升级到 AccessToken2 (服务端 Ruby 语言示例要点)

升级主要涉及以下服务端代码修改（假设您的 Gem 已经加载了 `Agora::DynamicKey` 和 `Agora::DynamicKey2` 模块）：

1.  **修改引用的模块和类**:
    ```ruby
    # 移除旧的引用 (如果之前是直接引用文件)
    # require_relative './path/to/old/RtcTokenBuilder'
    # require_relative './path/to/old/AccessToken'

    # 确保 Gem 已加载，通常在 Gemfile 中指定并执行 bundle install
    # require 'your-gem-name' # 加载 Gem

    # 使用新的模块路径
    # 旧 V1 模块: Agora::DynamicKey
    # 新 V2 模块: Agora::DynamicKey2
    ```

2.  **更新 Token 生成调用 (以 RTC 为例)**:
    ```ruby
    app_id = "your_app_id"
    app_certificate = "your_app_certificate"
    channel_name = "your_channel_name"
    user_id_int = 12345 # 使用整数 UID
    user_account_str = "user_account_name" # 或使用字符串账户

    # --- V1 示例 (使用 Agora::DynamicKey) ---
    # expire_duration_seconds = 3600 # V1 需要手动计算绝对时间戳
    # expire_ts = Time.now.to_i + expire_duration_seconds
    # v1_role = Agora::DynamicKey::RtcTokenBuilder::Role_Publisher
    #
    # token_v1 = Agora::DynamicKey::RtcTokenBuilder.build_token_with_uid({
    #   app_id: app_id,
    #   app_certificate: app_certificate,
    #   channel_name: channel_name,
    #   uid: user_id_int,
    #   role: v1_role,
    #   privilege_expired_ts: expire_ts
    # })
    # puts "V1 Token: #{token_v1}"


    # --- V2 示例 (使用 Agora::DynamicKey2) ---
    token_expire_seconds = 3600      # Token 本身有效期 (1小时)
    privilege_expire_seconds = 3600  # 权限有效期 (1小时)
    v2_role = Agora::DynamicKey2::RtcTokenBuilder::ROLE_PUBLISHER # 使用 V2 的角色常量

    # 使用整数 UID 生成 V2 Token
    token_v2_uid = Agora::DynamicKey2::RtcTokenBuilder.build_token_with_uid(
      app_id,
      app_certificate,
      channel_name,
      user_id_int,
      v2_role,
      token_expire_seconds,
      privilege_expire_seconds
    )
    puts "V2 Token (with UID): #{token_v2_uid}"

    # 使用字符串 User Account 生成 V2 Token
    token_v2_account = Agora::DynamicKey2::RtcTokenBuilder.build_token_with_user_account(
      app_id,
      app_certificate,
      channel_name,
      user_account_str, # 使用字符串账户
      v2_role,
      token_expire_seconds,
      privilege_expire_seconds
    )
    puts "V2 Token (with User Account): #{token_v2_account}"

    # --- V2 示例 (生成 RTM Token) ---
    rtm_user_id = "rtm_user_1"
    rtm_token_expire = 3600
    token_v2_rtm = Agora::DynamicKey2::RtmTokenBuilder.build_token(
      app_id,
      app_certificate,
      rtm_user_id,
      rtm_token_expire
    )
    puts "V2 RTM Token: #{token_v2_rtm}"

    # --- V2 示例 (生成 Chat User Token) ---
    chat_user_id = "chat_user_abc"
    chat_token_expire = 3600
    token_v2_chat_user = Agora::DynamicKey2::ChatTokenBuilder.build_user_token(
      app_id,
      app_certificate,
      chat_user_id,
      chat_token_expire
    )
    puts "V2 Chat User Token: #{token_v2_chat_user}"

    ```

3.  **更新角色常量**: 确保使用 `Agora::DynamicKey2::RtcTokenBuilder` 中定义的 `ROLE_PUBLISHER` 或 `ROLE_SUBSCRIBER` 常量（或直接使用对应的整数 1 或 2），并移除对 V1 中已废弃角色的引用 (如 `Role_Attendee`, `Role_Admin`)。

**重要提示**: 上述 Ruby 示例假设您的项目已经正确配置并加载了包含 `Agora::DynamicKey` 和 `Agora::DynamicKey2` 模块的 Gem。

## 结论

AccessToken2 (`Agora::DynamicKey2`) 是声网当前推荐的、更安全、更灵活且支持服务更广泛的鉴权机制。**所有新项目都应采用 AccessToken2**。对于现有项目，强烈建议评估并尽快升级到 AccessToken2，以充分利用其优势并确保与声网平台的长期兼容性。在升级涉及云录制、旁路推流等扩展服务的项目时，务必参考声网最新文档或咨询技术支持。