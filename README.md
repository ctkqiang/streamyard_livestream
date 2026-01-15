# StreamYard 直播 Flutter 包

一个用于嵌入 StreamYard 直播流并自动加入聊天功能的 Flutter 包。

## 功能特性

- 📺 **嵌入 StreamYard 直播流** - 直接在 Flutter 应用中显示 StreamYard 直播
- 🤖 **自动加入聊天** - 自动填写并提交聊天加入表单，包含用户信息
- 🔧 **JavaScript 交互** - 强大的 JavaScript 注入，与 StreamYard 网页界面交互
- 🎨 **可定制化 UI** - 灵活的组件样式和配置选项
- 📱 **跨平台支持** - 支持 Android、iOS、Web、Windows、macOS 和 Linux
- 🔍 **调试日志** - 全面的日志记录，便于调试注入问题

## 安装

添加到 `pubspec.yaml`：

```yaml
dependencies:
  streamyard_livestream: ^0.0.1
```

然后运行：

```bash
flutter pub get
```

## 快速开始

```dart
import 'package:flutter/material.dart';
import 'package:streamyard_livestream/streamyard_livestream.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreamYard 示例',
      home: Scaffold(
        appBar: AppBar(title: Text('直播流')),
        body: StreamYardLiveWidget(
          streamId: '你的_流_ID',
          streamTitle: '我的直播',
          user: StreamYardUser(
            firstName: '张',
            lastName: '三',
          ),
        ),
      ),
    );
  }
}
```

## API 参考

### StreamYardUser

用于自动加入功能的用户信息。

```dart
StreamYardUser user = StreamYardUser(
  firstName: '张',
  lastName: '三',
);
```

### StreamYardLiveWidget

显示 StreamYard 直播流的主要组件。

```dart
StreamYardLiveWidget({
  required String streamId,
  required String streamTitle,
  required StreamYardUser user,
  AppBar? actionBar,
  Color? backgroundColor,
  TextStyle? actionBarTextStyle,
})
```

**参数：**
- `streamId` (必需): StreamYard 流/观看 ID
- `streamTitle` (必需): 流显示的标题
- `user` (必需): 用于自动加入聊天的用户信息
- `actionBar`: 自定义应用栏（默认为简单标题 + 刷新按钮）
- `backgroundColor`: 背景颜色（默认为白色）
- `actionBarTextStyle`: 应用栏文本样式（默认为黑色，13px）

### StreamYardWebInteropt

用于 StreamYard 网页交互的实用类。

```dart
// 获取实例
final controller = StreamYardWebInteropt.instance;

// 生成流 URL
String url = controller.streamUrl('流_ID');

// 生成自动加入 JavaScript
String jsScript = controller.autoJoinStream(user: user);
```

## 高级用法

### 手动加入聊天

```dart
StreamYardLiveWidget(
  // ... 其他参数
  actionBar: AppBar(
    title: Text('直播流'),
    actions: [
      IconButton(
        icon: Icon(Icons.person_add),
        onPressed: () {
          // 在组件状态中调用 manualJoinChat()
        },
      ),
    ],
  ),
)
```

### 自定义样式

```dart
StreamYardLiveWidget(
  streamId: '你的-流-id',
  streamTitle: '自定义样式直播',
  user: StreamYardUser(firstName: '李', lastName: '四'),
  backgroundColor: Colors.grey[100],
  actionBarTextStyle: TextStyle(
    color: Colors.blue,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
)
```

### 状态管理

组件通过 JavaScript 处理器提供状态更新：

```dart
controller.addJavaScriptHandler(
  handlerName: 'logMessage',
  callback: (args) {
    final message = args.first as String;
    print('JS 日志: $message');
  },
);

controller.addJavaScriptHandler(
  handlerName: 'updateState',
  callback: (args) {
    final data = args.first as Map;
    final state = data['state'] as String;
    final message = data['message'] as String;
    // 处理状态更新
  },
);
```

## JavaScript 注入

自动加入脚本执行以下操作：

1. **等待加入按钮** - 扫描页面上的"加入"按钮
2. **打开加入模态框** - 点击加入按钮打开聊天模态框
3. **查找输入字段** - 通过占位符文本定位姓/名输入框
4. **填写表单数据** - 使用 React 兼容的值设置方式填充用户信息
5. **高亮提交按钮** - 可视化指示提交按钮供用户交互

## 故障排除

### 自动加入不工作

1. **检查流 ID** - 确保流 ID 正确且流处于活动状态
2. **验证用户信息** - 确保提供了 firstName 和 lastName
3. **检查 JavaScript 控制台** - 启用调试日志查看注入进度
4. **StreamYard UI 变更** - 包使用基于占位符的输入检测；如果 StreamYard 更改了 UI，可能需要更新选择器

### WebView 问题

1. **权限** - 确保应用具有必要的网页权限
2. **启用 JavaScript** - WebView 默认启用 JavaScript
3. **网络连接** - 检查设备互联网连接

## 平台特定说明

### Android
在 `AndroidManifest.xml` 中添加互联网权限：
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS
在 `Info.plist` 中添加网络访问：
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### Web
无需额外配置。

## 示例

查看 `example/` 目录获取完整的可运行示例。

## 开发

### 构建

```bash
flutter pub get
flutter analyze
flutter test
```

### 测试

```bash
flutter test
```
