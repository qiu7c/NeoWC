# NeoWC 项目交接文档

更新时间：2026-08-09
项目版本：0.1.2
仓库：`git@github.com:qiu7c/NeoWC.git`
主分支：`main`

## 1. 当前工作区状态

- 最近已推送提交：`9baa029 Fix native chat search cleanup`。
- 当前未提交修改包含微信运动分时段递增、完整删除聊天搜索/关键词提醒/群聊艾特提醒，以及新增胶囊工具栏。
- `main` 的已推送部分与 `origin/main` 同步；开始新工作前仍须重新检查 `git status` 和当前 diff。
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
本地 `.env` 已被 Git 忽略，并将大小写两套 `HTTP_PROXY/HTTPS_PROXY/ALL_PROXY` 清空、`NO_PROXY` 设为 `*`。并非所有工具都会自动读取 dotenv，执行网络命令时仍应显式加载或清空代理环境变量。

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
- 版本：0.1.2
- Controller：`NeoWCSettingsViewController`

注册调用：

```objc
[[objc_getClass("WCPluginsMgr") sharedInstance]
    registerControllerWithTitle:@"NeoWC"
                         version:@"0.1.2"
                      controller:@"NeoWCSettingsViewController"];
```

不要在界面放项目链接。UI 风格为纯白背景、浅灰舒展卡片、黑白灰线性图标和系统蓝色开关，不使用绿色强调色。

## 4. 文件职责

| 文件 | 职责 |
| --- | --- |
| `Tweak.xm` | Logos Hook、插件注册、快捷发送流程、朋友圈/游戏/登录/广告入口、聊天 UI Hook |
| `Sources/NeoWCAccount.m` | 获取当前登录用户内部 wxid，供设置页显示及后续账号验证复用 |
| `Sources/NeoWCSettingsViewController.m` | 设置页、分类和子项折叠、开关及编辑器入口 |
| `Sources/NeoWCAntiRevoke.m` | 防撤回解析、消息查询、本地提示、回复、记录中心和配置 |
| `Sources/NeoWCAntiRevokeTemplateEditor.m` | 防撤回模板编辑 |
| `Sources/NeoWCChatExport.m` | 多选纯文本、图片保存和分享卡片 |
| `Sources/NeoWCInterfaceTweaks.m` | 胶囊工具栏、输入栏圆角、免打扰图标隐藏与原状态恢复 |
| `Sources/NeoWCEnhancements.m` | 功能键、颜色工具和总开关判断 |
| `Sources/NeoWCDebug.m` | 日志、悬浮按钮、调试中心和 View 选择器 |
| `Sources/NeoWCCompatibility.m` | Runtime 类/Selector/触发状态检查 |
| `Sources/NeoWCPluginVisibility.m` | 记录插件注册并隐藏指定插件入口 |
| `Sources/NeoWCPluginShortcuts.m` | 动态注册日志、悬浮窗、调试中心及自定义页面入口 |
| `REFERENCE_PLUGIN_ANALYSIS.md` | 2DD、WeChatX、WCPulse、WeChatEnhance、存自拍和微信广告的稳定反编译结论 |

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
- 聊天记录显示修改：长按文字、应用、图片或转账消息，仅修改当前页面本机显示
- 语音自动转文字，可分别忽略群聊、私聊和自己发送
- 引用回复手势复用微信原生回复入口
- 引用消息定位
- 红包详情显示与通话二次确认
- 普通文字消息屏蔽、长按菜单管理
- 群成员进退群提醒
- 自动选择原图
- 通知点击直接进入对应聊天
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
- 朋友圈转发：快捷评论开启时独立按钮，关闭时加入微信原操作菜单
- 长按朋友圈头像，将微信原“设置权限/投诉”菜单替换为 4 个原生权限快捷项和投诉
- 朋友圈显示精确发布时间，可展开设置 `yyyy-MM-dd HH:mm:ss` 等自定义格式
- 自定义微信运动步数，同时覆盖设备对象与上传请求的三个精确步数字段
- 钱包余额本地显示：设置页只提供开关，余额必须在钱包页长按入口或余额数字设置，仅替换本机界面文字
- 好友数量本地显示：仅替换“个朋友”等明确好友数量文案
- 朋友圈与小程序启动广告净化

### 界面优化

- 胶囊工具栏：左侧语音与输入框、右侧表情与更多，共用顶栏玻璃效果和阴影配置
- 输入框内部圆角
- 外部工具栏圆角
- 内外圆角 0–40 自定义
- 隐藏聊天标题旁“免打扰”图片
- 插件显示管理
- 页面缩放：全局字体规则/网页文字与 NeoWC 设置页比例分别配置

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
| 胶囊工具栏 | `MMInputToolView didMoveToWindow` | 只透明化原背景并在原控件后加入两个不接收触摸的玻璃胶囊；不移动或替换微信按钮 |
| 输入框滑动 | `MMGrowTextView didMoveToWindow` | 手势只安装一次，`cancelsTouchesInView=NO` |
| 免打扰图标 | `UIImageView setAccessibilityLabel:/didMoveToWindow/setHidden:` | 仅处理标签严格等于“免打扰”的已管理图片 |
| 多选导出 | `BaseMsgContentViewController`、`MMScrollActionSheet` | 只在多选“更多”菜单构建期间插入项目 |
| 朋友圈 | `WCTimeLineCellView`、`WCTimeLineOperateButtonView` | 所有逻辑必须受开关控制 |
| 朋友圈转发 | `WCTimeLineCellView`、`WCOperateFloatView` | 快捷评论开启时显示独立转发按钮；关闭时在原浮动菜单中增加“转发”；媒体仅使用参考插件确认的下载器、路径和发布控制器 |
| 朋友圈头像快捷权限 | `WCTimeLineCellView editBlackList`、`WCActionSheet showInView:` | 只识别原生“设置权限/设置 + 投诉”两项菜单；失败时完整保留原菜单；权限动作仅调用已从参考插件确认的 `opAllPermission`、`opSocialBlackPermission`、`opOutsider:`、`opWCBlacklist:` |
| 朋友圈精确时间 | `WCTimeLineCellView initTimeLabel/updateWithDataItem:actionAreaVM:` | 时间源严格使用 `m_dataItem.createtime` 的 Unix 秒并只写 `m_timeLabel`；禁止增加 `layoutSubviews` Hook，禁止调用 `setNeedsLayout/layoutIfNeeded` |
| 游戏选择 | `CMessageMgr AddEmoticonMsg:MsgWrap:` | 非游戏消息和关闭状态直接 `%orig` |
| 聊天记录显示修改 | `TextMessageCellView`、`AppMessageCellView`、`ImageMessageCellView`、`WCPayTransferMessageCellView` | 文字/应用/转账沿用参考插件确认的消息对象、setter 与节点刷新；图片使用当前聊天页缓存并覆盖图片 Cell、ViewModel、数据项和 `CMessageWrap` 精确读取入口 |
| 引用回复手势 | `CommonMessageCellView onShowMsgReplyMenuItem:` | 仅横向滑动结束且超过阈值时调用微信原生回复入口；手势关闭后移除 |
| 语音自动转文字 | `VoiceMessageCellView layoutSubviews/onVoiceTrans:` | 消息级记录完成、处理中和重试次数；同时检查本地翻译结果与加载视图；失败最多尝试 5 次，禁止空语音无限循环 |
| 红包详情 | `WCRedEnvelopesRedEnvelopesDetailViewController viewWillAppear:` | 金额单位为分；详情写 `m_receivedInfoLable`，`nickNameLabel` 只清理旧残留；不得追加原生领取状态造成重复 |
| 消息屏蔽 | `CMessageMgr AsyncOnAddMsg:MsgWrap:` | 只处理新收到的普通文字；关闭或不命中时完整执行 `%orig` |
| 长按菜单管理 | 各消息 Cell 的 `operationMenuItems` | 只管理已存在菜单项；关闭时恢复原始标题 |
| 群成员提醒 | `CContactMgr printContactImportantChangeData:oldContact:` | 原调用前后比较群成员列表，本地提醒不写回联系人 |
| 自动原图 | `MMAssetPickerController`、`MMImagePreviewBrowserController viewDidLoad` | 只调用已确认的 `setIsOriginSelected:` |
| 通知直达聊天 | `NotificationActionsMgr`、`MicroMessengerAppDelegate` 通知回调 | 只接管含有效会话字段 `u` 的通知，其他通知完整回退微信 |
| 钱包余额显示 | `TimeoutNumber updateNumber:/defaultNumber:`、`WCPayWalletEntryHeaderView` | 已确认参数为 `unsigned long long` 且单位为分；仅钱包头部替换后调用原 IMP，禁止恢复 `MMUILabel` 全局数字猜测 |
| 微信运动步数 | `WCDeviceStepObject`、`UploadDeviceStepReq`、`WCDataItem` | Getter/Setter 均使用当天配置值；关闭、未配置或跨日时返回原值；阶段递增只在读取时按固定时段计算，不创建定时器，18:30 达到当天目标 |
| 页面缩放 | `MMThemeManager`、`CLocalInfo`、`WKWebView`、`WAThemeProxy` | 只缩放 `#font_set` 的 `alllevel/chatLevel` 与网页文字，不修改窗口 transform，不按账号硬编码 |
| 好友数量显示 | `MMUILabel setText:` | 必须匹配“个朋友”等明确文案，禁止无条件全局替换 |
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
  - 分类和父功能折叠使用无动画 `reloadData` 并保持当前滚动位置。
  - 不再使用 `insertRows/deleteRows` 的 `UITableViewRowAnimationTop`，避免卡片瞬间跳到页面顶部。
  - 箭头跟随刷新后的状态重建，不做中间态旋转动画。
- “关于”最底部通过 `MMServiceCenter`、`CContactMgr getSelfContact` 和 `CContact userName` 显示当前用户 wxid，单击复制；获取失败时只显示“未获取”。
- 不要恢复整段 `reloadSections`、父行 reload 动画或 Top 插入/删除动画，否则会造成整张卡片跳动。

## 10. 已删除或明确不做

- 长截图功能已完全移除，不要恢复相关 Controller、菜单和渲染代码。
- Markdown 导出已移除。
- 全局文字替换已完全移除；`MMUILabel setText:` 只保留好友数量的受限文案匹配，不得扩展为通用替换入口。
- 多选批量保存文件附件不实现，只保存已下载图片。
- View 选择器不提供“复制 Hook”。
- 不使用全局手势启动调试悬浮窗。
- 聊天消息时间标签已于 2026-08-09 完整删除，包括 Hook、设置项、配置键和兼容性条目；重构完成前不要恢复。

## 11. 已知限制

- 微信私有类和 Selector 会随版本变化，必须依赖兼容性中心和真机日志确认。
- `WCPluginsMgr` 没有注销 API；动态快捷入口关闭或改名后，旧入口可能要重启微信才消失。
- 多开微信可能更改 Bundle ID、容器和运行环境；当前 plist 已包含 `com.tencent.xin`、`com.tencent.wx`、`com.tencent.qy.xin`。
- 本地 Windows 无法完整验证 Theos/iOS 私有 API 编译，推送后由云端构建。
- 调试日志默认开启；排查性能时可先关闭。

### 当前静态修复，待云端编译与真机验证

1. 最近已推送提交 `8bc650b`
   - 语音自动转文字加入完成、处理中和最多 5 次重试状态，避免空内容或识别失败时无限循环。
   - 聊天消息时间标签已完整删除。
   - 艾特/关键词边缘提示改用 `scrollToMessage:highlight:marginTop:animated:`。
   - 红包详情已改为写入 `m_receivedInfoLable`，金额按分换算。

2. 当前未提交修复
   - beta34 已按要求完整删除聊天搜索、关键词提醒和群聊艾特提醒，包括设置 Key、设置项、运行时处理、边缘提示 UI、搜索控制器 Hook 与兼容性登记；同时移除删除提醒模块后遗留的未使用 `NeoWCContactManager`，修复 Theos `-Werror,-Wunused-function` 构建失败。
   - 新增胶囊工具栏：隐藏底部整条模糊背景，保留微信原语音、输入、表情和更多控件，只在其背后按左右两组增加玻璃胶囊；效果与阴影配置和胶囊顶栏共用。beta27 进一步按抓取层级透明化宽语音按钮与语音转述中的白色 `UIImageView`，并为展开的表情/更多区域补充独立模糊背景；beta28 让右侧表情/更多胶囊保持固定高度，引用回复条增高时不再纵向拉伸；beta29 在回到前台和锁屏解锁后的 `DidBecomeActive` 阶段立即并延迟幂等重放顶栏与输入栏胶囊状态，覆盖微信稍后的背景 alpha 重置且不触发布局调用；beta30 将胶囊顶栏移动到“界面优化 → 聊天胶囊”，并为顶栏和工具栏增加共享的 20%–100% 模糊强度、0%–30% 系统背景染色强度与现有阴影配置；beta31 监听微信传入的“对方正在输入…”标题状态，昵称保持不变，仅在昵称右侧显示绿色三点呼吸提示，状态结束后自动移除；beta32 修复输入栏背景图片集合在 Xcode 16.4 下触发的 Objective-C 轻量泛型指针类型 `-Werror`；beta33 改为遍历活动 Window 控制器树恢复聊天胶囊，在应用激活和受保护数据恢复后分三次幂等重放顶栏、底栏与置顶玻璃，并直接监听导航栏 `MMUILabel` 的输入状态文本；beta34 仅修复底部工具栏：未展开的表情/更多区域完全隐藏模糊 View、清除 `MMInputToolView` 自身背景，并在聊天页布局后幂等恢复透明状态。
   - 胶囊顶栏的液态玻璃仅允许 iOS 26 原生 `UIGlassEffect`；低版本强制使用超薄玻璃，已移除 NeoWC 自研兼容液态叠层。
   - 设置首页头像改为 96 点圆角方形容器，并同步扩大昵称、wxid 间距和页眉高度，避免直接缩放微信内部头像 View 造成首帧裁切。
   - 所有持久多选设置均在列表显示“当前选择：…”并在操作表中勾选当前项。

3. 仍须保持的既有边界
   - 钱包只处理 `WCPayWalletEntryHeaderView` 内的 `TimeoutNumber`，金额单位为分。
   - 全局 `MMUILabel` 数字猜测保持删除，只保留通讯录好友数量的严格文案匹配。
   - 图片伪装只缓存当前聊天页，退出时清理；图片编辑快捷发送与微信官方转发继续隔离。
   - 防撤回气泡提示继续使用弱引用合并调度器，不恢复 `CommonMessageCellView layoutSubviews`。

### 参考插件分析索引

完整稳定结论见 `REFERENCE_PLUGIN_ANALYSIS.md`：

- 2DD 小丑助手：钱包金额参数、文字/应用/图片/转账本地显示修改。
- WeChatX / WeChatX(1)：朋友圈权限与精确时间、原生浮动菜单转发、全局去分割线、页面缩放、语音状态机。
- WCPulse 1.6-3：引用定位、红包详情、扫码来源与通话确认。
- WeChatEnhance：引用手势、消息屏蔽、菜单管理、群成员提醒、自动原图、通知直达和钱包局部修改。
- 存自拍：预览长按、原生菜单、`EmoticonUploadInfoObj` 自拍上传链。
- 微信广告：广告过滤、URL 改写、Web 调试、越狱检测与统计字段相关入口。

## 12. 下一轮真机验证顺序

1. 编译并安装 beta34，确认设置页、聊天页和运行时均不再出现搜索、关键词提醒或群聊艾特提醒。
2. 开启胶囊工具栏，验证文字输入、按住说话、表情、更多、发送按钮、键盘切换和多行输入全部保持微信原行为。
3. 分别验证超薄玻璃、iOS 26 原生液态玻璃、阴影开关、深色模式及关闭功能后的原样恢复。
4. 打开未领取、部分领取和已领完红包，确认详情单行完整显示且不重复原生“已领取”文字。
5. 用空语音、无法识别语音和正常语音测试自动转文字，确认失败最多尝试 5 次且聊天不卡死。
6. 验证微信运动各时间阶段、跨日重置及 18:30 达到当天目标。
7. 回归钱包余额、文字/引用应用/图片/转账显示修改及“仅当前页面本机显示”边界。
8. 回归防撤回气泡、图片编辑快捷发送、朋友圈转发和设置页无动画刷新。

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
继续维护 D:\Vibe\NeoWC。先完整阅读 D:\Vibe\NeoWC\HANDOFF.md，再检查 git status、最近提交和当前 diff；工作区中的所有现有修改都要保留，不得覆盖或回退。

最近已推送提交为 9baa029。当前未提交修改包含：微信运动改为分时段阶段递增并在 18:30 达到目标；聊天搜索、关键词提醒和群聊艾特提醒已完整删除；胶囊工具栏已加入但仍待 Theos 编译和真机验证。HANDOFF.md 已更新，必须保留这些修改。

参考插件的稳定结论见 D:\Vibe\NeoWC\REFERENCE_PLUGIN_ANALYSIS.md，原始反编译产物在 D:\Vibe\NeoWC\.codex-analysis，仅供本机分析且不得加入提交。后续遇到未还原、真机不生效或微信版本变化的功能时，应直接回到用户提供的参考插件 `dylib`/`deb` 和这些本地提取文件继续反编译学习，确认 Hook 注册、原方法参数类型、字段来源与替换函数调用顺序后再修改 NeoWC；不要仅根据功能名或字符串猜测私有 API。

必须保留防撤回气泡方案：禁止给 CommonMessageCellView 恢复 layoutSubviews Hook，禁止主动调用 setNeedsLayout/layoutIfNeeded，提示刷新必须弱引用且合并执行。保留图片编辑快捷发送与微信官方转发完全隔离的逻辑，保留设置页无动画 reloadData 与滚动位置保持方案。聊天消息时间标签已完整删除，不要恢复；不要恢复长截图、Markdown 导出或全局文字替换。

下一轮优先推送构建并真机验证红包未领取/部分领取/已领完三种状态、空语音重试上限、微信运动分阶段结果，以及已删除功能不再出现入口或运行时行为。

修改后先执行 git status --short、git diff --check、git diff --stat 和约束扫描。本机没有 Theos，无法本地完成 iOS 私有 API 编译。未经用户明确要求不要提交或推送；用户说“提交”表示提交并推送 main，推送后不要查询云端构建结果。项目版本为 0.1.2，远程为 ssh://git@ssh.github.com:443/qiu7c/NeoWC.git。
```
