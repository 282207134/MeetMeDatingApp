# Flutter 验证记录

日期：2026-10-18。以下记录对应项目根目录的 Flutter 版本，旧 SwiftUI 测试记录单独保存在 `legacy/swiftui/docs/`。

## 环境

- Flutter 3.41.6 / Dart 3.11.4。
- Xcode 26.0.1 / iOS 26.0。
- iPhone 17 模拟器：`687B0ECD-3A39-4DF8-8916-3CC213A0D3E8`。
- iOS Bundle ID：`dev.meetme.meetme`。

## 结果

| 检查 | 结果 |
| --- | --- |
| `flutter analyze --no-pub` | 通过，无问题 |
| `flutter test --no-pub` | 10 项通过：6 项状态测试、4 项界面流程 |
| iOS 模拟器编译 | 通过，生成 `build/ios/iphonesimulator/Runner.app` |
| iPhone 自动化完整流程 | 3 组通过 |
| 普通应用启动、结束进程后重新启动 | 通过，可恢复已保存的演示资料 |
| 系统相册选择与头像保存 | 手动验证通过，重启后保存路径和照片文件仍存在 |

状态测试覆盖：喜欢/匹配去重，略过/撤销，筛选，资料与消息重新载入，拉黑阻止延迟回复，空消息与未读数，重置取消旧回复，损坏数据恢复。

界面测试覆盖：输入校验、三步引导、发现→匹配→消息、筛选空状态、资料编辑和退出保留数据。

模拟器三组完整流程：

1. 欢迎→本地注册→基础资料→兴趣→资料预览→发现。
2. 略过→撤销→喜欢→匹配→聊天→模拟回复→通过实际存储插件重新载入→连接/聊天列表。
3. 距离筛选→空状态→编辑姓名→设置开关→重新载入验证→重置→重新进入演示。

11 张实际 Flutter 截图位于 `docs/screenshots/`，见 [截图预览](Preview.md)。集成测试绑定截取 Flutter 渲染内容，因此截图不含 iOS 状态栏图标。

## 重现

```sh
flutter pub get
flutter analyze
flutter test
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d 687B0ECD-3A39-4DF8-8916-3CC213A0D3E8
```

集成测试会重置 Flutter 版演示数据。之后运行 `flutter run -t lib/main.dart -d <设备 ID>`，恢复普通应用入口。

本次未验证 Android 运行或真机运行；未接入服务端认证、真实消息、推送和支付。
