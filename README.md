# Meetme — Flutter 本地演示版

按 Pixso 的 **MeetMe Dating App** 设计实现的 Flutter 应用。沿用蓝青渐变、Logo 和人物素材，补齐可读文案。项目根目录现在是 Flutter 工程；上一版 SwiftUI 源码完整保留在 `legacy/swiftui/`。

## 运行

开发环境：Flutter **3.41.6**、Dart **3.11.4**、Xcode **26.0.1**。已生成 iOS 和 Android 工程，本次在 **iPhone 17 / iOS 26.0 模拟器**验证。

```sh
flutter pub get
flutter run -d 687B0ECD-3A39-4DF8-8916-3CC213A0D3E8
```

也可在 VS Code / Android Studio 中打开本目录，选择设备后运行 `lib/main.dart`。需要检查 iOS 原生工程时，打开 `ios/Runner.xcworkspace`。

首页点击 **Explore the demo** 可直接体验；**Create an account** 可体验本地注册和三步资料引导。注册表单不连接服务器，密码不会保存。

## 功能

- 欢迎、登录/注册表单、18 岁确认、基础资料与兴趣引导。
- 发现卡片：左右滑动、喜欢、略过、撤销、超级喜欢、资料详情和收藏。
- 年龄、距离、认证筛选，筛选后的空状态和重新发现。
- 匹配弹页、连接/喜欢你/收藏/已略过列表。
- 聊天列表、搜索、未读数、发送文字和明确标注的模拟回复。
- 资料编辑、相册照片选择、兴趣、本地数据保存。
- 取消匹配、拉黑/解除、仅在本机保存的演示举报。
- 设置、帮助、介绍、Plus 视觉预览、退出与重置。

## 数据

这是用户确认的可交互本地演示版。人物、匹配和回复为示例；未接真实身份认证、短信、定位、远程聊天、推送、审核或支付。Plus 只展示体验，不产生订阅或费用。通知和在线开关保存应用内偏好。

资料、消息、互动和偏好通过 `shared_preferences` 保存，键为 `meetme.flutter.state.v1`；选中的照片复制到应用 Documents 目录。退出会保留数据，Settings → Reset all demo data 会删除本地资料和照片并恢复样例。Flutter 版使用独立存储，不会读取旧 SwiftUI 版的数据。

## 代码

| 路径 | 用途 |
| --- | --- |
| `lib/main.dart` | 启动、读取本地状态 |
| `lib/src/app.dart` | 应用入口和四个主标签 |
| `lib/src/store.dart` | 模型、互动规则、消息和持久化 |
| `lib/src/auth.dart` | 欢迎、表单、资料引导 |
| `lib/src/discovery.dart` | 发现、筛选、详情、匹配 |
| `lib/src/social.dart` | 连接、会话、聊天、举报 |
| `lib/src/profile.dart` | 资料、照片、设置和帮助 |
| `lib/src/theme.dart` | 颜色和共享组件 |
| `assets/images/` | 从原设计保留的图像与应用图标 |
| `test/` | 状态与界面测试 |
| `integration_test/` | iPhone 模拟器完整流程 |
| `docs/reference/` | Pixso 原设计参考 |
| `legacy/swiftui/` | 之前的原生版本及其测试记录 |

## 验证

```sh
flutter analyze
flutter test
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d 687B0ECD-3A39-4DF8-8916-3CC213A0D3E8
```

模拟器测试会重置 **Flutter 版演示数据**，并将实际截图保存到 `docs/screenshots/`。查看 [测试记录](docs/Testing.md) 和 [截图预览](docs/Preview.md)。Android 工程已准备好，尚未进行 Android 运行验证。
