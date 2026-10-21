// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'OBIC';

  @override
  String get tagline => '在华社交与日常生活服务';

  @override
  String get tabHome => '首页';

  @override
  String get tabServices => '服务';

  @override
  String get tabMoments => '动态';

  @override
  String get tabDiscover => '发现';

  @override
  String get tabMessages => '消息';

  @override
  String get tabOrders => '订单';

  @override
  String get tabMe => '我的';

  @override
  String get tabContacts => '通讯录';

  @override
  String get homeGreeting => '社交与在华日常';

  @override
  String get homeHint => '聊天、动态、好友与通话——还可订餐、订酒店、问诊、出行等。';

  @override
  String get servicesTitle => '全部服务';

  @override
  String get servicesHint => '可自由浏览目录。提交请求需登录。';

  @override
  String get messagesTitle => '消息';

  @override
  String get messagesHint => '客服聊天、好友与通知。';

  @override
  String get messagesEmpty => '暂无会话。请联系客服开始聊天。';

  @override
  String get messagesEmptyGuest => '登录后查看聊天并与员工沟通。';

  @override
  String get messagesNoPreview => '暂无消息';

  @override
  String get chatSupportTitle => 'OBIC 客服';

  @override
  String get chatTalkToStaff => '转人工客服';

  @override
  String get chatTalkToStaffDone => '客服很快会在此回复';

  @override
  String get chatTalkToStaffBusy => '正在接通…';

  @override
  String get chatHandoffTitle => '转接人工客服';

  @override
  String get chatHandoffHint => '请选择分公司与业务类型，以便分配到正确的柜台。';

  @override
  String get chatHandoffBranch => '分公司';

  @override
  String get chatHandoffService => '业务 / 柜台';

  @override
  String get chatHandoffOrderRef => '订单 / 案件编号（可选）';

  @override
  String get chatHandoffOrderRefHint => '例如签证或订单号';

  @override
  String get chatHandoffNote => '备注（可选）';

  @override
  String get chatHandoffNoteHint => '给客服的简短说明';

  @override
  String get chatHandoffSubmit => '立即接通';

  @override
  String get chatHandoffCancel => '取消';

  @override
  String get chatHandoffUseNearest => '使用最近的分公司';

  @override
  String get chatAddPeopleTitle => '添加成员';

  @override
  String get chatAddPeopleHint => '邀请同分公司其他柜台员工加入此会话';

  @override
  String get chatAddPeopleEmpty => '没有可添加的其他柜台员工';

  @override
  String get chatAddPeopleSubmit => '添加所选';

  @override
  String get chatHandoffSummaryTitle => '给秘书的摘要';

  @override
  String get chatInputHint => '输入消息…';

  @override
  String get attachImage => '添加图片';

  @override
  String get attachFile => '添加文件';

  @override
  String get attachClear => '清除附件';

  @override
  String get chatHoldToTalk => '按住说话';

  @override
  String get chatReleaseToSend => '松开发送';

  @override
  String get chatSlideToCancel => '松开取消';

  @override
  String get chatVoiceTooShort => '语音太短';

  @override
  String get chatMicPermissionDenied => '发送语音需要麦克风权限';

  @override
  String get chatVoiceMode => '语音消息';

  @override
  String get chatVideoTooLarge => '视频过大（上限 80MB）。请缩短后再试。';

  @override
  String get chatVideoLargeWarning => '视频超过 12MB — 试用环境重新部署后可能丢失（待接 S3）。仍将发送。';

  @override
  String get chatVideoPickFailed => '无法读取该视频，请换一个。';

  @override
  String get mediaAlbum => '相册';

  @override
  String get mediaCamera => '拍摄';

  @override
  String get mediaVideo => '视频';

  @override
  String get mediaVideoTitle => '视频';

  @override
  String get mediaFromAlbum => '从相册选择';

  @override
  String get mediaRecordVideo => '拍摄视频';

  @override
  String get mediaCameraPermissionDenied => '需要相机权限。请在设置中开启。';

  @override
  String get mediaPhotosPermissionDenied => '需要相册权限。请在设置中开启。';

  @override
  String get mediaPickFailed => '无法打开相机或相册，请重试。';

  @override
  String get momentsAddMedia => '添加';

  @override
  String get momentsTextOnly => '文字';

  @override
  String get momentsTakePhoto => '拍照';

  @override
  String get chatImageLoadFailed => '无法加载此图片。请检查网络后重试。';

  @override
  String get chatPreviewVoice => '[语音]';

  @override
  String get chatPreviewVideo => '[视频]';

  @override
  String get chatPreviewImage => '[图片]';

  @override
  String get chatPreviewFile => '[文件]';

  @override
  String get momentsTitle => '动态';

  @override
  String get momentsEmpty => '暂无动态 — 来发布第一条吧。';

  @override
  String get momentsCreate => '发布动态';

  @override
  String get momentsHint => '分享你的想法…';

  @override
  String get momentsPost => '发布';

  @override
  String get momentsAnon => '用户';

  @override
  String get momentsDelete => '删除';

  @override
  String get momentsDeleteConfirm => '删除这条朋友圈？好友将无法再看到。';

  @override
  String get momentsDeleted => '已删除';

  @override
  String get momentsPrivacyWhoCanSee => '谁可以看';

  @override
  String get momentsPrivacyFriends => '全部好友';

  @override
  String get momentsPrivacyFriendsHint => '你的好友可见';

  @override
  String get momentsPrivacyPrivate => '私密';

  @override
  String get momentsPrivacyPrivateHint => '仅自己可见';

  @override
  String get momentsPrivacyPartial => '部分可见';

  @override
  String get momentsPrivacyPartialHint => '选中的好友可见';

  @override
  String momentsPrivacyPartialSelected(int n) {
    return '$n 位好友';
  }

  @override
  String get momentsPrivacyExclude => '不给谁看';

  @override
  String get momentsPrivacyExcludeHint => '选中的好友不可见';

  @override
  String momentsPrivacyExcludeSelected(int n) {
    return '不给 $n 人看';
  }

  @override
  String get momentsPrivacyNeedFriends => '请至少选择一位好友';

  @override
  String get momentsPrivacyDone => '完成';

  @override
  String get momentsOfficial => '官方';

  @override
  String get momentsAddPhotos => '照片';

  @override
  String get momentsAddVideos => '视频';

  @override
  String get momentsAddFiles => '文件';

  @override
  String get momentsChangeAvatar => '更换头像';

  @override
  String get momentsStaff => '员工';

  @override
  String get momentsJustNow => '刚刚';

  @override
  String momentsMinutesAgo(Object n) {
    return '$n 分钟前';
  }

  @override
  String momentsHoursAgo(Object n) {
    return '$n 小时前';
  }

  @override
  String momentsDaysAgo(Object n) {
    return '$n 天前';
  }

  @override
  String get momentsLike => '点赞';

  @override
  String get momentsUnlike => '取消赞';

  @override
  String get momentsComment => '评论';

  @override
  String get momentsCommentHint => '写评论…';

  @override
  String get momentsReplyHint => '写回复…';

  @override
  String get momentsCommentAddPhoto => '添加图片';

  @override
  String get momentsCommentTakePhoto => '拍照';

  @override
  String get momentsCommentSendFailed => '评论发送失败';

  @override
  String get momentsCommentDelete => '删除';

  @override
  String get momentsCommentDeleteConfirm => '删除这条评论？';

  @override
  String get momentsCommentDeleted => '已删除评论';

  @override
  String get momentsReply => '回复';

  @override
  String momentsReplyTo(Object name) {
    return '回复 $name';
  }

  @override
  String get momentsRepliedTo => '回复了';

  @override
  String get momentsFavorite => '收藏';

  @override
  String get momentsFavorited => '已收藏';

  @override
  String get momentsReport => '举报';

  @override
  String get momentsReported => '已举报 — 管理员将审核';

  @override
  String get momentsDownload => '保存到相册';

  @override
  String get momentsSaved => '已保存到相册';

  @override
  String get momentsSaveFailed => '保存失败';

  @override
  String get momentsFileSaved => '文件已保存';

  @override
  String get momentsNoLikes => '快来第一个点赞';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsEmpty => '已全部读完。';

  @override
  String get notificationsMarkAll => '全部标为已读';

  @override
  String get friendsTitle => '好友';

  @override
  String get friendsList => '我的好友';

  @override
  String get friendsEmpty => '暂无好友 — 用手机号或 ID 搜索。';

  @override
  String get friendsAdd => '添加好友';

  @override
  String get friendsSearchHint => '手机号或 OBIC ID';

  @override
  String get friendsIncoming => '好友请求';

  @override
  String get friendsAccept => '接受';

  @override
  String get friendsReject => '拒绝';

  @override
  String get friendsRequestSent => '好友请求已发送';

  @override
  String get friendsNewFriends => '新的朋友';

  @override
  String get friendsNewFriendsEmpty => '暂无待处理的好友请求。';

  @override
  String get friendsOutgoing => '已发送';

  @override
  String get friendsWaiting => '等待验证';

  @override
  String get friendsAcceptedToast => '已成为好友';

  @override
  String get friendsSendRequestTitle => '好友申请';

  @override
  String get friendsVerificationHint => '打个招呼吧 — 可选';

  @override
  String get friendsSend => '发送';

  @override
  String get friendsCancel => '取消';

  @override
  String get friendsAlreadyFriends => '已添加';

  @override
  String friendsRequestAlert(String name) {
    return '$name请求添加你为好友';
  }

  @override
  String get friendsViewRequests => '查看';

  @override
  String get friendsEmployeeNote => '员工无法添加客户为好友。';

  @override
  String get friendsByPhone => '搜索';

  @override
  String get friendsByQr => '二维码';

  @override
  String get friendsMyQr => '我的二维码';

  @override
  String get friendsScanQr => '扫描二维码';

  @override
  String get friendsQrHint => '请好友扫描你的码，或扫描对方的码添加。';

  @override
  String get friendsQrPayloadHint => '或在此粘贴 OBIC 二维码内容';

  @override
  String get friendsQrInvalid => '无效的二维码';

  @override
  String get profileObicId => 'OBIC 号';

  @override
  String get profileObicIdHint => '6–20 位，字母开头';

  @override
  String get profileObicIdFirstHint => '设置 OBIC 号方便好友搜索。每年可修改一次。';

  @override
  String get profileObicIdYearHint => 'OBIC 号每年只能修改一次。';

  @override
  String profileObicIdCooldownAt(Object date) {
    return '下次可修改日期：$date';
  }

  @override
  String profileObicIdCooldownData(Object date) {
    return 'OBIC 号每年只能修改一次。下次可修改：$date。';
  }

  @override
  String get profileObicIdCooldownHint => 'OBIC 号每年只能修改一次。';

  @override
  String get meObicId => 'OBIC 号';

  @override
  String get meObicIdUnset => '未设置';

  @override
  String get meMyQr => '我的二维码';

  @override
  String get chatComposeHint => '消息…';

  @override
  String get chatGroup => '群聊';

  @override
  String get ordersTitle => '我的订单';

  @override
  String get ordersHint => '订单仅属于您；服务器会验证所有权。';

  @override
  String get meTitle => '我的';

  @override
  String get meFavorites => '收藏';

  @override
  String get mePayServices => '支付与服务';

  @override
  String get payDemoBannerTitle => '试用示例';

  @override
  String get payDemoBannerBody => '这是支付与服务演示页 — 仅展示界面，暂无真实支付。';

  @override
  String get payDemoSectionMoney => '收付款';

  @override
  String get payDemoSectionShortcuts => '服务快捷入口';

  @override
  String get payDemoSectionOffers => 'OBIC 优惠';

  @override
  String get payDemoWallet => '钱包';

  @override
  String get payDemoTransfer => '转账';

  @override
  String get payDemoReceive => '收款';

  @override
  String get payDemoCards => '银行卡';

  @override
  String get payDemoDailyServices => '日常服务';

  @override
  String get payDemoVisa => '签证';

  @override
  String get payDemoBanking => '开户';

  @override
  String get payDemoTravel => '出行';

  @override
  String get payDemoOfferVip => 'VIP 中国';

  @override
  String get payDemoOfferPartner => '合作优惠';

  @override
  String get payDemoOfferSeasonal => '季节活动';

  @override
  String get payDemoOfferComing => '即将上线';

  @override
  String get payDemoOpenRealServices => '打开完整服务页';

  @override
  String get payDemoFooter => '产品试用占位界面。真实钱包与支付稍后上线。';

  @override
  String payDemoTileSnack(String label) {
    return '$label — 仅示例';
  }

  @override
  String get meMyPosts => '我的动态';

  @override
  String get meWorks => '视频号';

  @override
  String get meChannelHint => '在这里看我的视频号';

  @override
  String get meStatus => '状态';

  @override
  String meFriendsCount(int count) {
    return '$count 位好友';
  }

  @override
  String get meHint => '个人资料、语言与登录 — 权限由服务器控制。';

  @override
  String get meGuestHint => '登录后使用聊天、动态、订单与在华日常服务。';

  @override
  String get meRole => '角色';

  @override
  String get addressesTitle => '我的地址';

  @override
  String get addressesAdd => '添加地址';

  @override
  String get addressesEdit => '编辑地址';

  @override
  String get addressesEmpty => '暂无保存的地址。添加地址以便外卖配送和服务请求。';

  @override
  String get addressesLabel => '标签';

  @override
  String get addressesLine1 => '街道 / 楼栋';

  @override
  String get addressesLine2 => '单元 / 楼层';

  @override
  String get addressesCity => '城市';

  @override
  String get addressesDistrict => '区 / 区域';

  @override
  String get addressesNotes => '配送备注';

  @override
  String get addressesOptional => '可选';

  @override
  String get addressesSave => '保存地址';

  @override
  String get addressesSetDefault => '默认地址';

  @override
  String get addressesDefaultBadge => '默认';

  @override
  String get addressesDeleteTitle => '删除地址？';

  @override
  String get addressesDeleteBody => '此地址将从您的资料中移除。';

  @override
  String get addressesDeleteConfirm => '删除';

  @override
  String get addressesRequiredFields => '标签、街道和城市为必填项。';

  @override
  String get addressesPickTitle => '配送到';

  @override
  String get aboutObicBlurb => 'OBIC 不止服务——在华社交与生活：聊天、动态、餐饮、酒店、健康与出行。';

  @override
  String get aboutCredit => 'Made by Dr Ali';

  @override
  String get languageToggle => 'العربية';

  @override
  String get authLogin => '登录';

  @override
  String get authRegister => '注册';

  @override
  String get authEmailTab => '邮箱';

  @override
  String get authPhoneTab => '手机';

  @override
  String get authUseSmsCode => '验证码登录';

  @override
  String get authUsePassword => '密码登录';

  @override
  String get authSendCode => '发送验证码';

  @override
  String get authSmsCodeHint => '新号码将自动注册';

  @override
  String get authUseEmail => '使用邮箱';

  @override
  String get authUsePhone => '使用手机号';

  @override
  String get authEmail => '邮箱';

  @override
  String get authPhone => '手机';

  @override
  String get authName => '姓名';

  @override
  String get authPassword => '密码';

  @override
  String get authPasswordHint => '至少 8 个字符';

  @override
  String get authSignIn => '登录';

  @override
  String get authCreateAccount => '创建账户';

  @override
  String get authLogout => '退出登录';

  @override
  String get authOrContinue => '或使用';

  @override
  String get authContinueGoogle => '使用 Google 继续';

  @override
  String get authContinueApple => '使用 Apple 继续';

  @override
  String get authSocialNotConfigured => '此版本尚未配置 Google 或 Apple 登录。';

  @override
  String get authProviderEmailNotVerified =>
      'Apple 或 Google 未确认该邮箱，OBIC 不会跳过邮箱验证。';

  @override
  String get authSocialRoleNotAllowed => '该邮箱是员工账号，请使用密码登录。';

  @override
  String get authInvalidSocialToken => '无法验证这次 Google 或 Apple 登录，请重试。';

  @override
  String get authComingSoon => '即将推出';

  @override
  String get authEmailRequired => '请输入邮箱';

  @override
  String get authPhoneRequired => '请输入手机号';

  @override
  String get authFailed => '登录失败';

  @override
  String get authTotpHint => '请输入身份验证器中的 6 位验证码';

  @override
  String get authTotpCode => '验证码';

  @override
  String get authTotpVerify => '验证';

  @override
  String get authTotpBack => '返回登录';

  @override
  String get authNetworkError => '网络错误 — API 是否在运行？';

  @override
  String get authServerWaking => '服务器正在唤醒 — 请稍等几秒再试';

  @override
  String get authStillConnecting => '仍在连接 — 服务器可能正在唤醒';

  @override
  String get authRequiredTitle => '需要登录';

  @override
  String get authRequiredBody => '浏览无需登录。要提交服务请求、下单、聊天、发动态或加好友，请登录或注册。';

  @override
  String get authClose => '关闭';

  @override
  String get authWelcomeBack => '欢迎回来';

  @override
  String get authJoinHeadline => '加入 OBIC';

  @override
  String get authSignInSupport => '好友聊天 · 订餐 · 订酒店 · 健康与更多';

  @override
  String get authRegisterSupport => '聊天、动态、订餐订酒店、健康与 OBIC 服务——一站完成。';

  @override
  String get authForgotPassword => '忘记密码？';

  @override
  String get authNoAccount => '还没有账户？';

  @override
  String get authHasAccount => '已有账户？';

  @override
  String get authGoRegister => '立即注册';

  @override
  String get authGoLogin => '去登录';

  @override
  String get actionRequestService => '申请此服务';

  @override
  String get actionPlaceOrder => '下单';

  @override
  String get actionChatStaff => '联系员工';

  @override
  String get obicAiTitle => 'OBIC AI';

  @override
  String get obicAiWelcome =>
      '可咨询应用里的全部服务：房产、交通、旅游、医疗、餐饮、购物、教育、物流、政务、商务、签证、酒店、优惠或网点，也可查询订单状态。人工客服随时可帮助您。';

  @override
  String get obicAiInputHint => '问 OBIC AI…';

  @override
  String get obicAiOfflineHint => '本服务器尚未开启 OBIC AI。您仍可联系人工客服。';

  @override
  String get obicAiEmptyReply => '暂无回复 — 请重试或联系客服。';

  @override
  String get obicAiTabInstructions => '说明';

  @override
  String get obicAiTabChat => '对话';

  @override
  String get obicAiTabHistory => '历史';

  @override
  String get obicAiNewChat => '新对话';

  @override
  String get obicAiHistoryEmpty => '暂无历史对话。在「对话」提问后会显示在这里。';

  @override
  String get obicAiHistoryOpen => '打开';

  @override
  String get obicAiHistoryDelete => '删除';

  @override
  String get obicAiCopy => '复制';

  @override
  String get obicAiCopied => '已复制';

  @override
  String get obicAiNothingToCopy => '没有可复制的文字';

  @override
  String get obicAiRetry => '重新生成';

  @override
  String get obicAiStop => '停止';

  @override
  String get obicAiAttach => '添加附件';

  @override
  String get obicAiAttachPhoto => '照片';

  @override
  String get obicAiAttachPdf => 'PDF';

  @override
  String get obicAiAttachSheet => '表格';

  @override
  String get obicAiRemoveAttachment => '移除附件';

  @override
  String get obicAiFileTooLarge => '文件超过 4 MB，请选择更小的文件。';

  @override
  String get obicAiUnsupportedFile =>
      '仅支持 JPEG、PNG、WebP 图片，以及 PDF、Excel 或 CSV。';

  @override
  String get obicAiAttachmentNotConfigured => '图片和文件阅读尚未配置。';

  @override
  String get obicAiCouldNotReadFile => '无法读取此文件。';

  @override
  String get obicAiInstructionsTitle => '如何使用 OBIC AI';

  @override
  String get obicAiInstructionsBody =>
      'OBIC AI 能做什么\n• 回答服务目录中的全部内容：房产、交通、旅游、医疗、餐饮、购物、教育、物流、政务与商务，以及签证、酒店、配送等子项，还有优惠与网点。\n• 用您的语言回复——阿拉伯语、英语、中文、法语及其他语言。自然书写即可，它会跟随您的语言。\n\n本页与自动回复\n• 「对话」是您的专属助手。「历史」保存问答，方便稍后回来查看。\n• 客服与订单会话也可能收到简短 AI 自动回复。\n• 好友聊天保持社交私密——没有 AI。\n\n联系人工\n• 需要人工：消息 → OBIC 客服或订单会话 →「联系人工」。\n\n语言\n• 应用语言（阿 / EN / 中文 / FR）控制本页界面文案。\n• 您消息的语言控制 AI 回复语言。';

  @override
  String obicAiBalance(String amount) {
    return '余额：$amount';
  }

  @override
  String get obicAiTopUp => '充值';

  @override
  String get obicAiTopUpTitle => '充值 OBIC AI';

  @override
  String get obicAiTopUpBody =>
      '需先支付 ¥200，这笔钱成为你的余额。之后按次扣费：文字提问 ¥0.10，照片 ¥0.20，PDF 或表格 ¥0.20。余额不够下一次使用时，OBIC AI 会拒绝并请你再充一包 ¥200。';

  @override
  String get obicAiSandboxTopUp => '确认沙盒充值 ¥200';

  @override
  String get obicAiSandboxNote => '沙盒：不会划转真实资金。';

  @override
  String get obicAiTopUpSuccess => '已向余额加入 ¥200（沙盒）。';

  @override
  String get obicAiBalanceLow => '余额不足。请充值 ¥200 套餐后继续。';

  @override
  String get obicAiTopUpFailed => '充值失败，请重试。';

  @override
  String get obicAiCardNotConnected => '银行卡支付尚未接通。';

  @override
  String get msgTranslate => '翻译';

  @override
  String get msgShowOriginal => '显示原文';

  @override
  String get msgShowTranslation => '显示译文';

  @override
  String get msgTranslating => '正在翻译…';

  @override
  String get msgTranslateFailed => '翻译失败 — 请重试。';

  @override
  String get authSuccessContinue => '已登录 — 可以继续。';

  @override
  String get brandTag => '聊天 · 餐饮 · 酒店 · 健康等';

  @override
  String get searchPlaceholder => '搜索餐饮、酒店、健康、签证…';

  @override
  String get featured => '精选';

  @override
  String get vipTrip => 'VIP 中国之旅';

  @override
  String get vipTripDesc => '接机 · 酒店 · 参观工厂 · 专属客户经理';

  @override
  String get bookPkg => '预订套餐 →';

  @override
  String get fastTrack => '快速通道';

  @override
  String get visaExpress => '签证加急';

  @override
  String get visaExpressDesc => '商务/旅游签证支持与清单指导';

  @override
  String get from120 => '\$120 起 →';

  @override
  String get setup => '开户';

  @override
  String get openBank => '开设银行账户';

  @override
  String get openBankDesc => '本地开户指导与网点协调';

  @override
  String get startReq => '开始申请 →';

  @override
  String get topServices => '热门服务';

  @override
  String get seeAll => '查看全部';

  @override
  String get recommended => '推荐';

  @override
  String get regionDetecting => '正在定位…';

  @override
  String get regionRefresh => '刷新';

  @override
  String get regionUnavailable => '您所在地区暂未提供此服务';

  @override
  String get nearMeTitle => '附近网点';

  @override
  String get nearMeHint => '按与您的距离排序';

  @override
  String get allServices => '全部服务';

  @override
  String get serviceLabel => '服务';

  @override
  String get officialBadge => 'OBIC 官方';

  @override
  String get includedTitle => '包含内容';

  @override
  String get advisorTitle => '专属顾问';

  @override
  String get advisorDesc => '提交请求后为您分配';

  @override
  String get checklistTitle => '材料清单';

  @override
  String get checklistDesc => '在订单中查看清晰步骤';

  @override
  String get statusUpdatesTitle => '状态更新';

  @override
  String get statusUpdatesDesc => '在订单页跟踪进度';

  @override
  String get requestSvc => '申请此服务';

  @override
  String get chatSupport => '联系客服';

  @override
  String get chatComingSoon => '正在打开客服聊天…';

  @override
  String get requestTitle => '申请';

  @override
  String get prefBranch => '首选分支';

  @override
  String get notesLabel => '备注';

  @override
  String get notesHint => '日期、目标、文件说明…';

  @override
  String get submitOrder => '提交订单';

  @override
  String get orderSubmitted => '订单提交成功。';

  @override
  String get ordersEmptyGuest => '登录后查看您的申请。';

  @override
  String get ordersEmptyAuth => '暂无申请 — 从首页申请服务，或联系 OBIC 团队。';

  @override
  String get statusSubmitted => '已提交';

  @override
  String get statusInProgress => '处理中';

  @override
  String get statusAssigned => '已分配';

  @override
  String get statusWaitingCustomer => '等待客户';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusCancelled => '已取消';

  @override
  String get statusOpen => '进行中';

  @override
  String get statusWithAgent => '人工接待';

  @override
  String get requestTypeSupport => 'OBIC 客服';

  @override
  String get orderChat => '关于此订单的聊天';

  @override
  String get legalTerms => '条款';

  @override
  String get legalPrivacy => '隐私政策';

  @override
  String get legalAgreePrefix => '创建账户即表示您同意';

  @override
  String get legalAnd => '与';

  @override
  String get offlineBanner => '等待网络…';

  @override
  String get offlineConnecting => '正在连接…';

  @override
  String get offlineNeedsNetwork => '当前离线 — 恢复网络后再试。';

  @override
  String get offlineNoInternet => '无网络连接。请检查网络设置';

  @override
  String get msgWaitingNetwork => '等待网络…';

  @override
  String get msgTapToResend => '点击重发';

  @override
  String get networkUnavailable => '网络不可用，请重试。';

  @override
  String get actionOk => '好';

  @override
  String get actionCancel => '取消';

  @override
  String get chatDayToday => '今天';

  @override
  String get chatDayYesterday => '昨天';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAccount => '账号';

  @override
  String get settingsGeneral => '通用';

  @override
  String get settingsFeatures => '功能';

  @override
  String get settingsProfile => '个人资料';

  @override
  String get settingsAccountSecurity => '账号安全';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsMomentsNotifications => '朋友圈通知';

  @override
  String get settingsMomentsNotifyFriends => '好友发布朋友圈时通知我';

  @override
  String get settingsMomentsMute => '关闭朋友圈更新提醒';

  @override
  String get settingsInterface => '语言与显示';

  @override
  String get settingsFriendsPermissions => '朋友权限';

  @override
  String get settingsStorage => '存储空间';

  @override
  String get settingsChats => '聊天';

  @override
  String get settingsVoiceVideo => '音视频通话';

  @override
  String get profileName => '名字';

  @override
  String get profilePhoto => '头像';

  @override
  String get profileGender => '性别';

  @override
  String get profileGenderMale => '男';

  @override
  String get profileGenderFemale => '女';

  @override
  String get profileGenderOther => '其他';

  @override
  String get profileGenderUnset => '未设置';

  @override
  String get profileRegion => '地区';

  @override
  String get profileMobile => '手机号';

  @override
  String get profileWhatsUp => '个性签名';

  @override
  String get profileWhatsUpHint => '朋友在相册里看到的一句话';

  @override
  String get profileMyQr => '我的二维码';

  @override
  String get profileId => '账号';

  @override
  String get momentsPin => '置顶';

  @override
  String get profilePhone => '手机号';

  @override
  String get profileEmail => '邮箱';

  @override
  String get profileCity => '城市';

  @override
  String get profileCountry => '国家';

  @override
  String get profileEmailReadOnly => '此处无法修改邮箱';

  @override
  String get profileSave => '保存';

  @override
  String get profileSaved => '已保存';

  @override
  String get securityChangePassword => '修改密码';

  @override
  String get securityCurrentPassword => '当前密码';

  @override
  String get securityNewPassword => '新密码';

  @override
  String get securityPasswordChanged => '密码已更新';

  @override
  String get securityLinkedAccounts => '登录方式';

  @override
  String get friendsMuteMoments => '不看他（她）的朋友圈';

  @override
  String get friendsMuteMomentsHint => '其朋友圈不再出现在你的列表，也不再提醒或角标';

  @override
  String get friendsHideMyMoments => '不让他（她）看';

  @override
  String get friendsNoFriends => '暂无好友';

  @override
  String get storageClearCache => '清理缓存';

  @override
  String get storageCleared => '已清理';

  @override
  String get storageCacheHint => '只删除已缓存的图片和文件。聊天、消息和登录都会保留。';

  @override
  String get storageClearConfirm => '清理这台手机上的缓存图片和文件？聊天和登录会保留。';

  @override
  String storageFreed(String size) {
    return '已释放 $size';
  }

  @override
  String get storageImages => '图片';

  @override
  String get storageVideos => '视频';

  @override
  String get storageVoice => '语音';

  @override
  String get storageFiles => '文件';

  @override
  String get storageMusic => '已下载音乐';

  @override
  String get storageChats => '聊天';

  @override
  String get storageChatsHint => '保留在这台手机上。清理缓存不会删除它们。';

  @override
  String get storageClearMusic => '清除已下载音乐';

  @override
  String get storageAutoDelete => '自动删除过期缓存';

  @override
  String get storageAutoNever => '从不';

  @override
  String storageAutoDays(int days) {
    return '$days 天';
  }

  @override
  String get chatsEnterSend => '按 Enter 发送';

  @override
  String get chatsConfirmDelete => '删除消息前确认';

  @override
  String get voiceSpeakerDefault => '语音通话默认扬声器';

  @override
  String get voiceVideoPreview => '显示我的视频预览';

  @override
  String get settingsSaved => '已保存';

  @override
  String get switchAccountTitle => '切换账号';

  @override
  String get switchAccountHint => '轻触头像切换账号';

  @override
  String get switchAccountAdd => '添加账号';

  @override
  String get momentsCopyLink => '复制链接';

  @override
  String get momentsCopied => '已复制链接';

  @override
  String get momentsCopyText => '复制';

  @override
  String get momentsTextCopied => '已复制';

  @override
  String get momentsTranslate => '翻译';

  @override
  String get momentsMyAlbum => '我的朋友圈';

  @override
  String momentsFriendAlbum(String name) {
    return '$name的朋友圈';
  }

  @override
  String get momentsCoverTapHint => '点击封面可更换';

  @override
  String get momentsCoverAdjust => '调整封面';

  @override
  String get momentsCoverSave => '完成';

  @override
  String get momentsCoverAdjustHint => '拖动移动 · 双指缩放 · 然后点完成';

  @override
  String get channelTitle => '视频号';

  @override
  String get callErrorGeneric => '无法连接 — 请重试';

  @override
  String get callErrorPermission => '需要相机或麦克风权限';

  @override
  String get callErrorJoin => '无法开始通话 — 请检查网络后重试';

  @override
  String get settingsSystem => '系统';

  @override
  String get settingsDarkMode => '深色模式';

  @override
  String get settingsSupportSafety => '支持与安全';

  @override
  String get settingsContactSupport => '联系客服';

  @override
  String get settingsReportBug => '报告问题';

  @override
  String get settingsRestoreAccount => '恢复账号';

  @override
  String get restoreAccountHint => '请联系 OBIC 员工在管理后台恢复已停用账号';

  @override
  String get restoreAccountDialog =>
      '暂无自助恢复。请向客服提供邮箱或手机号 — 超级管理员或 Ops 员工可在管理后台恢复。恢复后请用原密码登录。';

  @override
  String get deleteAccountTitle => '删除账号';

  @override
  String get deleteAccountBody => '账号将被停用，您将从此设备退出。如需恢复可由员工在管理后台操作。';

  @override
  String get deleteAccountPasswordRequired => '当前密码（必填）';

  @override
  String get deleteAccountSuperAdminRule =>
      '超级管理员：仅当仍有其他超级管理员时才能自删；最后一个超级管理员不可自删。';

  @override
  String get deleteAccountConfirm => '删除';

  @override
  String get deleteAccountDone => '已在此设备删除账号';

  @override
  String get reportBugTitle => '报告问题';

  @override
  String get reportBugDescriptionHint => '描述问题（至少 5 个字）';

  @override
  String get reportBugAddPhotos => '添加图片';

  @override
  String get reportBugSubmit => '提交';

  @override
  String get reportBugThanks => '感谢 — 团队会查看您的报告';

  @override
  String get reportBugTooShort => '请补充更多细节';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get chatMute => '消息免打扰';

  @override
  String get chatUnmute => '取消免打扰';

  @override
  String get chatMuted => '已静音';

  @override
  String get chatUnmuted => '已取消静音';

  @override
  String get chatHide => '隐藏聊天';

  @override
  String get chatHideConfirm => '从列表隐藏？再次打开会恢复显示。';

  @override
  String get chatClearHistory => '清空聊天记录';

  @override
  String get chatClearHistoryConfirm => '仅清空您这边的记录，无法撤销。';

  @override
  String get chatDelete => '删除聊天';

  @override
  String get chatDeleteConfirm => '从列表删除此聊天并为你清空记录？';

  @override
  String get chatMarkUnread => '标为未读';

  @override
  String get chatPin => '置顶聊天';

  @override
  String get chatUnpin => '取消置顶';

  @override
  String get chatDraftPrefix => '[草稿]';

  @override
  String get chatRecall => '撤回';

  @override
  String get chatRecalledYou => '你撤回了一条消息';

  @override
  String get chatRecalledPeer => '有一条消息被撤回';

  @override
  String get errorProfileFieldsUnsupported => '无法保存资料。请更新应用后重试。';

  @override
  String get errorWrongPassword => '当前密码不正确';

  @override
  String get errorEmailTaken => '该邮箱已被使用';

  @override
  String get errorObicIdTaken => '该 OBIC ID 已被占用';

  @override
  String get errorGenericRetry => '出错了 — 请重试';

  @override
  String get errorUploadFailed => '无法上传照片 — 请换一张图片重试';

  @override
  String get errorMomentsCoverFailed => '无法更新朋友圈封面 — 请重试';

  @override
  String get errorOnlySecretaryCanUpdateStatus => '仅秘书可以更新状态';

  @override
  String get profileObicIdCopied => '已复制 OBIC ID';

  @override
  String get profileSetObicId => '设置 OBIC ID';

  @override
  String get profileChangeObicId => '更改 ID';

  @override
  String get profileEmailPasswordRequired => '当前密码（更改邮箱时必填）';

  @override
  String get profileEmailChangeHint => '更改邮箱需验证当前密码；旧邮箱将无法登录。';

  @override
  String get settingsLanguage => '语言';

  @override
  String get verifyOtpTitle => '输入验证码';

  @override
  String get verifyOtpEmailHint => '我们已向你的邮箱发送 6 位验证码';

  @override
  String get verifyOtpPhoneHint => '我们已向你的手机发送 6 位验证码';

  @override
  String get verifyOtpPhoneViaEmailHint => '目前通过邮箱发送验证码以确认手机号，短信验证稍后上线。';

  @override
  String get verifyOtpPhoneTrialEmailHint => '目前通过邮箱发送验证码以确认手机号，短信验证稍后上线。';

  @override
  String get verifyOtpPhoneTrialLogHint => '请输入发到邮箱的验证码';

  @override
  String get verifyOtpSmsNotConfigured => '短信服务尚未配置，请稍后再试或联系支持';

  @override
  String get verifyOtpSmsSendFailed => '短信发送失败，请稍后重试';

  @override
  String get verifyOtpEmailSendFailed => '邮件验证码发送失败，请检查邮箱后重试';

  @override
  String get verifyOtpEmailRequiredForPhone => '请填写邮箱以接收验证码';

  @override
  String get verifyOtpInvalid => '请输入 6 位验证码';

  @override
  String get verifyOtpWrongCode => '验证码不正确';

  @override
  String get verifyOtpExpired => '验证码已过期，请重新获取';

  @override
  String get verifyOtpTooManyAttempts => '尝试次数过多，请重新获取验证码';

  @override
  String get verifyOtpSessionExpired => '验证会话已过期，请重新开始';

  @override
  String get verifyOtpConfirm => '验证';

  @override
  String get verifyOtpResend => '重新发送';

  @override
  String verifyOtpResendIn(Object seconds) {
    return '$seconds 秒后可重发';
  }

  @override
  String get verifyOtpResent => '验证码已发送';

  @override
  String verifyOtpTrialCode(Object code) {
    return '测试验证码：$code';
  }

  @override
  String get friendsCopyObicId => '复制 OBIC ID';

  @override
  String get phoneVerifyTitle => '验证手机号';

  @override
  String get phoneVerifyHeadline => '需验证中国大陆手机号';

  @override
  String get phoneVerifyBody => '在中国的用户须添加并验证中国大陆手机号（+86）后才能使用聊天与订单。设置与语言仍可使用。';

  @override
  String get phoneVerifyBodyEmailOtp => '请填写大陆手机号（+86）。目前用邮箱验证码确认号码，短信验证稍后上线。';

  @override
  String get phoneVerifyEmailForCodeHint => '用于接收验证码的邮箱';

  @override
  String get phoneVerifySendCode => '发送验证码';

  @override
  String get phoneVerifyOpenSettings => '语言与外观';

  @override
  String get phoneVerifyLater => '稍后激活';

  @override
  String get phoneVerifyLocked => '可以先看看。要操作请先激活手机号。';

  @override
  String get phoneVerifyActivate => '激活号码';

  @override
  String get phoneChinaOnly => '仅支持中国大陆号码（+86 / 1[3-9]…）';

  @override
  String get smsPhoneCountries => '请使用中国、沙特阿拉伯或也门的手机号。';

  @override
  String get smsCountryChina => '中国 +86';

  @override
  String get smsCountrySaudi => '沙特 +966';

  @override
  String get smsCountryYemen => '也门 +967';

  @override
  String get phoneVerifyBlocked => '请先验证中国大陆手机号';

  @override
  String get emailVerifyTitle => '验证邮箱';

  @override
  String get emailVerifyHeadline => '需验证邮箱';

  @override
  String get emailVerifyBody => '在中国的用户须先验证邮箱后才能使用聊天与订单。验证码会发到你的收件箱。';

  @override
  String get emailVerifySendCode => '发送邮箱验证码';

  @override
  String get authChinaPhoneRequired => '在中国请用大陆手机号（+86）和邮箱注册以接收验证码';

  @override
  String get profileUseCurrentLocation => '使用当前位置';

  @override
  String get profileLocationDetecting => '正在定位…';

  @override
  String profileLocationDetail(String detail) {
    return '附近：$detail';
  }

  @override
  String get profilePickCountry => '选择国家/地区';

  @override
  String get profilePickCity => '选择城市';

  @override
  String get profileSearchCountry => '搜索国家/地区';

  @override
  String get profileSearchCity => '搜索城市';

  @override
  String get profileLocationFailed => '无法定位 — 请手动选择国家与城市';

  @override
  String get miniAppsTitle => 'OBIC 小程序';

  @override
  String get miniAppsPullCue => '下拉打开小程序';

  @override
  String get miniAppsPullHint => '已通过的小程序';

  @override
  String get miniAppsTipTitle => '小程序在这里';

  @override
  String get miniAppsTipBody => '在首页顶部下拉，或点按小程序栏，即可打开已通过审核的小程序。';

  @override
  String get miniAppsTipTry => '试一试';

  @override
  String get miniAppsTipDismiss => '知道了';

  @override
  String get miniAppsSearchHint => '搜索小程序';

  @override
  String get miniAppsEmptySearch => '没有匹配的小程序';

  @override
  String get miniAppsClose => '关闭';

  @override
  String get miniAppsCloseHint => '上滑关闭';

  @override
  String get miniAppsExampleBadge => '示例';

  @override
  String get miniAppsPartnerBadge => '示例小程序';

  @override
  String get miniAppsComingSoonBody => '只有已通过审核的小程序才会在 OBIC 内打开。';

  @override
  String get miniAppsPartnerHint =>
      '请在设置 → 小程序提交页面。超级管理员通过后才会出现在这里。已拒绝和已停用的不会打开。';

  @override
  String get channelDescription => '来自 OBIC 员工与好友的短视频';

  @override
  String get channelFollow => '关注';

  @override
  String get channelFollowing => '已关注';

  @override
  String channelStats(int followers, int videos) {
    return '$followers 位关注者 · $videos 个视频';
  }

  @override
  String channelLimitsHint(int mb, int sec) {
    return '短视频上限 $mb MB、$sec 秒';
  }

  @override
  String get channelEmpty => '暂无视频 — 来发第一条吧';

  @override
  String get channelUpload => '上传';

  @override
  String get channelUploadTitle => '上传短视频';

  @override
  String get channelUploadLimits => '最大 40 MB、60 秒';

  @override
  String get channelCaptionHint => '添加说明（可选）';

  @override
  String get channelUploadDone => '已发布';

  @override
  String get channelVideoTooLarge => '视频太大（最大 40 MB）';

  @override
  String get channelVideoTooLong => '视频太长（最长 60 秒）';

  @override
  String get channelNoCaption => '短视频';

  @override
  String get discoverTitle => '发现';

  @override
  String get discoverMiniAppsHint => '打开小程序 · 也可在首页下拉';

  @override
  String get channelTabFollow => '关注';

  @override
  String get channelTabNearby => '附近';

  @override
  String get channelTabFriends => '朋友';

  @override
  String get channelTabHot => '热门';

  @override
  String get channelMyChannel => '我的视频号';

  @override
  String get channelOfficialShort => 'OBIC 官方';

  @override
  String get channelPostDenied => '个人视频号仅好友可见。员工可发官方号。';

  @override
  String get channelShared => '已复制 — 分享数已更新';

  @override
  String get channelShareTitle => '分享';

  @override
  String get channelShareToMoments => '分享到朋友圈';

  @override
  String get channelShareToChat => '分享给朋友';

  @override
  String get channelShareCopyLink => '复制链接';

  @override
  String get channelShareCopied => '链接已复制';

  @override
  String get channelShareMomentsDone => '已分享到朋友圈';

  @override
  String get channelShareChatDone => '已发送到聊天';

  @override
  String get channelShareNoFriends => '请先添加好友再分享到聊天';

  @override
  String get channelSharePickFriend => '发送给…';

  @override
  String channelCommentsTitle(int count) {
    return '$count 条评论';
  }

  @override
  String get channelCommentsEmpty => '暂无评论';

  @override
  String get channelCommentHint => '说点什么…';

  @override
  String get chatNewChat => '发起聊天';

  @override
  String get momentsUnpin => '取消置顶';

  @override
  String get momentsPinnedToast => '已置顶';

  @override
  String get momentsUnpinnedToast => '已取消置顶';

  @override
  String get momentsHideTheirs => '不看他的朋友圈';

  @override
  String get momentsShowTheirs => '看他的朋友圈';

  @override
  String get momentsHideMine => '不让他看我的朋友圈';

  @override
  String get momentsShowMine => '让他看我的朋友圈';

  @override
  String get momentsPrefsSaved => '已更新';

  @override
  String get settingsSounds => '声音';

  @override
  String get soundCall => '来电铃声';

  @override
  String get soundMessage => '消息提示音';

  @override
  String get soundNotification => '通知提示音';

  @override
  String get soundClassic => '经典';

  @override
  String get soundSoft => '轻柔';

  @override
  String get soundBright => '清亮';

  @override
  String get friendsPickerSearch => '搜索';

  @override
  String get friendsPickerEmpty => '无结果';

  @override
  String get messagesFilterAll => '全部';

  @override
  String get messagesFilterUnread => '未读';

  @override
  String get messagesFilterGroups => '群聊';

  @override
  String get messagesFilterServices => '服务';

  @override
  String get messagesFilterEmpty => '此筛选下没有会话';

  @override
  String get chatMarkRead => '标为已读';

  @override
  String get messagesMarkAllRead => '全部标为已读';

  @override
  String get messagesMarkAllReadDone => '已全部标为已读';

  @override
  String get chatTimeYesterday => '昨天';

  @override
  String get chatWeekdayMon => '周一';

  @override
  String get chatWeekdayTue => '周二';

  @override
  String get chatWeekdayWed => '周三';

  @override
  String get chatWeekdayThu => '周四';

  @override
  String get chatWeekdayFri => '周五';

  @override
  String get chatWeekdaySat => '周六';

  @override
  String get chatWeekdaySun => '周日';

  @override
  String get messagesSwipeRead => '已读';

  @override
  String get messagesSwipeUnread => '未读';

  @override
  String get messagesSwipePin => '置顶';

  @override
  String get messagesSwipeUnpin => '取消置顶';

  @override
  String get messagesSwipeMute => '免打扰';

  @override
  String get messagesSwipeUnmute => '取消免打扰';

  @override
  String get messagesSearchHint => '搜索';

  @override
  String get messagesSearchChats => '聊天';

  @override
  String get messagesSearchHistory => '聊天记录';

  @override
  String messagesSearchRelated(int n) {
    return '$n条相关消息';
  }

  @override
  String get messagesSearchEmpty => '无搜索结果';

  @override
  String get chatSearchHint => '搜索此聊天';

  @override
  String get chatSearch => '搜索';

  @override
  String get chatSearchEmpty => '没有匹配的消息';

  @override
  String chatSearchPosition(int current, int total) {
    return '$current/$total';
  }

  @override
  String get chatSearchOlder => '上一条';

  @override
  String get chatSearchNewer => '下一条';

  @override
  String get chatSearchPhotos => '图片';

  @override
  String get chatSearchVideos => '视频';

  @override
  String get chatSearchFiles => '文件';

  @override
  String get chatSearchLinks => '链接';

  @override
  String get chatSearchAll => '全部';

  @override
  String get chatFindInChat => '在聊天中查找';

  @override
  String get chatUnreadNotInView => '第一条未读消息不在已加载的记录中';

  @override
  String get chatCopy => '复制';

  @override
  String get chatQuote => '引用';

  @override
  String get chatDeleteForMe => '为我删除';

  @override
  String get chatDeleteForMeConfirm => '仅在此设备上删除这条消息？';

  @override
  String get chatCopied => '已复制';

  @override
  String get chatNothingToCopy => '没有可复制的内容';

  @override
  String get chatDeletedForMe => '已为你删除';

  @override
  String get chatMessageActions => '消息操作';

  @override
  String get friendsContactsTitle => '通讯录';

  @override
  String get friendsGroupChats => '群聊';

  @override
  String get friendsNewGroup => '发起群聊';

  @override
  String get friendsStarred => '星标朋友';

  @override
  String get directoryTitle => '公司通讯录';

  @override
  String get directoryHint => '这里是允许你看到的同事。手机号只对超级管理员显示。';

  @override
  String get directoryEmpty => '你的范围内还没有同事。';

  @override
  String get directorySearch => '搜索同事';

  @override
  String get directoryUnassigned => '未分配部门';

  @override
  String get directoryMessage => '发消息';

  @override
  String get directoryLoadFailed => '通讯录加载失败';

  @override
  String get approvalsTitle => '审批';

  @override
  String get approvalsHint => '提交申请。审批人按顺序处理。';

  @override
  String get approvalsEmpty => '还没有申请。';

  @override
  String get approvalsNew => '新申请';

  @override
  String get approvalsTemplate => '模板';

  @override
  String get approvalsTitleField => '标题';

  @override
  String get approvalsDetails => '说明';

  @override
  String get approvalsSend => '提交';

  @override
  String get approvalsApprove => '同意';

  @override
  String get approvalsReject => '拒绝';

  @override
  String get approvalsCancel => '撤回申请';

  @override
  String get approvalsWaiting => '待你审批';

  @override
  String get approvalsMine => '我的申请';

  @override
  String get approvalsLoadFailed => '审批加载失败';

  @override
  String get approvalPending => '审批中';

  @override
  String get approvalApproved => '已同意';

  @override
  String get approvalRejected => '已拒绝';

  @override
  String get approvalCancelled => '已撤回';

  @override
  String get attendanceTitle => '打卡';

  @override
  String get attendanceHint => '上班打卡，下班打卡。时间按公司时区计算。';

  @override
  String get attendanceClockIn => '上班打卡';

  @override
  String get attendanceClockOut => '下班打卡';

  @override
  String get attendanceMissing => '未打卡';

  @override
  String get attendanceOnTime => '准时';

  @override
  String get attendanceLate => '迟到';

  @override
  String get attendanceEarly => '早退';

  @override
  String get attendanceOffDay => '非工作日';

  @override
  String get attendanceRecent => '最近几天';

  @override
  String get attendanceNote => '备注（可选）';

  @override
  String get attendanceLoadFailed => '打卡加载失败';

  @override
  String get reportsTitle => '汇报';

  @override
  String get reportsHint => '写下已完成的和下一步。当天、本周、本月可以继续修改。';

  @override
  String get reportsDaily => '日报';

  @override
  String get reportsWeekly => '周报';

  @override
  String get reportsMonthly => '月报';

  @override
  String get reportsDone => '已完成';

  @override
  String get reportsPlan => '下一步';

  @override
  String get reportsBlockers => '困难';

  @override
  String get reportsSend => '提交';

  @override
  String get reportsMissing => '未提交';

  @override
  String get reportsSent => '已提交';

  @override
  String get reportsInbox => '收到的汇报';

  @override
  String get reportsMine => '我的汇报';

  @override
  String get reportsNone => '还没有。';

  @override
  String get reportsLoadFailed => '汇报加载失败';

  @override
  String get formsTitle => '表单';

  @override
  String get formsHint => '填写公司表单。管理台可以查看你提交的内容。';

  @override
  String get formsSend => '提交';

  @override
  String get formsFillRequired => '请填写所有必填项';

  @override
  String get formsNone => '还没有表单。';

  @override
  String get formsMine => '我的表单';

  @override
  String get formsLoadFailed => '表单加载失败';

  @override
  String get collectionTitle => '收集表';

  @override
  String get collectionHint => '填写发给你的收集表。截止前可以修改。';

  @override
  String get collectionSend => '提交';

  @override
  String get collectionFillRequired => '请填写所有必填项';

  @override
  String get collectionNone => '还没有发给你的收集表。';

  @override
  String get collectionOpen => '进行中';

  @override
  String get collectionClosed => '已截止';

  @override
  String get collectionLoadFailed => '收集表加载失败';

  @override
  String get roomsTitle => '会议室';

  @override
  String get roomsHint => '预约会议室。同一时间不能被预约两次。';

  @override
  String get roomsBook => '预约';

  @override
  String get roomsPurpose => '用途';

  @override
  String get roomsStart => '开始';

  @override
  String get roomsEnd => '结束';

  @override
  String get roomsPick => '选择';

  @override
  String get roomsUpcoming => '即将开始';

  @override
  String get roomsNone => '这段时间没有预约。';

  @override
  String get roomsCancel => '取消';

  @override
  String get roomsLoadFailed => '会议室加载失败';

  @override
  String get rosterTitle => '入职与离职';

  @override
  String get rosterHint => '在最后一天申请离职。确认后不会关闭登录。';

  @override
  String get rosterAsk => '申请离职';

  @override
  String get rosterJoined => '入职日期';

  @override
  String get rosterLastDay => '最后一天';

  @override
  String get rosterNote => '备注';

  @override
  String get rosterActive => '在职';

  @override
  String get rosterLeaving => '离职申请中';

  @override
  String get rosterLeft => '已离职';

  @override
  String get rosterUnrecorded => '未记录';

  @override
  String get rosterMissing => '你的入职日期还没有记录。';

  @override
  String get rosterPending => '离职申请正在等待办公台处理。';

  @override
  String get rosterRecorded => '离职已记录。登录保持可用，直到员工台关闭账号。';

  @override
  String get rosterLoadFailed => '花名册加载失败';

  @override
  String get payslipsTitle => '工资条';

  @override
  String get payslipsHint => '打开工资条并确认已查看。这是记录，不会打款。';

  @override
  String get payslipsSeen => '我已查看';

  @override
  String get payslipsConfirmed => '已查看';

  @override
  String get payslipsOpen => '待查看';

  @override
  String get payslipsEarning => '应发';

  @override
  String get payslipsDeduction => '扣款';

  @override
  String get payslipsNet => '实发';

  @override
  String get payslipsNote => '备注';

  @override
  String get payslipsNone => '还没有工资条。';

  @override
  String get payslipsLoadFailed => '工资条加载失败';

  @override
  String get companyContactsTitle => '客户联系人';

  @override
  String get companyContactsHint => '这些联系人属于公司。你只能看到分配给你的人。';

  @override
  String get companyContactsName => '姓名';

  @override
  String get companyContactsPhone => '电话';

  @override
  String get companyContactsOrg => '单位';

  @override
  String get companyContactsNote => '备注';

  @override
  String get companyContactsSave => '保存';

  @override
  String get companyContactsNew => '新联系人';

  @override
  String get companyContactsActive => '有效';

  @override
  String get companyContactsPaused => '已停用';

  @override
  String get companyContactsSearch => '搜索';

  @override
  String get companyContactsNone => '还没有联系人。';

  @override
  String get companyContactsLoadFailed => '客户联系人加载失败';

  @override
  String get companyTagsTitle => '客户标签';

  @override
  String get companyTagsHint => '公司设置的标签。列出的是分配给你的联系人。';

  @override
  String get companyTagsActive => '使用中';

  @override
  String get companyTagsPaused => '已停用';

  @override
  String get companyTagsNone => '还没有标签。';

  @override
  String get companyTagsLoadFailed => '客户标签加载失败';

  @override
  String get companyGroupsTitle => '客户群组';

  @override
  String get companyGroupsHint => '分配给你的一批公司联系人。这不是聊天。';

  @override
  String get companyGroupsName => '群组';

  @override
  String get companyGroupsNote => '备注';

  @override
  String get companyGroupsSave => '保存';

  @override
  String get companyGroupsNew => '新群组';

  @override
  String get companyGroupsActive => '使用中';

  @override
  String get companyGroupsPaused => '已停用';

  @override
  String get companyGroupsNone => '还没有群组。';

  @override
  String get companyGroupsLoadFailed => '客户群组加载失败';

  @override
  String get companyWelcomesTitle => '欢迎语';

  @override
  String get companyWelcomesHint => '接待新客户时使用的欢迎语。应用只显示文字，不会发送。';

  @override
  String get companyWelcomesCopy => '复制';

  @override
  String get companyWelcomesCopied => '欢迎语已复制';

  @override
  String get companyWelcomesAssigned => '分配给你';

  @override
  String get companyWelcomesDefault => '公司欢迎语';

  @override
  String get companyWelcomesNone => '还没有欢迎语。';

  @override
  String get companyWelcomesLoadFailed => '欢迎语加载失败';

  @override
  String get quickRepliesTitle => '快捷回复';

  @override
  String get quickRepliesHint => '复制公司回复，或保存自己的回复。应用不会发送。';

  @override
  String get quickRepliesName => '标题';

  @override
  String get quickRepliesBody => '回复';

  @override
  String get quickRepliesSave => '保存';

  @override
  String get quickRepliesNew => '新回复';

  @override
  String get quickRepliesCopy => '复制';

  @override
  String get quickRepliesCopied => '回复已复制';

  @override
  String get quickRepliesCompany => '公司';

  @override
  String get quickRepliesMine => '我的';

  @override
  String get quickRepliesActive => '使用中';

  @override
  String get quickRepliesPaused => '已停用';

  @override
  String get quickRepliesNone => '还没有回复。';

  @override
  String get quickRepliesLoadFailed => '快捷回复加载失败';

  @override
  String get companyHandoverTitle => '客户交接';

  @override
  String get companyHandoverHint => '这里列出交给你或从你这里交出去的公司客户。应用不会给客户发消息。';

  @override
  String companyHandoverFrom(String name) {
    return '来自 $name';
  }

  @override
  String companyHandoverTo(String name) {
    return '交给 $name';
  }

  @override
  String companyHandoverCount(int count) {
    return '$count 位客户';
  }

  @override
  String get companyHandoverNone => '还没有交接。';

  @override
  String get companyHandoverLoadFailed => '客户交接加载失败';

  @override
  String get companyDriveTitle => '公司网盘';

  @override
  String get companyDriveHint => '公司文件夹。可以在手机上添加照片。其他文件在员工后台添加。这里的文件不是公开链接。';

  @override
  String get companyDriveNone => '还没有文件夹。';

  @override
  String get companyDriveEmpty => '这个文件夹里没有文件。';

  @override
  String get companyDriveOpenOnDesk => '请在员工后台打开这个文件。';

  @override
  String get companyDriveLoadFailed => '公司网盘加载失败';

  @override
  String get companyDocumentsTitle => '共享文档';

  @override
  String get companyDocumentsHint => '打开公司文档并修改文字。最后一次保存会留下来。这不是网盘文件。';

  @override
  String get companyDocumentsBody => '正文';

  @override
  String get companyDocumentsSave => '保存';

  @override
  String companyDocumentsSavedBy(String name) {
    return '最近由 $name 保存';
  }

  @override
  String get companyDocumentsNone => '还没有文档。';

  @override
  String get companyDocumentsLoadFailed => '共享文档加载失败';

  @override
  String get companySpreadsheetsTitle => '共享表格';

  @override
  String get companySpreadsheetsHint => '打开表格并修改单元格。最后一次保存会留下来。单元格是文字，不是公式。';

  @override
  String get companySpreadsheetsSave => '保存';

  @override
  String companySpreadsheetsSavedBy(String name) {
    return '最近由 $name 保存';
  }

  @override
  String get companySpreadsheetsNone => '还没有表格。';

  @override
  String get companySpreadsheetsLoadFailed => '共享表格加载失败';

  @override
  String get companyCalendarTitle => '公司日历';

  @override
  String get companyCalendarHint => '添加事件。时间按中国时间。应用不会发送邀请。这不是会议室预订。';

  @override
  String get companyCalendarName => '标题';

  @override
  String get companyCalendarDate => '日期';

  @override
  String get companyCalendarStart => '开始';

  @override
  String get companyCalendarEnd => '结束';

  @override
  String get companyCalendarNote => '备注';

  @override
  String get companyCalendarSave => '保存';

  @override
  String get companyCalendarNew => '新事件';

  @override
  String get companyCalendarActive => '显示';

  @override
  String get companyCalendarPaused => '已隐藏';

  @override
  String get companyCalendarNone => '这段时间没有事件。';

  @override
  String get companyCalendarLoadFailed => '公司日历加载失败';

  @override
  String get companyMailTitle => '公司邮件';

  @override
  String get companyMailHint => '给其他员工发消息。消息留在 OBIC 内，不会发到外部邮箱。';

  @override
  String get companyMailSubject => '主题';

  @override
  String get companyMailBody => '正文';

  @override
  String get companyMailSend => '发送';

  @override
  String get companyMailTo => '收件人';

  @override
  String get companyMailInbox => '收件箱';

  @override
  String get companyMailOutbox => '已发送';

  @override
  String get companyMailNone => '没有消息。';

  @override
  String get companyMailLoadFailed => '公司邮件加载失败';

  @override
  String get companyMeetingsTitle => '公司会议';

  @override
  String get companyMeetingsHint => '会议有时间、议程、应参加的员工和会后记录。时间为中国时间。应用不会发起通话。';

  @override
  String get companyMeetingsName => '标题';

  @override
  String get companyMeetingsDate => '日期';

  @override
  String get companyMeetingsStart => '开始';

  @override
  String get companyMeetingsEnd => '结束';

  @override
  String get companyMeetingsAgenda => '议程';

  @override
  String get companyMeetingsNotes => '记录';

  @override
  String get companyMeetingsTo => '参加人';

  @override
  String get companyMeetingsSave => '保存';

  @override
  String get companyMeetingsNew => '新会议';

  @override
  String get companyMeetingsActive => '显示';

  @override
  String get companyMeetingsPaused => '已隐藏';

  @override
  String get companyMeetingsNone => '没有会议。';

  @override
  String get companyMeetingsLoadFailed => '公司会议加载失败';

  @override
  String get companyFileAnswersTitle => '文档问答';

  @override
  String get companyFileAnswersHint =>
      '向公司共享文档提问。答案只来自这些文档。公司 AI 开启时，会根据匹配的段落写回复。';

  @override
  String get companyFileAnswersQuestion => '问题';

  @override
  String get companyFileAnswersAsk => '提问';

  @override
  String get companyFileAnswersFromDocuments => '来自文档';

  @override
  String get companyFileAnswersFromAi => '来自公司 AI';

  @override
  String get companyFileAnswersNone => '没有问题。';

  @override
  String get companyFileAnswersLoadFailed => '文档问答加载失败';

  @override
  String get companyAppsTitle => '公司应用';

  @override
  String get companyAppsHint => '打开公司网页工具。页面留在它自己的网站上。';

  @override
  String get companyAppsNone => '没有应用。';

  @override
  String get companyAppsLoadFailed => '无法打开应用';

  @override
  String get friendsStar => '设为星标';

  @override
  String get friendsUnstar => '取消星标';

  @override
  String get friendsMessage => '发消息';

  @override
  String get friendsRecent => '最近添加';

  @override
  String get friendsNewMark => '新';

  @override
  String friendsContactsCount(int count) {
    return '$count 位联系人';
  }

  @override
  String get friendsGroupsEmpty => '暂无群聊';

  @override
  String get friendsStarredEmpty => '暂无星标朋友。长按好友即可设为星标。';

  @override
  String get contactProfileYou => '你';

  @override
  String get contactProfileRemark => '备注';

  @override
  String get contactProfileSetRemark => '设置备注';

  @override
  String get contactProfileRemarkHint => '仅保存在这台手机上';

  @override
  String contactProfileRealName(String name) {
    return '名字：$name';
  }

  @override
  String get contactProfileVoice => '语音通话';

  @override
  String get contactProfileVideo => '视频通话';

  @override
  String get contactProfileVoiceOrVideo => '语音或视频通话';

  @override
  String get contactProfileSaved => '已保存';

  @override
  String get contactProfileViewPhoto => '查看照片';

  @override
  String get contactProfileCallFailed => '无法发起通话';

  @override
  String contactMomentsNone(String name) {
    return '$name还没有发布任何内容。';
  }

  @override
  String get contactMomentsNoneSelf => '你还没有发布任何内容。';

  @override
  String get settingsMiniApps => '小程序';

  @override
  String get settingsMiniAppsHint => '在 OBIC 网站提交小程序。超级管理员通过后，其他人才能打开。';

  @override
  String get miniAppsWebsiteBody =>
      '小程序在 OBIC 网站提交，不在设置里。用 OBIC 账号登录后，填写名称、简介、图标和 zip 包。';

  @override
  String get miniAppsOpenWebsite => '打开 OBIC 网站';

  @override
  String get miniAppWebsiteName => 'OBIC 官网';

  @override
  String get miniAppFormTitle => '提交小程序';

  @override
  String get miniAppName => '名称';

  @override
  String get miniAppDescription => '简短说明';

  @override
  String get miniAppIconUrl => '图标网址（HTTPS）';

  @override
  String get miniAppPickIcon => '选择图标图片';

  @override
  String get miniAppIconUploading => '正在上传图标…';

  @override
  String get miniAppStartUrl => '页面地址（HTTPS）';

  @override
  String get miniAppSubmit => '提交';

  @override
  String get miniAppMySubmissions => '我的提交';

  @override
  String get miniAppEmptyMine => '你还没有提交小程序。';

  @override
  String get miniAppSubmitted => '已提交。状态：待审核，直到超级管理员处理。';

  @override
  String get miniAppHttpsRequired => '页面地址必须是 HTTPS 网址。';

  @override
  String get miniAppPickPackage => '选择安装包';

  @override
  String get miniAppPackageRequired => '请选择根目录含 index.html 的 .zip 包。';

  @override
  String get miniAppNameRequired => '请填写名称和简短说明。';

  @override
  String get miniAppServerUnavailable => '这台服务器还没有小程序接口。表单已就绪，接口更新后才会开始审核。';

  @override
  String get miniAppStatusPending => '待审核';

  @override
  String get miniAppStatusApproved => '已通过';

  @override
  String get miniAppStatusRejected => '已拒绝';

  @override
  String get miniAppStatusDisabled => '已停用';

  @override
  String get miniAppReviewReason => '原因';

  @override
  String get miniAppEngineFail => '无法打开此小程序';

  @override
  String get miniAppEngineReload => '重新加载';

  @override
  String get miniAppEngineRestart => '重新打开小程序';

  @override
  String get miniAppEngineRetry => '重试';

  @override
  String get discoverShortcuts => '快捷';

  @override
  String get discoverTrending => '热门';

  @override
  String get discoverOffers => '优惠';

  @override
  String get discoverMusic => '音乐';

  @override
  String get discoverNew => '新功能';

  @override
  String get discoverNewHint => '小程序与新功能';

  @override
  String get discoverEmpty => '这里还是空的';

  @override
  String get servicesRecent => '最近';

  @override
  String get servicesRecentEmpty => '还没有最近的服务';

  @override
  String get servicesHeroTitle => '中国与世界';
}
