# NeoWC 参考插件分析

更新时间：2026-08-09

本文只记录已经从二进制、Selector 交叉引用或真机表现中确认的结论。原始 dylib、deb、反汇编文本和分析脚本位于本机 `.codex-analysis/`，该目录必须保持 Git 忽略，不得加入提交。

## 1. 2DD 小丑助手

参考文件：

- `2DD小丑助手-arm64.deb`
- 本地提取：`.codex-analysis/2dd-joker/`

已确认结论：

- `TimeoutNumber updateNumber:` 的原参数是 `unsigned long long`，钱包金额单位为分。替换后必须把整数金额交给原 IMP，不能改成字符串，也不能全局扫描 `MMUILabel`。
- 钱包余额修改只应限定在 `WCPayWalletEntryHeaderView` 的 `TimeoutNumber`，否则会误改插件版本号和其他数字。
- `TextMessageCellView`、`AppMessageCellView`、`WCPayTransferMessageCellView` 的“小丑”入口都从当前 Cell/ViewModel 取得消息对象，写对应 setter 后调用消息节点刷新入口。
- 转账涉及 `m_nsFeeDesc`、`m_receiverDesc`、`m_senderDesc`，显示层还依赖当前微信版本的节点刷新，不能通过全局文字替换模拟。
- 图片伪装需要同时覆盖图片 Cell、ViewModel、`MMImgDataItem_Message` 和 `CMessageWrap` 的精确图片读取入口，并把修改限制在当前聊天页面。

## 2. WeChatX

参考文件：

- `WeChatX.dylib`
- `WeChatX(1).dylib`
- 本地切片：`.codex-analysis/WeChatX-old.arm64.dylib`、`.codex-analysis/WeChatX-new.arm64.dylib`

已确认结论：

- 朋友圈精确时间从 `WCTimeLineCellView` 的 `m_dataItem.createtime` 读取 Unix 秒，只更新原生 `m_timeLabel`。
- 朋友圈头像长按权限使用微信原生 `editBlackList` 流程及 `opAllPermission`、`opSocialBlackPermission`、`opOutsider:`、`opWCBlacklist:`。
- 朋友圈转发复用原生浮动菜单结构、分隔视图和动画；快捷评论开启时可在评论按钮旁增加独立转发按钮。
- 全局去分割线通过宽泛的 `UIView layoutSubviews` 识别细线视图并保存原始 hidden 状态，朋友圈也在处理范围内。
- 页面缩放修改主题字体规则与网页文字比例，不应缩放整个窗口 transform，也没有按账号硬编码。
- 图片伪装、微信运动增强和聊天搜索均通过微信已有对象及请求字段实现，不依赖全局标签扫描。
- 语音自动转文字在消息/ViewModel 上记录“完成”“处理中”和重试次数，检查 `hasLocalTranslateResult` 及翻译加载/结果视图，失败重试上限为 5。
- 聊天搜索使用独立 `MsgSearchHelper initWithContentsController:`，配置 `m_sessionId`、`m_searchSessionId`、`m_delegate`、`m_searchParentVC`、场景、按名称/时间搜索和侧滑取消。

## 3. WCPulse 1.6-3

参考文件：

- `WCPulse_1.6-3-arm.deb`
- 本地提取：`.codex-analysis/wcpulse-deb/`
- 重点反汇编：`wcpulse-at-keyword.txt`、`wcpulse-open-chat-search.txt`、`wcpulse-red-detail.txt`、`wcpulse-refer-detail.txt`、`wcpulse-scan-detail.txt`、`wcpulse-call-confirm.txt`

已确认结论：

- 艾特与关键词边缘提示定位调用 `scrollToMessage:highlight:marginTop:animated:`，`marginTop` 为屏幕高度三分之一；关键词命中后可通过 `getChatCellWithMsg:` 和 `highLightSearchKeyWords:` 高亮。
- 引用位置跳转与边缘提示是两条不同路径，不能统一强行调用 `returnToOriginalMsg:`。
- 聊天搜索入口先让聊天控制器执行 `initMsgSearchHelper:`，再读取其原生 `m_oMsgSearchHelper`；打开路径优先使用 `pushSearchControllerWithCompletion:`，兼容分支调用 `onSearchItem`。该实现未调用 `getSearcherViewController` 或自行 `presentViewController:`。
- 聊天消息时间实现位于 WCPulse 的消息 Cell 运行时配置链。它缓存 `runtimeTimeLabelConfigReady`、开关、字号、粗体及明暗颜色，读取 `cell.viewModel.messageWrap.m_uiCreateTime`，通过 `wcpulse_formatTimeWithStrftime:` 生成文字，并复用 tag 为 `10086` 的标签。
- 该实现只处理 `TextMessageSubViewModel`，要求 `startHeight == 0`，通过 `getHeadImageView` 取得可见头像；若头像或 Cell 的 `contextString` 是非空纯数字则跳过。标签放在独立容器内并复用，标签高度为 `max(12, fontSize * 1.5)`、宽度至少 50 点，横向以头像中心对齐，纵向放在头像底部附近。
- WCPulse 二进制中确认到的是“头像下方时间”，没有确认到 NeoWC 旧版的“气泡旁时间”。因此 NeoWC 恢复时，头像模式按上述真实链路收敛；气泡模式仍是独立适配，并在可用横向空间不足时隐藏，不能宣称为 WCPulse 原实现。
- 红包详情 Hook 是 `WCRedEnvelopesRedEnvelopesDetailViewController viewWillAppear:`。数据链为 `m_delegate` -> `m_data` -> `m_oWCRedEnvelopesDetailInfo`。
- 红包金额字段 `m_lTotalAmount`、`m_lRecAmount` 单位为分；数量字段为 `m_lTotalNum`、`m_lRecNum`。
- `nickNameLabel` 仅用于清理旧的 `\n(¥` 残留；详情应写入 `m_receivedInfoLable` 的 attributedText。默认格式为“总金额、已领个数、剩余个数、剩余金额”，不能把原生领取状态再次当祝福语追加。
- 其他已确认入口包括伪装扫码来源、聊天搜索按钮、群聊艾特提示、关键词提示、红包详情和通话二次确认。

## 4. WeChatEnhance

参考文件：

- `WeChatEnhance.dylib`
- 本地报告：`.codex-analysis/wechatenhance_report.json`

已观察并用于功能对照：

- 引用回复手势及其配置。
- 普通消息屏蔽、长按菜单管理。
- 群成员进群/退群提醒与关键词提醒。
- 自动原图、通知点击直达对应聊天。
- 钱包余额局部修改。

这些功能只能按已确认的类和 Selector 分项迁移。报告中的功能名不等于调用链已经完整还原，未确认部分仍需继续反编译或真机日志验证。

## 5. 存自拍

参考文件：

- `存自拍.dylib`
- 本地文件：`.codex-analysis/save-selfie.dylib`、`save-selfie-disasm.txt`、`selfie-helper-disasm.txt`

已确认结论：

- `EmoticonPreviewWindowViewController` 通过 `popoverView addLongPressTarget:action:` 接入预览长按。
- 普通和应用表情 Cell 通过原生菜单增加“存入自拍”，使用 `MMMenuItem initWithTitle:svgName:target:action:` 或兼容初始化器。
- 不能走普通“保存表情”流程。数据必须构造成 `EmoticonUploadInfoObj`，设置 `setUploadImgMd5:`、`setIsSelfie:YES`、`setSelfieScene:`、`setIsUploadWxam:`、`setSelfieEnterTime:`、`setLensId:`。
- 图片数据先经 `saveImgDataToTempPathWithImgData:`，最后交给表情添加逻辑的 `handleEmoticonUploadInfo:source:`。
- 已是自拍表情或未下载完成的内容必须跳过。

## 6. 微信广告

参考文件：

- `微信广告.dylib`
- `com.ylr.wcsurfacetrim_1.0_iphoneos-arm64.deb`
- `storage.dylib`
- 本地文件：`.codex-analysis/wechat-ad.dylib`、`wechat-ad-hooks.txt`、`wechat-ad-core-disasm.txt`、`wechat-ad-url-disasm.txt`、`wechat-ad-stats-disasm.txt`

分析中观察到的功能面：

- 朋友圈/小程序启动广告过滤。
- URL 改写和 Web 调试开关。
- 越狱检测绕过。
- 部分统计字段改写。

`WCSurfaceTrim` 的 Hook 注册进一步确认了广告精简入口：`BrandTLExptConfig` / `BSTLExptConfig isExptNotShowAd`、朋友圈广告卡片管理器、三个 Timeline Flutter 控制器的 `enableAd`、`MagicAdPushMgrService`、小程序启动广告处理器及 `WCUserComment` 的广告标记。`storage.dylib` 主要提供 `WCPluginsMgr` 插件注册基础设施，不是广告过滤实现。参考包包含的关注公众号限制不属于广告精简，禁止迁入 NeoWC。

`storage.dylib` 的插件管理链路已经进一步确认：构造器延迟等待 `MoreViewController`，替换 `addFunctionSection` 后先调用原实现，再从 `m_tableViewMgr` 取得第 3 个 section，使用 `WCTableViewCellManager normalCellForSel:target:leftImage:title:WithDisclosureIndicator:` 插入唯一“插件”行；点击后新建 `WCPluginsViewController`，通过 `CAppViewControllerManager getCurrentNavigationController` 和 `PushViewController:animated:` 打开。注册接口为 `WCPluginsMgr sharedInstance`、`registerControllerWithTitle:version:controller:` 与 `registerSwitchWithTitle:key:`，模型字段为 `isController/title/version/controller/key`。配置 Key 完整集合为 `WCPluginsMgr.IconStyle`、`PluginCategories`、`CustomCategories`、`PluginDisplayNames`、`PluginDisplayVersions`、`PluginOrderIndexes`、`HiddenPlugins`、`PluginsPerPage`、`HeaderTitle`、`HeaderSubtitle`、`HeaderIconImageData`、`HeaderIconCornerRadius`。

NeoWC 当前把这些入口归入“广告精简”，但必须保持开关关闭时完整返回微信原逻辑。URL、越狱与统计相关 Hook 风险和版本敏感度较高，不能从字符串命中推断调用签名；后续修改前必须重新确认原方法参数与返回类型。

## 7. WeChatX 全局头像圆角

对 `WeChatX-new.arm64.dylib` 的 `WXInitRoundAvatar`（`0x2addf8`）和旧版同名初始化器（`0x27c77c`）反编译后确认：

- 目标类不是全局 `UIImageView`，而是微信头像基类 `MMHeadImageView` 与占位头像类 `FakeHeadImageView`。
- `MMHeadImageView` Hook `initWithUsrName:headImgUrl:bAutoUpdate:bRoundCorner:`、`layoutSubviews`、`setConerSize:`。
- `FakeHeadImageView` Hook `initWithRoundCorner:`、`layoutSubviews`、`setConerSize:`。
- 布局阶段若对象响应 `headImageView`，优先修改内部真实头像 View；否则修改容器本身。
- 圆角半径算法为 `min(width, height) × 0.5 × ratio`，其中 `ratio` 来自 0–100 的 `wkkAvatarRadius` 并限制在有效范围内。
- `setConerSize:` 的输入也按相同比例换算。参考插件另有浅色/深色描边与描边宽度逻辑，但它与“全局头像圆角”不是同一必要能力，NeoWC 暂不迁入。

因此实现全局头像圆角时只应覆盖上述两个头像类，不得扫描普通图片视图，避免把聊天图片、二维码、表情或功能图标裁圆。

## 8. 使用原则

- 后续维护遇到尚未还原、真机不生效或微信版本变化的功能时，可以并且应当回到上述参考插件的原始 `dylib`/`deb` 及 `.codex-analysis/` 中的提取文件继续反编译学习；先补齐证据，再修改 NeoWC。
- 先从 Hook 注册表确定类、Selector 和原方法类型，再看替换函数调用顺序。
- Objective-C 对象返回、标量返回和结构体参数必须使用类型匹配的 `objc_msgSend`。
- 不用全局 UILabel/UIView 文本猜测代替已知私有 API。
- 参考插件的视觉结果只能帮助定位，不能替代反编译证据。
- 二进制与临时分析产物不得提交；稳定结论更新到本文和 `HANDOFF.md`。
