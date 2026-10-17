# 模拟器测试记录

验证日期：2026-10-17（Asia/Tokyo）。

环境：Xcode 26.0.1 / iOS 26.0 (23A343) / Apple Silicon / `MeetMe iPhone 17` 模拟器。

应用及两个测试 Target 均编译通过。**9 个测试用例均已通过最终验证，当前没有未解决的测试失败。** 结果按每个用例最后一次执行统计；注册用例在改为使用键盘“完成”收起输入法后切换字段的流程后单独重跑通过。

| 范围 | 验证内容 | 结果 |
| --- | --- | --- |
| 状态逻辑 | 双向喜欢生成唯一匹配，并在重建 Store 后恢复 | 通过 |
| 状态逻辑 | 距离筛选、略过与撤销 | 通过 |
| 状态逻辑 | 空白消息不发送，拉黑移除匹配和对话 | 通过 |
| 状态逻辑 | 资料、通知偏好、退出后的数据保留 | 通过 |
| 模拟器 UI | 修改姓名和开关，终止并重启后恢复 | 通过 |
| 模拟器 UI | 打开资料、收藏、在连接页找到收藏 | 通过 |
| 模拟器 UI | 缩小距离得到空状态，重启保留筛选，重置恢复卡片 | 通过 |
| 模拟器 UI | 喜欢 → 匹配 → 聊天 → 模拟回复 → 重启恢复消息 | 通过 |
| 模拟器 UI | 注册表单、年龄确认、三步资料引导、进入发现页 | 通过 |

机器可读结果与应用二进制摘要见 [TestResults.json](TestResults.json)。各用例记录了对应的 `.xcresult` 路径，结果包位于工作目录的 `build/` 中。前八项的通过记录在 `SimulatorTests-Verified.xcresult`，最后一项在 `RegistrationStable.xcresult`。

本次也检查了实际模拟器截图，文字由原生 SwiftUI 正常绘制。截图目录为 [screenshots](screenshots)。没有在物理 iPhone 或其他 iOS 版本上测试；相册选择、举报、拉黑解除等其余界面没有逐项自动化覆盖。

重新执行完整测试：

```sh
xcodebuild -project MeetMe.xcodeproj -scheme MeetMe \
  -destination 'platform=iOS Simulator,name=MeetMe iPhone 17' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO \
  -parallel-testing-enabled NO test
```
