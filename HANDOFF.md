# NeoWC 项目交接文档

更新时间：2026-07-22
项目版本：0.1.1
仓库：`git@github.com:qiu7c/NeoWC.git`
主分支：`main`

## 1. 当前工作区状态

- 最近已推送提交：`1488432 Remove anti-revoke cell layout loop`。
- 当前本地还有未推送修改：
  - 保留防撤回气泡方案的弱引用合并刷新修复。
  - 优化设置页分类和功能子项展开动画。
- 提交前必须先执行 `git status --short` 和 `git diff --check`，不要覆盖用户已有修改。
- 用户通常会明确说“推送”后再提交；推送后不主动查询 GitHub Actions 构建结果。

## 2. 项目定位与构建

NeoWC 是注入微信的 Theos / Logos Tweak，使用 Objective-C、ARC 和原生 UIKit。

- 包名：`com.qiu7c.neowc`
- 注入目标：`com.tencent.xin`
- 多开兼容注入：`com.tencent.xin`、`com.tencent.wx`、`com.tencent.qy.xin`
- 架构：`arm64 arm64e`
- 最低目标：iOS 14
- 安装进程：`WeChat`
- 源文件入口：`Tweak.xm`
- 其他源文件：`Sources/*.m`
- 图标源文件：`Assets/NeoWCIcon.svg`

本机 Windows 通常没有 Theos，最终编译由 GitHub Actions 完成。Makefile 会自动包含 `Sources/*.m`。

本地静态检查：

```powershell
$git='C:\Users\C\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe'
& $git status --short
& $git diff --check
& $git diff --stat
```

## 3. 插件入口

当 `WCPluginsMgr` 存在时注册：

- 标题：NeoWC
- 版本：0.1.1
- Controller：`NeoWCSettingsViewController`

注册调用：

```objc
[[objc_getClass("WCPluginsMgr") sharedInstance]
    registerControllerWithTitle:@"NeoWC"
                         version:@"0.1.1"
                      controller:@"NeoWCSettingsViewController"];
```

不要在界面放项目链接。UI 风格为纯白背景、浅灰舒展卡片、黑白灰线性图标和系统蓝色开关，不使用绿色强调色。

## 4. 文件职责

| 文件 | 职责 |
| --- | --- |
| `Tweak.xm` | Logos Hook、插件注册、快捷发送流程、朋友圈/游戏/登录/广告入口、聊天 UI Hook |
| `Sources/NeoWCSettingsViewController.m` | 设置页、分类和子项折叠、开关及编辑器入口 |
| `Sources/NeoWCAntiRevoke.m` | 防撤回解析、消息查询、本地提示、回复、记录中心和配置 |
| `Sources/NeoWCAntiRevokeTemplateEditor.m` | 防撤回模板编辑 |
| `Sources/NeoWCChatExport.m` | 多选纯文本、图片保存和分享卡片 |
| `Sources/NeoWCInterfaceTweaks.m` | 输入栏圆角、免打扰图标隐藏与原状态恢复 |
| `Sources/NeoWCEnhancements.m` | 功能键、颜色工具和总开关判断 |
| `Sources/NeoWCDebug.m` | 日志、悬浮按钮、调试中心和 View 选择器 |
| `Sources/NeoWCCompatibility.m` | Runtime 类/Selector/触发状态检查 |
| `Sources/NeoWCPluginVisibility.m` | 记录插件注册并隐藏指定插件入口 |
| `Sources/NeoWCPluginShortcuts.m` | 动态注册日志、悬浮窗、调试中心及自定义页面入口 |

`参考/` 下的源码、dylib 和分析目录只用于对照，不要把分析脚本或反编译临时产物加入主工程。

## 5. 当前设置分类

### 聊天增强

- 防撤回
  - 消息下方提示
  - 气泡旁提示
  - 自定义文字、颜色和 X/Y
  - 推荐位置：X=0、Y=10
  - 回复撤回者与时间限制
  - 运行期记录中心与可选本地摘要
- 小游戏结果选择及骰子/猜拳跨类型彩蛋
- 聊天记录小丑：长按文字、应用或转账消息，仅修改当前页面本机显示
- 输入框左滑清空、右滑粘贴
- 官方图片编辑后快速发送到当前会话
- 多选消息导出
  - 复制纯消息正文
  - 批量保存已下载图片
  - 极简、对话、深色分享卡片

### 常用增强

- 设备扫码自动登录
- 游戏扫码授权自动允许
- 朋友圈双击点赞、爱心动画和震动强度
- 朋友圈操作按钮直接评论
- 自定义微信运动步数，每日启动或回前台刷新日期
- 钱包余额本地显示：长按钱包入口或余额数字设置，仅替换本机界面文字
- 好友数量本地显示：仅替换“个朋友”等明确好友数量文案
- 朋友圈与小程序启动广告净化

### 界面优化

- 输入框内部圆角
- 外部工具栏圆角
- 内外圆角 0–40 自定义
- 隐藏聊天标题旁“免打扰”图片
- 全局文字替换风险开关：通过 `MMUILabel setText:` 完全匹配原文字后替换
- 插件显示管理

### 开发者功能

- 可移动调试悬浮按钮；不使用全局激活手势
- 可关闭调试日志
- 调试中心、View 选择器、Runtime 搜索
- 功能兼容性中心
- 插件管理快捷入口和自定义 UIViewController/UIView Runtime 类入口

## 6. 关键 Hook 与约束

| 功能 | 类与方法 | 约束 |
| --- | --- | --- |
| 防撤回核心 | `CMessageMgr onNewSyncNotAddDBMessage:` | 开关关闭时立即回到 `%orig` |
| 气泡旁提示 | `CommonMessageCellView setViewModel:`、`updateStatus`、`didMoveToWindow` | 禁止重新加入 `layoutSubviews` Hook；禁止主动 `setNeedsLayout/layoutIfNeeded` |
| 消息下方颜色 | `SystemMessageCellView layoutSubviews` | 只在颜色变化时重绘，并保存原色用于恢复 |
| 图片编辑结果 | `EditImageAttr setEditedImage:`、`setEditedImages:` | 只被动接收微信最终图，不 Hook `processEditImage:` 或 `getDisplayImage:` |
| 快捷发送菜单 | `WCActionSheet showInView:` | 只在聊天编辑上下文和有效会话中增加按钮 |
| 快捷发送确认 | `SharePreConfirmSheetView onConfirmButtonClick/onCancelButtonClick` | 不干扰微信官方转发实例和代理 |
| 输入栏圆角 | `MMInputToolView didMoveToWindow` | 不 Hook `layoutSubviews`；相同配置只应用一次 |
| 输入框滑动 | `MMGrowTextView didMoveToWindow` | 手势只安装一次，`cancelsTouchesInView=NO` |
| 免打扰图标 | `UIImageView setAccessibilityLabel:/didMoveToWindow/setHidden:` | 仅处理标签严格等于“免打扰”的已管理图片 |
| 多选导出 | `BaseMsgContentViewController`、`MMScrollActionSheet` | 只在多选“更多”菜单构建期间插入项目 |
| 朋友圈 | `WCTimeLineCellView`、`WCTimeLineOperateButtonView` | 所有逻辑必须受开关控制 |
| 游戏选择 | `CMessageMgr AddEmoticonMsg:MsgWrap:` | 非游戏消息和关闭状态直接 `%orig` |
| 聊天记录小丑 | `TextMessageCellView`、`AppMessageCellView`、`WCPayTransferMessageCellView` 的 `operationMenuItems`/`canPerformAction:withSender:` | 仅在开关开启时插入“小丑”菜单；只做当前页面本机显示修改 |
| 钱包余额显示 | `TimeoutNumber updateNumber:/didMoveToSuperview`、`WCPayWalletEntryHeaderView didMoveToSuperview`、`MMUILabel setText:` | 仅替换本机 UI 文本，不触碰支付动作、交易状态或网络请求 |
| 好友数量显示 | `MMUILabel setText:` | 必须匹配“个朋友”等明确文案，禁止无条件全局替换 |
| 全局文字替换 | `MMUILabel setText:` | 风险开关默认关闭；必须配置原文字和替换文字；只做完全匹配，不做模糊/正则替换 |
| 广告 | `WCDataItem`、`WAAppTaskSplashADConfig` | 关闭状态返回微信原值 |

私有类不要以强链接符号方式引用。优先使用 `NSClassFromString`、`objc_getClass`、`sel_registerName` 和类型明确的 `objc_msgSend`。

## 7. 防撤回当前实现

### 核心逻辑

- 解析 `revokemsg` XML。
- 查询原消息并拦截好友撤回。
- 群聊和私聊分别处理。
- 自己撤回的消息保留微信原逻辑。
- 可创建 type-10000 本地提示。
- 提示记录同时使用 server ID 和 local ID，适配 Cell 复用和增量刷新。
- 运行时异常必须回退 `%orig`，不能阻断微信收消息。

### 气泡旁方案

这是近期卡顿修复的重点：

- 普通消息 Cell 不再 Hook `layoutSubviews`。
- `setViewModel:`、`updateStatus`、`didMoveToWindow` 只调用合并调度器。
- 每个 Cell 同一时刻最多存在一个刷新任务。
- 异步任务只弱引用 Cell，Cell 释放或离开 Window 后直接结束。
- 不主动请求布局，不强制同步布局。
- 文字、颜色和 frame 只有变化时才写入。
- label 使用高 `zPosition`，不在每次刷新调用 `bringSubviewToFront:`。

不要重新采用“每次布局刷新”的旧方案，否则搜索消息跳转、进入聊天和返回可能卡住。

## 8. 图片编辑快捷发送

- 用户在微信官方图片编辑完成菜单点击“发送到当前会话”。
- 最终图片从微信对 `EditImageAttr` 的 setter 写入中取得。
- `NeoWCQuickSendSession` 独立强持有图片、消息、联系人、转发逻辑和来源编辑逻辑。
- 只有用户在确认页真正点击发送并收到发送回调后，才允许结束编辑。
- 点击取消必须保留编辑流程。
- 官方“转发给朋友”不得使用 NeoWC 的 session 或代理。
- 不允许回退发送原图。

真机重点验证：

1. 编辑后的图片而不是原图进入确认页。
2. “发送到当前会话”确认后能发送。
3. 取消后编辑内容仍在。
4. 停留确认页十秒后仍能发送。
5. 官方转发联系人列表和确认页不受影响。
6. 朋友圈图片编辑不应错误发送到聊天联系人。

## 9. 设置页 UI

- 分类支持展开/折叠并保存状态。
- 带子项的功能支持轻点父卡片收起或展开。
- 关闭主开关时箭头透明但保留占位，避免 UISwitch 左移。
- 当前本地动画优化：
  - 分类标题不 reload，只插入/删除内部行。
  - 父功能行不 reload。
  - 子项使用顶部轻滑动画。
  - 箭头独立进行 0.2 秒旋转。
  - 父卡片圆角原位更新。
- 不要恢复整段 `reloadSections` 或父行 reload 动画，否则会造成整张卡片跳动。

## 10. 已删除或明确不做

- 长截图功能已完全移除，不要恢复相关 Controller、菜单和渲染代码。
- Markdown 导出已移除。
- 多选批量保存文件附件不实现，只保存已下载图片。
- View 选择器不提供“复制 Hook”。
- 不使用全局手势启动调试悬浮窗。

## 11. 已知限制

- 微信私有类和 Selector 会随版本变化，必须依赖兼容性中心和真机日志确认。
- `WCPluginsMgr` 没有注销 API；动态快捷入口关闭或改名后，旧入口可能要重启微信才消失。
- 多开微信可能更改 Bundle ID、容器和运行环境；主 plist 当前只注入官方 `com.tencent.xin`。
- 本地 Windows 无法完整验证 Theos/iOS 私有 API 编译，推送后由云端构建。
- 调试日志默认开启；排查性能时可先关闭。

## 12. 下一轮真机验证顺序

1. 开启防撤回气泡方案，进入普通聊天。
2. 搜索聊天记录并跳转到目标消息，再返回。
3. 快速切换多个聊天并接收新消息。
4. 撤回后确认提示立即出现且不会消失。
5. 关闭防撤回后重复上述流程。
6. 测试输入栏圆角开启/关闭、搜索跳转和返回。
7. 测试图片编辑快捷发送与官方转发。
8. 测试设置页分类和子项展开动画。

若只有气泡方案开启时卡顿，优先检查 `CommonMessageCellView` 的三处低频入口和合并调度器，禁止先恢复布局 Hook。

## 13. Git 提交流程

远程使用 SSH 443：

```text
ssh://git@ssh.github.com:443/qiu7c/NeoWC.git
```

提交前：

```powershell
& $git status --short
& $git diff --check
& $git diff --stat
```

提交只包含当前任务文件，不修改 `参考/` 中的分析材料，不覆盖无关用户改动。用户要求推送时推送 `main`，不主动等待或查询云构建结果。

## 14. 新窗口接手提示词

```text
继续维护 D:\Vibe\NeoWC。先完整阅读 HANDOFF.md，再查看 git status、最近提交和当前 diff。不要恢复长截图或 Markdown 导出。当前最重要的是保持防撤回气泡方案不使用 CommonMessageCellView layoutSubviews，不主动 setNeedsLayout/layoutIfNeeded；刷新必须弱引用并合并。保留图片编辑快捷发送与官方转发隔离。未经我明确要求不要推送，推送后不要查询构建结果。
```
