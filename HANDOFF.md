# NeoWC 项目交接文档

更新时间：2026-07-19

## 1. 项目与仓库

- 项目名：NeoWC
- 类型：注入微信的 Theos / Logos Tweak，Objective-C + Logos
- GitHub：`qiu7c/NeoWC`
- 当前分支：`main`
- 远程地址：`ssh://git@ssh.github.com:443/qiu7c/NeoWC.git`
- 使用 SSH 443 是因为当前网络无法稳定连接 GitHub SSH 22 端口。
- 构建目标：`iphone:clang:latest:14.0`
- 架构：`arm64 arm64e`
- ARC：已开启
- GitHub Actions：`.github/workflows/build.yml`，推送后云端 Theos 构建。
- 用户要求：推送构建即可，不主动查询 Actions 构建结果，节省 token。

最近已推送提交：

- `e2b66d1 Improve chat capture and anti-revoke prompts`
- `796e79d Fix long screenshot spacing and quality`
- `e781404 Add anti-revoke and private long screenshots`
- `7b3e701 Resolve game controller dynamically`
- `bdbd1a9 Fix floating window orientation observer`
- `b2ae27e Fix active window lookup for iOS 13+`

## 2. 当前工作区状态（重要）

当前准备提交的改动包括长截图顶栏/输入栏修复、输入栏圆角展平、预览过渡与短图居中、当前会话稳定发送，以及防撤回侧边文字/坐标自定义。本次提交完成后以 `git status` 和最新提交记录为准。

## 3. 用户长期偏好与操作原则

- UI 使用纯白页面、浅灰卡片，卡片长度舒展；不要绿色图标或绿色按钮。
- 图标要简洁、现代、黑白或灰色线条风格；图标周边不要多余背景和阴影。
- 顶部图标与 NeoWC 名称直接融入白色背景，不使用卡片承载。
- 设置分类支持展开/折叠。
- 朋友圈相关、自动登录、小游戏、运动步数、广告屏蔽均归入“增强功能”，不要单独建立朋友圈分类。
- “实验工具”统一称为“开发者功能”。日志必须支持开启和关闭。
- 调试悬浮窗只能从设置中开启，不使用全局手势监听；悬浮按钮支持拖动，非按钮区域必须透传触摸，不能卡住微信。
- 不需要“复制 Hook”。
- 不要在 UI 中显示项目地址链接。
- 用户说“修改代码不要提交”时，只编辑，不检查、不构建、不提交；用户说“提交”时再统一检查并直接推送 `main`。
- 仓库可能存在用户自己的改动；提交前必须先确认 `git status` 和 diff 范围。
- 不要修改或提交 `参考` 下的逆向分析产物，除非用户明确要求。

## 4. 项目入口与总体结构

### 插件注册

入口在 `Tweak.xm` 的 `NeoWCRegisterPlugin()`：

```objc
[[WCPluginsMgr sharedInstance]
    registerControllerWithTitle:@"NeoWC"
                         version:@"0.1.0"
                      controller:NSStringFromClass([NeoWCSettingsViewController class])];
```

`NeoWCEntryLoader +load`、`NewSettingViewController -viewDidLoad` 会尝试注册，使用 `NeoWCDidRegister` 防止重复注册。

### 文件职责

- `Tweak.xm`：微信类 Hook、插件入口、朋友圈、小游戏、步数、广告、自动登录、长截图菜单、防撤回 Cell 提示。
- `Sources/NeoWCSettingsViewController.m`：主设置 UI、分类卡片、所有开关和详情入口。
- `Sources/NeoWCEnhancements.h/.m`：NSUserDefaults 键和总开关判断 `NeoWCEnhancementEnabled()`。
- `Sources/NeoWCDebug.h/.m`：开发者功能、悬浮窗、View 选择、对象层级、Runtime 搜索、日志。
- `Sources/NeoWCPluginVisibility.h/.m`：记录其他插件注册并在插件管理页面隐藏指定入口。
- `Sources/NeoWCAntiRevoke.h/.m`：撤回 XML 解析、原消息查询、本地提示、气泡旁提示、可选回复撤回者。
- `Sources/NeoWCChatCapture.h/.m`：聊天多选长截图、生成提示、高清合成、预览编辑、微信内部分享。

## 5. 当前功能概览

### 设置 UI

- NeoWC 顶部简洁图标和名称。
- 白色背景、灰色卡片风格。
- 分类展开/折叠并持久化。
- 插件管理入口通过 `WCPluginsMgr` 注册。

### 开发者功能

- 设置开关控制悬浮窗。
- 悬浮按钮可拖动。
- 独立调试 Window 只拦截按钮/面板触摸，其余区域透传。
- 当前 View 选择与层级检查。
- Objective-C Runtime 类/方法搜索。
- 对象属性检查和报告复制。
- 日志查看、复制、清空，日志采集可关闭。

关键方法：

- `-[NeoWCDebugManager setFloatingEnabled:]`
- `-[NeoWCDebugManager floatingButtonPanned:]`
- `-[NeoWCDebugManager presentDashboardFromViewController:]`
- `-[NeoWCDebugManager beginViewPicking]`
- `NeoWCLog()`

### 插件显示管理

- Hook `WCPluginsMgr` 的 Controller/Switch 注册请求并记录。
- Hook `WCPluginsViewController` 过滤插件列表。
- 可隐藏不想显示的插件入口，但不会停止插件本身运行。
- 本次未注册的历史插件会显示为未加载。

关键方法：

- `recordControllerWithTitle:version:controller:`
- `recordSwitchWithTitle:key:`
- `NeoWCFilterPluginListController()`

### 防撤回

Hook：`CMessageMgr -onNewSyncNotAddDBMessage:`。

主入口：

```objc
BOOL NeoWCHandleRevokeMessage(id messageManager, id incomingMessage);
```

当前逻辑：

- 识别 `<sysmsg type="revokemsg">`。
- 解析 session、newmsgid、replacemsg。
- 查询原消息并保留，不处理自己主动撤回的消息。
- 支持本地提示模板、回复模板和回复时间限制。
- 提示位置有两种：
  - “消息下方”：插入 type 10000 本地灰字，创建时间使用原消息 `createTime + 1`，目的是排在对应消息后面。
  - “气泡旁”：不插入系统提示，通过 `CommonMessageCellView -layoutSubviews` 在收到的气泡右侧/发出的气泡左侧显示“已拦截撤回”，与气泡垂直居中。
- 气泡旁提示以服务端消息 ID 存入 NSUserDefaults，最多保留约 400 条。

关键方法：

- `NeoWCHandleRevokeMessage()`
- `NeoWCAntiRevokeSidePromptForMessage()`
- `NeoWCRememberSidePrompt()`
- `%hook CommonMessageCellView -layoutSubviews`

注意：

- 用户此前强调不要随意改防撤回 Debug 逻辑。
- 旧版本已经写入数据库、位置错误的 type 10000 提示不会被新代码自动迁移；新位置逻辑主要影响之后发生的撤回。
- 气泡旁布局需要在真机验证图片、语音、视频、超长文字及群聊头像场景，防止可用横向空间不足时覆盖气泡。

### 聊天多选长截图

入口：聊天多选消息后点击“更多”中的“截图”。

Hook：

- `BaseMsgContentViewController -ShowMultiSelectMoreOperation:`
- `MMScrollActionSheet -showInView:` 注入“截图”按钮。
- `BaseMsgContentViewController -scrollActionSheet:didSelecteItem:` 启动截图并主动 `dismissAnimated:YES` 收起微信菜单。

生成流程：

1. `NeoWCStartChatCapture()` 创建 `NeoWCChatCaptureSession`。
2. 读取 `getSelectedMsgs` 并映射消息列表 indexPath。
3. 显示灰色卡片阴影“截图生成中”。
4. 调用 `exitMultiSelectMode`。
5. 等待 1 秒让微信 UI 恢复稳定。
6. 逐条滚动并按 Cell 实际高度截图。
7. 合成顶栏、消息内容和输入栏。
8. 弹出全屏预览。

清晰度：

- Cell 快照使用 `UIScreen.mainScreen.scale`，目标是与原生屏幕截图一致。
- 最终长图优先保持设备原生倍率。
- 只有在输出单边可能超过约 32760 像素时才降低倍率，避免 Core Graphics 尺寸上限。
- 已移除原先 2800 万像素面积降质限制；超长图内存占用会明显增加，需真机关注 WeChat 被 Jetsam 的风险。

编辑功能：

- 矩形模糊，带模糊度滑杆。
- 矩形涂黑。
- 红色自由画笔。
- 撤销。
- 水印、聊天对象名称、生成时间。
- 模糊使用 `CIAffineClamp + CIGaussianBlur`，避免裁剪边缘产生黑框；框选预览不再绘制边框。

分享：

- 右上角只保留一个分享按钮。
- 使用微信 `WCActionSheet`，不再调用 `UIActivityViewController`。
- 操作项：保存到相册、分享给联系人、发送到当前会话。
- 联系人分享：`PasteboardMsgProvider + ForwardMessageLogicController`。
- 当前会话发送：用 `PasteboardMsgProvider` 生成图片消息，再通过 `ForwardMessageLogicController -forwardMsgList:toContacts:` 定向发送。不要再调用 `sendCaptruedImage:`，微信 8.0.71 会在内部触发 `doesNotRecognizeSelector` 崩溃。

关键方法：

- `NeoWCStartChatCapture()`
- `-[NeoWCChatCaptureSession start]`
- `selectedIndexPaths`
- `prepareChrome`
- `captureNextCell`
- `composeImage`
- `-[NeoWCChatCapturePreviewViewController renderedImage]`
- `shareImage / shareToContact / sendToCurrentConversation`

当前优先验证项：

1. 顶栏/输入框修复及输入工具栏圆角展平是否在最新版微信真机生效。
2. 3x 高清超长图是否出现内存峰值或生成失败。
3. 模糊滑杆和画笔在缩放后的长图上坐标是否准确。
4. 微信内部联系人分享在最新版类名和 delegate 回调下是否正常。
5. “发送到当前会话”后预览关闭设置是否符合预期。

### 其他增强功能

- 设备扫码自动确认登录：`MultiDeviceCardLoginContentView`。
- 游戏扫码授权自动允许：`MMAuthorizeUserInfoViewController`。
- 朋友圈双击点赞：`WCTimeLineCellView`。
- 朋友圈操作按钮替换为评论：`WCTimeLineOperateButtonView`。
- 小游戏结果选择：Hook `CMessageMgr -AddEmoticonMsg:MsgWrap:`；支持骰子、石头剪刀布及跨类型彩蛋值。
- 微信运动步数：Hook `WCDeviceStepObject -m7StepCount`。
- 广告屏蔽：Hook `WCDataItem isAd/isVideoAd` 和 `WAAppTaskSplashADConfig`。
- 这些 Hook 大多常驻注册，但每次执行前检查功能开关；关闭功能时仅有很小的分支开销，不执行主要逻辑。

## 6. 参考资料

`参考` 目录包含：

- `wuji-tweak`：用户旧项目，自动登录、小游戏、朋友圈等功能来源。
- `ddzs`：其他插件参考代码。
- `WeChatHeaders`：最新版微信类和方法头文件，适配类名/selector 时优先查询。
- `WeChatEnhance.dylib` 与 `WeChatEnhance-analysis`：防撤回、广告、小游戏等静态分析产物。
- `ChatCapture.dylib` 与 `ChatCapture-analysis`：长截图插件静态分析，尤其是微信分享链路与截图流程。

只把这些作为参考，不把分析目录加入正式编译，也不要无意义提交逆向脚本。

## 7. 构建与 Git 注意事项

- Windows 本地通常没有 Theos，主要依赖 GitHub Actions 构建。
- Xcode 16.4 / iOS 18.5 SDK 会把弃用警告当错误；不要使用：
  - `UIApplication.keyWindow`
  - `UIApplicationDidChangeStatusBarOrientationNotification`
- 微信私有类必须尽量使用 `NSClassFromString` / `objc_getClass` 和动态 `objc_msgSend`，避免链接阶段出现 `Undefined symbols`。之前 `GameController` 就因静态类引用导致链接失败。
- `gh auth status` 最近显示旧 Token 无效，但 Git 通过 SSH 443 推送正常；普通提交推送不依赖 `gh`。
- 提交前执行：

```powershell
$git='C:\Users\C\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe'
& $git status -sb
& $git diff --check
& $git diff
```

- 只暂存本次范围内文件；用户当前习惯是直接提交并推送 `main`。
- 推送：

```powershell
& $git push origin main
```

- 推送后不要主动查询 Actions，除非用户明确要求查看构建结果或提供失败日志。

## 8. 给新窗口的提示词

复制下面整段到新的 Codex 窗口：

```text
继续维护 D:\Vibe\NeoWC 项目。请先完整阅读 D:\Vibe\NeoWC\HANDOFF.md，再查看 git status 和相关源码，不要从头猜测历史。

这是一个微信 Theos/Logos Tweak，仓库是 qiu7c/NeoWC，既有工作流是直接推送 main 触发 GitHub 云构建。参考代码、最新版微信头文件和 dylib 静态分析都在 D:\Vibe\NeoWC\参考。适配微信私有类时优先查 WeChatHeaders，并尽量用 NSClassFromString/objc_getClass/objc_msgSend，避免私有类静态链接失败。

当前提交状态请以 git log -1 和 git status 为准。开始工作前先确认是否存在用户尚未提交的改动，不要覆盖或丢失。

用户偏好：中文沟通；UI 纯白背景、浅灰舒展卡片、黑白灰现代线条图标，不要绿色；分类支持折叠；调试悬浮窗只能从设置开启且必须触摸透传；不要复制 Hook；不要显示项目链接。除非我明确说“提交”，否则只改代码，不检查、不构建、不提交。等我说“提交”时再统一检查、提交并推送 main；推送后不要主动查询 GitHub Actions 结果。

先简短告诉我你已经读懂当前状态，然后等待我的下一个具体需求；不要擅自修改代码。
```
