# NeoWC 项目交接与实现记忆

## 2026-07-22 反馈修复（本地未推送）

- 图片编辑快捷发送取图修复：不再只等待 `getDisplayImage:`；主动读取 `EditImageForwardAndEditLogicController.getEditImageAttr`、`_editImageAttr` 与编辑视图，解析 `EditImageAttr.editedImage/editedImages/unCropImage`，并 Hook `setEditedImage:`、`setEditedImages:` 在微信写入最终结果时缓存真实全分辨率 `UIImage`。
- 设置页折叠附件布局修复：为“箭头 + UISwitch”的 accessory stack 明确设置 72×32 pt 外层尺寸，避免 UITableView 不计算 accessoryView 自适应尺寸时整体跑到屏幕左侧并重叠。
- 防撤回气泡旁提示恢复为消息 ViewModel 与气泡完成绑定后的主队列刷新，并在 Cell 重新进入窗口时补刷；同步刷新会在绑定未完成时把提示永久隐藏。提示层显式保持 alpha 与高 zPosition。
- 功能子项折叠不再 `reloadSections` 带动整张分类卡片跳动，改为只淡入/淡出父开关紧随的子项，并无动画刷新父行圆角和箭头。
- 新增插件管理快捷入口：可按需动态注册调试日志开关、调试悬浮窗开关、直达调试中心、直达防撤回记录；还可输入自定义入口名称与 Runtime 类名。`UIViewController` 子类直接注册，`UIView` 子类由 `NeoWCDynamicViewShortcutController` 承载。WCPluginsMgr 没有注销 API，因此关闭或更换已注册入口后需重启微信清理本次进程的旧入口。
- 图片编辑快捷发送已能从 `EditImageAttr setEditedImage:` 取得最终编辑图；会话 ID 在编辑器存活时缓存。插件创建独立转发实例，但把微信原 `EditImageForwardAndEditLogicController` 作为代理，点击后立即进入官方确认流程，由微信在发送成功回调后退出编辑，取消确认则保留原编辑流程；不再等待聊天页或扫描 Window。
- 设置分类重新整理：小游戏结果、图片编辑快捷发送和多选导出归入“聊天增强”；登录授权、朋友圈、运动和广告归入“常用增强”；新增“界面优化”。输入栏圆角的实机目标已确认为 `MMInputToolView.subviews.firstObject`（外部工具栏）和 `MMGrowTextView` 本身（内部输入框），内外均支持 0–40 自定义并可恢复微信原始 layer 状态；插件显示管理也移至该分类。
- 聊天输入框新增局部滑动操作开关：仅给 `MMGrowTextView` 安装左右 `UISwipeGestureRecognizer`，左滑通过微信输入组件的文本更新路径清空内容，右滑调用内部 `UITextView paste:` 在当前光标位置粘贴；关闭后移除手势，不监听全局页面。
- 设置页子选项折叠：带子设置的功能开启时自动展开；主功能开启后可轻点该行卡片手动收起/展开，右侧使用方向箭头提示状态，折叠状态独立保存且不改变功能开关。
- 防撤回提示外观：消息下方模板改为全宽多行编辑页并支持自定义文字颜色；气泡旁提示增加系统颜色选择器，位置既可拖动也可直接输入 X/Y 数值；设置卡片内部取消分割线。
- 朋友圈双击点赞反馈：点赞后在双击触点显示约 0.52 秒的爱心弹出、轻微上浮和淡出动画；震动三档统一使用中等触感风格并压缩为 0.58 / 0.76 / 0.90，解决轻档无感和重档过猛。
- 10:22 快速发送崩溃：已用安装 deb 的 arm64e UUID 和偏移确认，`processEditImage:` 参数是微信临时指针而非可持有对象；删除关联保存，改为只在该参数仍有效的 `processEditImage:` 调用栈内生成并缓存真实 `UIImage`。
- 防撤回气泡提示二次修复：同时保存 server ID 和 local ID 两种键，Cell 复用或增量刷新时任一 ID 均可重新匹配；数值转换增加类型保护，异常时回退微信原撤回逻辑。
- 防撤回刷新崩溃修复：已由崩溃 UUID `fde5525946243a538cbad8cafab7ff80` 和偏移 `0xD350` 定位到 `setViewModel:` 的延迟 block；取消跨生命周期捕获消息 Cell，改为 `%orig` 后同步刷新提示，避免 Cell 回收/复用后触发野指针。
- 防撤回气泡旁提示：增加 Cell `setViewModel:`、`updateStatus`、`layoutSubviews` 三处刷新，并排除 `iConsoleWindow`，解决提示需要重进页面才出现、收到新消息后消失的问题。
- 图片编辑快捷发送：保留 `processEditImage:` 的最终编辑结果；用户点击插件按钮时，在编辑器释放前按需调用一次官方 `getDisplayImage:`，不再回退原图，也不干预官方转发流程。
- 多选导出：新增总开关和“纯文本 / 保存图片 / 分享卡片”三个子开关；删除 Markdown；纯文本只复制正文到剪贴板。
- 分享卡片：联系人通过 `CContactMgr` 解析显示名称，禁止暴露 `wxid`；标题不再读取“已选择 N 条消息”；长文本自动换行；增加极简、对话、深色三种样式。
- 朋友圈双击点赞：新增独立震动开关和轻/中/强三级力度。
- 小游戏结果选择：取消系统 Present 动画并缩短自定义上移动画，减少点击后的等待感。
- 微信运动：原逻辑只认手动设置当天；现改为每天首次启动或重新进入前台时，把已保存步数刷新为当天配置。

更新时间：2026-07-22
当前版本：0.1.1

## 项目约束

- NeoWC 是注入微信的 Theos / Logos Tweak，Objective-C + ARC，架构 `arm64 arm64e`。
- 插件入口通过 `WCPluginsMgr` 注册 `NeoWCSettingsViewController`。
- 私有微信类使用 `NSClassFromString`、`objc_getClass` 和动态 `objc_msgSend`，避免链接期未定义符号。
- Windows 本地通常没有 Theos；提交前做静态检查，推送 `main` 后由 GitHub Actions 构建。
- 推送后不主动查询构建结果。
- UI 偏好：纯白背景、舒展浅灰卡片、黑白灰线性图标、分类展开折叠，不使用绿色强调色。

## 0.1.1 阶段二：图片编辑快捷发送

状态：已完成代码实现。

- 只在具有有效 `c2CUserName` 的聊天图片编辑流程显示“发送到当前会话”。
- 使用微信官方 `getDisplayImage:` 的编辑结果，禁止回退发送原图。
- 发送前再次校验编辑会话用户名和联系人用户名，避免群聊/私聊串会话。
- 创建消息、联系人、Selector 或编辑结果失败时显示具体原因。
- 点击确认发送后等待微信成功回调；20 秒无成功结果提示网络/接口超时。
- 成功后显示“图片已发送”。
- 快捷发送不再提供“发送后返回聊天”子开关；生命周期完全跟随微信官方编辑转发逻辑。
- 2026-07-19 回归修复：移除对全局 `ForwardMessageLogicController` 的全部 Hook，避免干扰微信官方编辑图片转发。
- 快速发送不再使用 `NeoWCImageQuickSendDelegate`、Window 扫描或后台重试；新转发实例仅处理指定联系人，代理仍为微信原图片编辑逻辑，避免干扰官方“转发给朋友”。
- 点击“发送到当前会话”时同步调用官方确认页；只有确认发送成功后才退出编辑模式。
- 根因修复：禁止在 `processEditImage:` 前后主动调用 `getDisplayImage:`；改为 Hook 微信自身对 `getDisplayImage:` 的正常调用并旁路保存返回图片，避免重复消费编辑结果导致官方转发也失效。

关键文件：`Tweak.xm`。

## 0.1.1 阶段三：防撤回与兼容性

状态：已完成代码实现。

- 防撤回记录中心保存本次微信运行期间的记录，支持联系人、会话和内容搜索。
- 记录区分文字、图片、文件/分享和其他消息类型。
- 默认只保存在内存；用户开启后才把摘要持久化。关闭持久化会删除本地归档。
- 只保存摘要、类型、会话和时间，不复制图片或文件，降低隐私风险。
- 气泡旁提示改为独立外观预览页，可修改文字并拖动定位。
- 推荐位置按钮恢复 X=0 / Y=10，修改会通知当前可见聊天 Cell 刷新。
- 功能兼容性中心显示微信版本，并区分“可用 / 类不存在 / Selector 变化 / 尚未触发”。
- 兼容性检查只读取 Runtime，不主动执行功能。

关键文件：`Sources/NeoWCAntiRevoke.m`、`Sources/NeoWCCompatibility.m`。

## 0.1.1 阶段四：多选消息扩展

状态：已完成代码实现；按用户要求不实现批量保存文件。

- 微信多选消息“更多”菜单可按子开关显示：纯文本、保存图片、分享卡片。
- 纯文本仅复制消息正文到剪贴板，不包含时间、发送者、wxid 或格式标记；Markdown 已移除。
- 批量保存仅处理已经下载到本地的图片；不处理文件附件。
- 分享卡片按正文高度动态布局并自动换行，提供极简、对话和深色三种高倍率样式。
- 所有入口复用微信当前 `getSelectedMsgs`，不持续监听聊天页面。

关键文件：`Sources/NeoWCChatExport.m`、`Tweak.xm`。

## 现有其他功能

- 防撤回与两种提示模式、可选回复撤回者。
- 设备扫码自动登录、游戏扫码自动授权。
- 朋友圈双击点赞、操作按钮快捷评论。
- 小游戏结果选择及跨类型彩蛋。
- 微信运动步数、广告净化。
- 插件显示管理。
- 开发者调试中心、可移动悬浮按钮、View 层级和 Runtime 检查、可关闭日志。

## 真机验证重点

- 微信私有 UI 只能在真机注入后最终验证；编译通过不代表所有版本的 Selector 行为完全一致。
- 微信可能不提供明确的发送失败回调，因此已提供准备阶段具体错误和确认发送后的超时提示。
- 仅本地已下载的图片可批量保存；未下载图片会跳过并提示。

## 提交检查

```powershell
$git='C:\Users\C\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe'
& $git status -sb
& $git diff --check
& $git diff --stat
```

远程：`ssh://git@ssh.github.com:443/qiu7c/NeoWC.git`，当前工作流直接提交并推送 `main`。
