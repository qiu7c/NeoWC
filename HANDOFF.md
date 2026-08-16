# NeoWC 项目交接文档

更新时间：2026-08-16
项目版本：0.1.2
仓库：`git@github.com:qiu7c/NeoWC.git`
主分支：`main`

## 1. 当前工作区状态

- 最近本地提交：`6c19524 Expand NeoWC authorization and chat controls`；当前本地 `main` 尚领先 `origin/main`。
- 当前未提交修改包含：完整删除有严重兼容问题的胶囊工具栏；扩展“广告精简”；完整删除朋友圈转发按钮长按发送指定好友，只保留普通朋友圈转发；设置首页个人信息区改为居中头像、昵称、wxid 和授权状态，仅作者 wxid 命中管理员哈希时将真实昵称显示为金色并标注“作者”。
- 开始新工作前仍须重新检查 `git status`、最近提交和当前 diff。
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
| `Sources/NeoWCInterfaceTweaks.m` | 输入栏圆角、免打扰图标隐藏与原状态恢复 |
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
- 朋友圈转发：快捷评论开启时独立按钮，关闭时加入微信原操作菜单；仅保留短按进入朋友圈发布页
- 长按朋友圈头像，将微信原“设置权限/投诉”菜单替换为 4 个原生权限快捷项和投诉
- 朋友圈显示精确发布时间，可展开设置 `yyyy-MM-dd HH:mm:ss` 等自定义格式
- 自定义微信运动步数，同时覆盖设备对象与上传请求的三个精确步数字段
- 钱包余额本地显示：设置页只提供开关，余额必须在钱包页长按入口或余额数字设置，仅替换本机界面文字
- 好友数量本地显示：仅替换“个朋友”等明确好友数量文案
- 广告精简：朋友圈、视频号、广告推送与小程序启动广告

### 界面优化

- 胶囊顶栏：隐藏整条聊天顶栏背景，左右保留独立玻璃胶囊
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
| 输入框滑动 | `MMGrowTextView didMoveToWindow` | 手势只安装一次，`cancelsTouchesInView=NO` |
| 免打扰图标 | `UIImageView setAccessibilityLabel:/didMoveToWindow/setHidden:` | 仅处理标签严格等于“免打扰”的已管理图片 |
| 多选导出 | `BaseMsgContentViewController`、`MMScrollActionSheet` | 只在多选“更多”菜单构建期间插入项目 |
| 朋友圈 | `WCTimeLineCellView`、`WCTimeLineOperateButtonView` | 所有逻辑必须受开关控制 |
| 朋友圈转发 | `WCTimeLineCellView`、`WCOperateFloatView` | 只保留短按进入朋友圈发布页；长按选择好友、私聊发送及其联系人选择/运行时会话已完整删除；图片编辑快捷发送会话保持隔离 |
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
| 广告精简 | `BrandTLExptConfig`、`BSTLExptConfig`、`BrandTimelineMsgMgr`、`MagicAdPushMgrService`、`WAAppTaskSplashADConfig` 等 | 所有 Hook 受原 `NeoWCAdBlockerKey` 控制，关闭状态返回微信原值；不复制参考插件的关注公众号限制 |

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
   - beta35 按要求完整删除胶囊工具栏的 Key、默认值、设置项、UI 实现、生命周期重放和兼容性登记；胶囊顶栏与普通输入栏圆角保持独立可用。
   - beta35 扩展原 `NeoWCAdBlockerKey` 为“广告精简”，覆盖朋友圈广告配置/卡片、视频号广告开关、广告推送、小程序启动广告及广告评论元数据；没有加入参考插件的关注公众号限制。
   - beta35 曾加入朋友圈转发长按选择好友，已在 beta47 按要求完整删除；短按原朋友圈转发行为不变。
   - beta36 按 `storage.dylib` 的真实调用链内置插件管理：工程提供兼容的 `WCPluginModel` / `WCPluginsMgr` 注册接口，在 `MoreViewController addFunctionSection` 完成后向第 3 个原生 section 插入唯一“插件”行，并通过 `CAppViewControllerManager` 当前导航控制器打开管理页。管理页保留参考插件的分类增删改、插件改名/版本、收纳恢复、排序、分页、顶部文字/图标/圆角、入口图标和清空配置；持久化沿用 `WCPluginsMgr.*` Key。旧的标题过滤式“插件显示管理”和 `NeoWCPluginShortcuts` 多入口注册已完整删除，NeoWC 设置只作为管理器中的单一 Controller 项注册。
   - 胶囊顶栏的液态玻璃仅允许 iOS 26 原生 `UIGlassEffect`；低版本强制使用超薄玻璃，已移除 NeoWC 自研兼容液态叠层。
   - 设置首页头像改为 96 点圆角方形容器，并同步扩大昵称、wxid 间距和页眉高度，避免直接缩放微信内部头像 View 造成首帧裁切。
   - 所有持久多选设置均在列表显示“当前选择：…”并在操作表中勾选当前项。
   - beta39 将原引用左滑升级为“消息手势”：左滑、双击、三击均可分别配置自己和对方消息，动作包含不设置、引用、撤回、复制、删除、复读；对方消息在设置和运行时两层禁止撤回。左滑默认保留引用并支持 36–100 点触发距离，双击和三击默认不设置，避免默认抢占微信原生行为。引用、撤回、复制、删除只调用参考二进制已确认的 `onShowMsgReplyMenuItem:`、`onRevokeMsg:`、`onCopy:`、`onDelete:` / `onDeleteMessage:`，调用前仍检查 `respondsToSelector:`；复读不依赖 WeChatX 自定义的 `wx_repeatLongPressPlusOne:`，只对普通文字使用消息管理器发送，不强制复读媒体消息。
   - beta40 依据 WeChatX 二进制中的 `ForwardMsgUtil canBeForwardWithMsg:` 与 `ForwardMessageLogicController forwardNoConfirmForMsgList:toContacts:` 完善复读：直接把原 `CMessageWrap` 交给微信官方无确认转发引擎并发送回当前会话，覆盖微信允许转发的文字、图片、链接/小程序、文件、视频和表情等类型；仅当官方转发入口不可用时对普通文字使用 `CMessageMgr AddMsg:MsgWrap:` 兜底，避免自行拼接媒体 XML 或错误复用附件路径。
   - beta41 完整核对 WeChatX 的语音复读分支后补齐语音：语音消息不走普通转发，而是复制原 `CMessageWrap`、清空本地/服务端 ID、重新绑定当前发送者与会话并设置语音转发标记；随后通过 `CMessageMgr getVoicePath` / `getPathOfAudio:` 复制语音文件（复制失败时以 `SaveMesVoice:MsgWrap:` 保存数据），最后交给 `AudioSender ResendVoiceMsg:MsgWrap:`，必要时由 `uploaderForMsgWrap:` 取得上传器后重发。所有私有入口均先检查运行时能力，未找到本地语音文件时拒绝生成空消息。
   - beta42 完善 wxid 授权管理：普通检测继续严格按 `blacklisted` 优先、仅 `authorized=true && blacklisted=false` 放行；管理员入口只以当前 wxid 的 SHA-256 与内置管理员哈希比较。管理页以“已授权 / 黑名单”双列表展示，两个列表统一实时搜索和手动刷新；新增黑名单列表与解除黑名单接口，添加、删除、拉黑、解除后自动刷新两边，并补齐管理员自删/自拉黑保护、二次确认、HTTP 405 与超时状态。管理员密钥只保存在管理控制器内存中，退出页面即清除。
   - beta43 将插件管理改为真正的全屏 push 页面：入栈前使用 `hidesBottomBarWhenPushed` 隐藏微信底部 TabBar，返回后交由 UIKit 自动恢复；保留居中头像、标题/副标题、分类切换器、设置入口与插件卡片列表，版本号置于行尾，原有排序、收纳和信息编辑逻辑保留。NeoWC 搜索激活态的导航区、搜索框与内容页统一使用系统 grouped 背景，去除顶部白块与正文灰底的割裂。
   - beta44 消息手势新增独立的“右滑 · 自己 / 右滑 · 对方”动作配置，与左滑共享触发距离、阻尼、震动和回弹，可选引用、复制、删除、复读，自己消息额外支持撤回。新增键默认为“不设置”，不改变旧用户现有左滑行为。
   - beta45 授权请求不再阻塞 NeoWC 设置页进入：本地已授权且当前 wxid 的 SHA-256 与缓存匹配时，先正常展示功能并在后台静默刷新，加载期不会暂时收起功能；首次、旧缓存或本地未授权时先完成页面 push，再显示小型“授权验证”弹窗。服务端返回未授权、拉黑或请求异常后才更新本地状态并停用核心功能；永久黑名单启动拦截保持不变。
   - beta46 消息手势的左滑、右滑、双击和三击共八个自己/对方配置项，统一在标题下方以小字显示“当前状态：…”；选择动作后随设置列表刷新立即更新，不再在行尾重复显示。
   - beta47 完整删除朋友圈转发按钮长按发送指定好友：移除联系人选择控制器、长按手势、好友消息组装、转发会话和两个运行时处理方法，只保留短按进入朋友圈发布页。设置首页个人信息区改为居中圆角头像、真实昵称、wxid 和“已授权”；仅当前 wxid 命中管理员哈希时把真实昵称显示为金色并追加“作者”，不写死作者昵称。
   - beta48 为永久本地黑名单增加受控恢复：启动、完成启动或重新激活时最多每 5 分钟后台复查一次普通授权接口；只有合法 200/403 响应明确返回 `blacklisted=false` 才清除本地永久标记并关闭限制弹窗，断网、超时、500 和格式异常均保持锁定。解除后仍按 `authorized` 决定是否开放核心功能。
   - beta49 调整设置入口授权体验：点击 NeoWC 先完成页面入栈，再延迟弹出无按钮的“首次初始化验证”弹窗；弹窗仅在当前 wxid 尚无任何完成态验证记录时出现，并由请求完成自动关闭。已验证过的同一 wxid 后续进入只后台静默刷新，失败或未授权状态由页面内状态行展示，不再重复模态阻塞。
   - beta50 明确插件管理页列表卡片层级：插件名称、版本、箭头或开关所在区域使用 `systemBackgroundColor` 连成一张圆角分组卡片，首尾行分别裁切连续圆角，选中态使用系统填充色；继续保持无分割线并自动适配深色模式。

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

1. 编译并安装 beta36，确认设置页不再出现胶囊工具栏，聊天底部工具栏完全使用微信原实现。
2. 开关“广告精简”，分别验证朋友圈、视频号、广告推送和小程序启动广告，关闭后确认微信原行为恢复。
3. 短按朋友圈转发确认原朋友圈发布页不变；长按确认不再触发好友选择或私聊发送。
4. 分别验证胶囊顶栏的超薄玻璃、iOS 26 原生液态玻璃、阴影开关、深色模式及关闭功能后的原样恢复。
5. 打开未领取、部分领取和已领完红包，确认详情单行完整显示且不重复原生“已领取”文字。
6. 用空语音、无法识别语音和正常语音测试自动转文字，确认失败最多尝试 5 次且聊天不卡死。
7. 验证微信运动各时间阶段、跨日重置及 18:30 达到当天目标。
8. 回归钱包余额、文字/引用应用/图片/转账显示修改及“仅当前页面本机显示”边界。
9. 回归防撤回气泡、图片编辑快捷发送和设置页无动画刷新。
10. 在“我”页确认只出现一个“插件”入口；验证 Controller 与 Switch 注册、默认“美化/功能/定制”分类、分类增删改、改名/版本、收纳恢复、拖动及序号排序、分页、顶部设置和清空配置。若设备仍安装原 `storage.dylib`，必须先移除，避免同名 `WCPluginsMgr` / `WCPluginsViewController` Runtime 类冲突。
11. 开启“消息手势”，分别用自己和对方的文字、图片、语音消息验证左滑、双击、三击；确认对方撤回不可选，删除/撤回仍走微信确认流程，文字和微信允许转发的媒体可复读，语音复读会生成一条新的可播放语音且不会改动原消息。
12. 授权回归：分别用已授权、未授权、黑名单和断网账号进入设置页，确认仅服务端明确授权且未拉黑时显示核心功能。管理员进入“授权管理”后输入临时密钥，验证双列表加载、切换、实时搜索和刷新；依次添加测试 wxid、删除授权、重新添加并拉黑、切换黑名单后解除，确认每步均有二次确认且成功后两个列表和总数一起更新；再用 401/403/404/405/500 或超时响应验证对应提示，并确认当前管理员行不可删除或拉黑。

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

最近本地提交为 6c19524，当前本地 main 尚领先 origin/main。当前未提交修改包含：胶囊工具栏已完整删除；广告精简已扩展；朋友圈转发按钮长按发送好友已完整删除，只保留短按发布页；`storage.dylib` 插件管理逻辑已内置并替代旧插件隐藏/多快捷入口；设置首页个人信息区已加入授权状态，并仅对作者 wxid 的真实昵称显示金色“作者”标识。HANDOFF.md 已更新，必须保留这些修改。

参考插件的稳定结论见 D:\Vibe\NeoWC\REFERENCE_PLUGIN_ANALYSIS.md，原始反编译产物在 D:\Vibe\NeoWC\.codex-analysis，仅供本机分析且不得加入提交。后续遇到未还原、真机不生效或微信版本变化的功能时，应直接回到用户提供的参考插件 `dylib`/`deb` 和这些本地提取文件继续反编译学习，确认 Hook 注册、原方法参数类型、字段来源与替换函数调用顺序后再修改 NeoWC；不要仅根据功能名或字符串猜测私有 API。

必须保留防撤回气泡方案：禁止给 CommonMessageCellView 恢复 layoutSubviews Hook，禁止主动调用 setNeedsLayout/layoutIfNeeded，提示刷新必须弱引用且合并执行。保留图片编辑快捷发送与微信官方转发完全隔离的逻辑，保留设置页无动画 reloadData 与滚动位置保持方案。聊天消息时间标签已完整删除，不要恢复；不要恢复长截图、Markdown 导出或全局文字替换。

下一轮优先推送构建并真机验证红包未领取/部分领取/已领完三种状态、空语音重试上限、微信运动分阶段结果，以及已删除功能不再出现入口或运行时行为。

修改后先执行 git status --short、git diff --check、git diff --stat 和约束扫描。本机没有 Theos，无法本地完成 iOS 私有 API 编译。未经用户明确要求不要提交或推送；用户说“提交”表示提交并推送 main，推送后不要查询云端构建结果。项目版本为 0.1.2，远程为 ssh://git@ssh.github.com:443/qiu7c/NeoWC.git。
```
