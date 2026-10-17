# Meetme — iPhone 本地演示版

按 Pixso 中的 **MeetMe Dating App** 设计制作的 SwiftUI 应用。保留蓝青渐变、原始 Logo、人物素材和卡片式界面，并用原生文字补齐设计稿中未能渲染的文案。

已在 iPhone 17 / iOS 26.0 模拟器运行验证：4 项状态测试与 5 项 UI 流程均有通过记录。查看 [测试记录](docs/Testing.md) 和 [实际截图](docs/Preview.md)。

## 打开与运行

使用 Xcode 26 或更新版本打开 `MeetMe.xcodeproj`，选择 **MeetMe** Scheme 和 iPhone 模拟器后运行。应用最低支持 iOS 18，无第三方依赖，不需要账号、API Key 或签名团队即可在模拟器运行。

也可运行：

```sh
zsh scripts/run_simulator.sh
```

首次进入可点击 **Explore the demo**，或通过 **Create an account** 体验本地注册和三步资料引导。注册表单不连接服务器，密码不会存储。

## 已实现

- 欢迎、注册/登录表单、18 岁确认、三步资料引导。
- 卡片发现页：横向滑动、喜欢、略过、撤销、超级喜欢、资料详情和收藏。
- 年龄、距离、认证筛选及筛选后的空状态。
- 双向喜欢后的匹配界面、连接/喜欢你/收藏/已略过列表。
- 聊天列表、搜索、未读状态、发送文字、明确标注的模拟回复。
- 个人资料编辑、照片选择、兴趣、偏好与本地持久化。
- 取消匹配、拉黑/解除拉黑、仅在本机保存的演示举报。
- 帮助、应用介绍、订阅体验预览、退出、重置数据。

## 数据边界

这是用户确认的完整本地演示版。人物为示例，匹配由本地规则产生，聊天回复由程序模拟；未接入真实身份认证、短信、定位、云端消息、推送、审核或支付。订阅页面不购买、不扣费。通知和在线开关保存应用内偏好，不请求系统推送权限。

资料、聊天和筛选以 Codable + UserDefaults 保存。自行选择的照片保存在应用 Documents 中。退出后数据保留；Settings → Reset all demo data 可恢复样例数据。

## 结构与验证

- `MeetMe/Models.swift`：统一状态、数据模型、持久化和互动逻辑。
- `MeetMe/Authentication.swift`：欢迎、表单与资料引导。
- `MeetMe/Discovery.swift`：发现、筛选、详情、匹配。
- `MeetMe/Social.swift`：连接、聊天、举报。
- `MeetMe/Profile.swift`：资料、照片、设置和帮助。
- `MeetMe/Theme.swift`：设计色、共享界面组件。
- `MeetMeTests/`：状态逻辑与持久化测试。
- `MeetMeUITests/`：模拟器交互流程与截图。
- `docs/reference/`：从用户 Pixso 文件读取的参考图。

执行测试：

```sh
xcodebuild -project MeetMe.xcodeproj -scheme MeetMe \
  -destination 'platform=iOS Simulator,name=MeetMe iPhone 17' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO \
  -parallel-testing-enabled NO test
```

工程文件已生成，可直接在 Xcode 打开。若新增 Swift 源文件，可运行 `python3 scripts/generate_project.py` 更新工程引用。应用图标由 `swift scripts/create_icon.swift` 从原设计 Logo 生成。
