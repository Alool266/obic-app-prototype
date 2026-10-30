import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'أوبك'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In ar, this message translates to:
  /// **'حياة اجتماعية وخدمات يومية في الصين'**
  String get tagline;

  /// No description provided for @tabHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get tabHome;

  /// No description provided for @tabServices.
  ///
  /// In ar, this message translates to:
  /// **'الخدمات'**
  String get tabServices;

  /// No description provided for @tabMoments.
  ///
  /// In ar, this message translates to:
  /// **'اللحظات'**
  String get tabMoments;

  /// No description provided for @tabDiscover.
  ///
  /// In ar, this message translates to:
  /// **'اكتشف'**
  String get tabDiscover;

  /// No description provided for @tabMessages.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل'**
  String get tabMessages;

  /// No description provided for @tabOrders.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get tabOrders;

  /// No description provided for @tabMe.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get tabMe;

  /// No description provided for @tabContacts.
  ///
  /// In ar, this message translates to:
  /// **'جهات'**
  String get tabContacts;

  /// No description provided for @homeGreeting.
  ///
  /// In ar, this message translates to:
  /// **'حياتك الاجتماعية ويوميات الصين'**
  String get homeGreeting;

  /// No description provided for @homeHint.
  ///
  /// In ar, this message translates to:
  /// **'دردشة ولحظات وأصدقاء ومكالمات — مع طعام وفنادق وصحة وسفر والمزيد.'**
  String get homeHint;

  /// No description provided for @servicesTitle.
  ///
  /// In ar, this message translates to:
  /// **'كل الخدمات'**
  String get servicesTitle;

  /// No description provided for @servicesHint.
  ///
  /// In ar, this message translates to:
  /// **'تصفّح الكتالوج بحرية. الطلب يتطلب تسجيل الدخول.'**
  String get servicesHint;

  /// No description provided for @messagesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل'**
  String get messagesTitle;

  /// No description provided for @messagesHint.
  ///
  /// In ar, this message translates to:
  /// **'محادثة الدعم والأصدقاء والإشعارات.'**
  String get messagesHint;

  /// No description provided for @messagesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا محادثات بعد. ابدأ محادثة مع الفريق.'**
  String get messagesEmpty;

  /// No description provided for @messagesEmptyGuest.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لعرض محادثاتك ومراسلة الفريق.'**
  String get messagesEmptyGuest;

  /// No description provided for @messagesNoPreview.
  ///
  /// In ar, this message translates to:
  /// **'لا رسائل بعد'**
  String get messagesNoPreview;

  /// No description provided for @chatSupportTitle.
  ///
  /// In ar, this message translates to:
  /// **'دعم أوبك'**
  String get chatSupportTitle;

  /// No description provided for @chatTalkToStaff.
  ///
  /// In ar, this message translates to:
  /// **'تحدث مع الفريق'**
  String get chatTalkToStaff;

  /// No description provided for @chatTalkToStaffDone.
  ///
  /// In ar, this message translates to:
  /// **'سيرد الفريق هنا قريباً'**
  String get chatTalkToStaffDone;

  /// No description provided for @chatTalkToStaffBusy.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التوصيل…'**
  String get chatTalkToStaffBusy;

  /// No description provided for @chatHandoffTitle.
  ///
  /// In ar, this message translates to:
  /// **'التواصل مع الفريق'**
  String get chatHandoffTitle;

  /// No description provided for @chatHandoffHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر الفرع والخدمة لنوجّهك إلى المكتب المناسب.'**
  String get chatHandoffHint;

  /// No description provided for @chatHandoffBranch.
  ///
  /// In ar, this message translates to:
  /// **'الفرع'**
  String get chatHandoffBranch;

  /// No description provided for @chatHandoffService.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة / المكتب'**
  String get chatHandoffService;

  /// No description provided for @chatHandoffOrderRef.
  ///
  /// In ar, this message translates to:
  /// **'رقم الطلب / المرجع (اختياري)'**
  String get chatHandoffOrderRef;

  /// No description provided for @chatHandoffOrderRefHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: رقم التأشيرة أو الطلب'**
  String get chatHandoffOrderRefHint;

  /// No description provided for @chatHandoffNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختياري)'**
  String get chatHandoffNote;

  /// No description provided for @chatHandoffNoteHint.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة قصيرة للفريق'**
  String get chatHandoffNoteHint;

  /// No description provided for @chatHandoffSubmit.
  ///
  /// In ar, this message translates to:
  /// **'وصّلني'**
  String get chatHandoffSubmit;

  /// No description provided for @chatHandoffCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get chatHandoffCancel;

  /// No description provided for @chatHandoffUseNearest.
  ///
  /// In ar, this message translates to:
  /// **'استخدم أقرب فرع'**
  String get chatHandoffUseNearest;

  /// No description provided for @chatAddPeopleTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة أشخاص'**
  String get chatAddPeopleTitle;

  /// No description provided for @chatAddPeopleHint.
  ///
  /// In ar, this message translates to:
  /// **'ادعُ موظفي مكاتب الفرع الآخرين إلى هذه المحادثة'**
  String get chatAddPeopleHint;

  /// No description provided for @chatAddPeopleEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد موظفون آخرون لإضافتهم'**
  String get chatAddPeopleEmpty;

  /// No description provided for @chatAddPeopleSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إضافة المحددين'**
  String get chatAddPeopleSubmit;

  /// No description provided for @chatHandoffSummaryTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملخص للسكرتيرة'**
  String get chatHandoffSummaryTitle;

  /// No description provided for @chatInputHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالة…'**
  String get chatInputHint;

  /// No description provided for @attachImage.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق صورة'**
  String get attachImage;

  /// No description provided for @attachFile.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق ملف'**
  String get attachFile;

  /// No description provided for @attachClear.
  ///
  /// In ar, this message translates to:
  /// **'إزالة المرفق'**
  String get attachClear;

  /// No description provided for @chatHoldToTalk.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطولاً للتحدث'**
  String get chatHoldToTalk;

  /// No description provided for @chatReleaseToSend.
  ///
  /// In ar, this message translates to:
  /// **'أفلت للإرسال'**
  String get chatReleaseToSend;

  /// No description provided for @chatSlideToCancel.
  ///
  /// In ar, this message translates to:
  /// **'أفلت للإلغاء'**
  String get chatSlideToCancel;

  /// No description provided for @chatVoiceTooShort.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة الصوتية قصيرة جداً'**
  String get chatVoiceTooShort;

  /// No description provided for @chatMicPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'يلزم إذن الميكروفون للرسائل الصوتية'**
  String get chatMicPermissionDenied;

  /// No description provided for @chatVoiceMode.
  ///
  /// In ar, this message translates to:
  /// **'رسالة صوتية'**
  String get chatVoiceMode;

  /// No description provided for @chatVideoTooLarge.
  ///
  /// In ar, this message translates to:
  /// **'الفيديو كبير جداً (الحد 80 ميجا). جرّب مقطعاً أقصر.'**
  String get chatVideoTooLarge;

  /// No description provided for @chatVideoLargeWarning.
  ///
  /// In ar, this message translates to:
  /// **'الفيديو أكبر من 12 ميجا — قد لا يبقى بعد إعادة نشر التجربة حتى S3. سيتم الإرسال.'**
  String get chatVideoLargeWarning;

  /// No description provided for @chatVideoPickFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة الفيديو. جرّب مقطعاً آخر.'**
  String get chatVideoPickFailed;

  /// No description provided for @mediaAlbum.
  ///
  /// In ar, this message translates to:
  /// **'الألبوم'**
  String get mediaAlbum;

  /// No description provided for @mediaCamera.
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا'**
  String get mediaCamera;

  /// No description provided for @mediaVideo.
  ///
  /// In ar, this message translates to:
  /// **'فيديو'**
  String get mediaVideo;

  /// No description provided for @mediaVideoTitle.
  ///
  /// In ar, this message translates to:
  /// **'فيديو'**
  String get mediaVideoTitle;

  /// No description provided for @mediaFromAlbum.
  ///
  /// In ar, this message translates to:
  /// **'من الألبوم'**
  String get mediaFromAlbum;

  /// No description provided for @mediaRecordVideo.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل فيديو'**
  String get mediaRecordVideo;

  /// No description provided for @mediaCameraPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'يلزم إذن الكاميرا. فعّله من الإعدادات.'**
  String get mediaCameraPermissionDenied;

  /// No description provided for @mediaPhotosPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'يلزم إذن مكتبة الصور. فعّله من الإعدادات.'**
  String get mediaPhotosPermissionDenied;

  /// No description provided for @mediaPickFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح الكاميرا أو الألبوم. حاول مرة أخرى.'**
  String get mediaPickFailed;

  /// No description provided for @momentsAddMedia.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get momentsAddMedia;

  /// No description provided for @momentsTextOnly.
  ///
  /// In ar, this message translates to:
  /// **'نص'**
  String get momentsTextOnly;

  /// No description provided for @momentsTakePhoto.
  ///
  /// In ar, this message translates to:
  /// **'التقاط صورة'**
  String get momentsTakePhoto;

  /// No description provided for @chatImageLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل هذه الصورة. تحقق من الاتصال وحاول مرة أخرى.'**
  String get chatImageLoadFailed;

  /// No description provided for @chatPreviewVoice.
  ///
  /// In ar, this message translates to:
  /// **'[صوت]'**
  String get chatPreviewVoice;

  /// No description provided for @chatPreviewVideo.
  ///
  /// In ar, this message translates to:
  /// **'[فيديو]'**
  String get chatPreviewVideo;

  /// No description provided for @chatPreviewImage.
  ///
  /// In ar, this message translates to:
  /// **'[صورة]'**
  String get chatPreviewImage;

  /// No description provided for @chatPreviewFile.
  ///
  /// In ar, this message translates to:
  /// **'[ملف]'**
  String get chatPreviewFile;

  /// No description provided for @momentsTitle.
  ///
  /// In ar, this message translates to:
  /// **'اللحظات'**
  String get momentsTitle;

  /// No description provided for @momentsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا لحظات بعد — كن أول من ينشر.'**
  String get momentsEmpty;

  /// No description provided for @momentsCreate.
  ///
  /// In ar, this message translates to:
  /// **'لحظة جديدة'**
  String get momentsCreate;

  /// No description provided for @momentsHint.
  ///
  /// In ar, this message translates to:
  /// **'بماذا تفكر؟'**
  String get momentsHint;

  /// No description provided for @momentsPost.
  ///
  /// In ar, this message translates to:
  /// **'نشر'**
  String get momentsPost;

  /// No description provided for @momentsAnon.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم'**
  String get momentsAnon;

  /// No description provided for @momentsDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get momentsDelete;

  /// No description provided for @momentsDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف هذه اللحظة؟ لن يراها الأصدقاء بعد الآن.'**
  String get momentsDeleteConfirm;

  /// No description provided for @momentsDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم الحذف'**
  String get momentsDeleted;

  /// No description provided for @momentsPrivacyWhoCanSee.
  ///
  /// In ar, this message translates to:
  /// **'من يمكنه الرؤية'**
  String get momentsPrivacyWhoCanSee;

  /// No description provided for @momentsPrivacyFriends.
  ///
  /// In ar, this message translates to:
  /// **'كل الأصدقاء'**
  String get momentsPrivacyFriends;

  /// No description provided for @momentsPrivacyFriendsHint.
  ///
  /// In ar, this message translates to:
  /// **'مرئية لأصدقائك'**
  String get momentsPrivacyFriendsHint;

  /// No description provided for @momentsPrivacyPrivate.
  ///
  /// In ar, this message translates to:
  /// **'خاصة'**
  String get momentsPrivacyPrivate;

  /// No description provided for @momentsPrivacyPrivateHint.
  ///
  /// In ar, this message translates to:
  /// **'أنت فقط تراها'**
  String get momentsPrivacyPrivateHint;

  /// No description provided for @momentsPrivacyPartial.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة مع…'**
  String get momentsPrivacyPartial;

  /// No description provided for @momentsPrivacyPartialHint.
  ///
  /// In ar, this message translates to:
  /// **'الأصدقاء المحددون فقط'**
  String get momentsPrivacyPartialHint;

  /// No description provided for @momentsPrivacyPartialSelected.
  ///
  /// In ar, this message translates to:
  /// **'{n} أصدقاء'**
  String momentsPrivacyPartialSelected(int n);

  /// No description provided for @momentsPrivacyExclude.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء عن…'**
  String get momentsPrivacyExclude;

  /// No description provided for @momentsPrivacyExcludeHint.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء عن أصدقاء محددين'**
  String get momentsPrivacyExcludeHint;

  /// No description provided for @momentsPrivacyExcludeSelected.
  ///
  /// In ar, this message translates to:
  /// **'مخفية عن {n}'**
  String momentsPrivacyExcludeSelected(int n);

  /// No description provided for @momentsPrivacyNeedFriends.
  ///
  /// In ar, this message translates to:
  /// **'اختر صديقاً واحداً على الأقل'**
  String get momentsPrivacyNeedFriends;

  /// No description provided for @momentsPrivacyDone.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get momentsPrivacyDone;

  /// No description provided for @momentsOfficial.
  ///
  /// In ar, this message translates to:
  /// **'رسمي'**
  String get momentsOfficial;

  /// No description provided for @momentsAddPhotos.
  ///
  /// In ar, this message translates to:
  /// **'صور'**
  String get momentsAddPhotos;

  /// No description provided for @momentsAddVideos.
  ///
  /// In ar, this message translates to:
  /// **'فيديو'**
  String get momentsAddVideos;

  /// No description provided for @momentsAddFiles.
  ///
  /// In ar, this message translates to:
  /// **'ملفات'**
  String get momentsAddFiles;

  /// No description provided for @momentsChangeAvatar.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الصورة'**
  String get momentsChangeAvatar;

  /// No description provided for @momentsStaff.
  ///
  /// In ar, this message translates to:
  /// **'موظف'**
  String get momentsStaff;

  /// No description provided for @momentsJustNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get momentsJustNow;

  /// No description provided for @momentsMinutesAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ ‎{n}‎ د'**
  String momentsMinutesAgo(Object n);

  /// No description provided for @momentsHoursAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ ‎{n}‎ س'**
  String momentsHoursAgo(Object n);

  /// No description provided for @momentsDaysAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ ‎{n}‎ ي'**
  String momentsDaysAgo(Object n);

  /// No description provided for @momentsLike.
  ///
  /// In ar, this message translates to:
  /// **'إعجاب'**
  String get momentsLike;

  /// No description provided for @momentsUnlike.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الإعجاب'**
  String get momentsUnlike;

  /// No description provided for @momentsComment.
  ///
  /// In ar, this message translates to:
  /// **'تعليق'**
  String get momentsComment;

  /// No description provided for @momentsCommentHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب تعليقاً…'**
  String get momentsCommentHint;

  /// No description provided for @momentsReplyHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رداً…'**
  String get momentsReplyHint;

  /// No description provided for @momentsCommentAddPhoto.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صورة'**
  String get momentsCommentAddPhoto;

  /// No description provided for @momentsCommentTakePhoto.
  ///
  /// In ar, this message translates to:
  /// **'التقاط صورة'**
  String get momentsCommentTakePhoto;

  /// No description provided for @momentsCommentSendFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إرسال التعليق'**
  String get momentsCommentSendFailed;

  /// No description provided for @momentsCommentDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get momentsCommentDelete;

  /// No description provided for @momentsCommentDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف هذا التعليق؟'**
  String get momentsCommentDeleteConfirm;

  /// No description provided for @momentsCommentDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف التعليق'**
  String get momentsCommentDeleted;

  /// No description provided for @momentsReply.
  ///
  /// In ar, this message translates to:
  /// **'رد'**
  String get momentsReply;

  /// No description provided for @momentsReplyTo.
  ///
  /// In ar, this message translates to:
  /// **'رد على {name}'**
  String momentsReplyTo(Object name);

  /// No description provided for @momentsRepliedTo.
  ///
  /// In ar, this message translates to:
  /// **'رد على'**
  String get momentsRepliedTo;

  /// No description provided for @momentsFavorite.
  ///
  /// In ar, this message translates to:
  /// **'مفضلة'**
  String get momentsFavorite;

  /// No description provided for @momentsFavorited.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ في المفضلة'**
  String get momentsFavorited;

  /// No description provided for @momentsReport.
  ///
  /// In ar, this message translates to:
  /// **'إبلاغ'**
  String get momentsReport;

  /// No description provided for @momentsReported.
  ///
  /// In ar, this message translates to:
  /// **'تم الإبلاغ — سيراجعه المشرف'**
  String get momentsReported;

  /// No description provided for @momentsDownload.
  ///
  /// In ar, this message translates to:
  /// **'حفظ في الصور'**
  String get momentsDownload;

  /// No description provided for @momentsSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ في الصور'**
  String get momentsSaved;

  /// No description provided for @momentsSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الحفظ'**
  String get momentsSaveFailed;

  /// No description provided for @momentsFileSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الملف'**
  String get momentsFileSaved;

  /// No description provided for @momentsNoLikes.
  ///
  /// In ar, this message translates to:
  /// **'كن أول من يعجب'**
  String get momentsNoLikes;

  /// No description provided for @notificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا إشعارات جديدة.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsMarkAll.
  ///
  /// In ar, this message translates to:
  /// **'تعليم الكل كمقروء'**
  String get notificationsMarkAll;

  /// No description provided for @friendsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأصدقاء'**
  String get friendsTitle;

  /// No description provided for @friendsList.
  ///
  /// In ar, this message translates to:
  /// **'أصدقاؤك'**
  String get friendsList;

  /// No description provided for @friendsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا أصدقاء بعد — ابحث بالهاتف أو المعرّف.'**
  String get friendsEmpty;

  /// No description provided for @friendsAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صديق'**
  String get friendsAdd;

  /// No description provided for @friendsSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف أو معرّف OBIC'**
  String get friendsSearchHint;

  /// No description provided for @friendsIncoming.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الصداقة'**
  String get friendsIncoming;

  /// No description provided for @friendsAccept.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get friendsAccept;

  /// No description provided for @friendsReject.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get friendsReject;

  /// No description provided for @friendsRequestSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلب الصداقة'**
  String get friendsRequestSent;

  /// No description provided for @friendsNewFriends.
  ///
  /// In ar, this message translates to:
  /// **'أصدقاء جدد'**
  String get friendsNewFriends;

  /// No description provided for @friendsNewFriendsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات صداقة معلّقة.'**
  String get friendsNewFriendsEmpty;

  /// No description provided for @friendsOutgoing.
  ///
  /// In ar, this message translates to:
  /// **'مُرسلة'**
  String get friendsOutgoing;

  /// No description provided for @friendsWaiting.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار القبول'**
  String get friendsWaiting;

  /// No description provided for @friendsAcceptedToast.
  ///
  /// In ar, this message translates to:
  /// **'أصبحتما صديقين'**
  String get friendsAcceptedToast;

  /// No description provided for @friendsSendRequestTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب صداقة'**
  String get friendsSendRequestTitle;

  /// No description provided for @friendsVerificationHint.
  ///
  /// In ar, this message translates to:
  /// **'قل مرحباً — ملاحظة اختيارية'**
  String get friendsVerificationHint;

  /// No description provided for @friendsSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get friendsSend;

  /// No description provided for @friendsCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get friendsCancel;

  /// No description provided for @friendsAlreadyFriends.
  ///
  /// In ar, this message translates to:
  /// **'صديق'**
  String get friendsAlreadyFriends;

  /// No description provided for @friendsRequestAlert.
  ///
  /// In ar, this message translates to:
  /// **'طلب صداقة من {name}'**
  String friendsRequestAlert(String name);

  /// No description provided for @friendsViewRequests.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get friendsViewRequests;

  /// No description provided for @friendsEmployeeNote.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن للموظفين إضافة العملاء كأصدقاء.'**
  String get friendsEmployeeNote;

  /// No description provided for @friendsByPhone.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get friendsByPhone;

  /// No description provided for @friendsByQr.
  ///
  /// In ar, this message translates to:
  /// **'برمز QR'**
  String get friendsByQr;

  /// No description provided for @friendsMyQr.
  ///
  /// In ar, this message translates to:
  /// **'رمزي'**
  String get friendsMyQr;

  /// No description provided for @friendsScanQr.
  ///
  /// In ar, this message translates to:
  /// **'مسح QR'**
  String get friendsScanQr;

  /// No description provided for @friendsQrHint.
  ///
  /// In ar, this message translates to:
  /// **'اطلب من الصديق مسح رمزك، أو امسح رمزه لإضافة صداقة.'**
  String get friendsQrHint;

  /// No description provided for @friendsQrPayloadHint.
  ///
  /// In ar, this message translates to:
  /// **'أو الصق رمز OBIC هنا'**
  String get friendsQrPayloadHint;

  /// No description provided for @friendsQrInvalid.
  ///
  /// In ar, this message translates to:
  /// **'رمز QR غير صالح'**
  String get friendsQrInvalid;

  /// No description provided for @profileObicId.
  ///
  /// In ar, this message translates to:
  /// **'معرّف OBIC'**
  String get profileObicId;

  /// No description provided for @profileObicIdHint.
  ///
  /// In ar, this message translates to:
  /// **'6–20 حرفاً، يبدأ بحرف'**
  String get profileObicIdHint;

  /// No description provided for @profileObicIdFirstHint.
  ///
  /// In ar, this message translates to:
  /// **'عيّن معرّف OBIC ليجدك الأصدقاء. يمكن تغييره مرة كل سنة.'**
  String get profileObicIdFirstHint;

  /// No description provided for @profileObicIdYearHint.
  ///
  /// In ar, this message translates to:
  /// **'يمكن تغيير معرّف OBIC مرة كل 365 يوماً.'**
  String get profileObicIdYearHint;

  /// No description provided for @profileObicIdCooldownAt.
  ///
  /// In ar, this message translates to:
  /// **'التغيير التالي متاح في {date}'**
  String profileObicIdCooldownAt(Object date);

  /// No description provided for @profileObicIdCooldownData.
  ///
  /// In ar, this message translates to:
  /// **'يمكن تغيير معرّف OBIC مرة كل 365 يوماً. التالي في {date}.'**
  String profileObicIdCooldownData(Object date);

  /// No description provided for @profileObicIdCooldownHint.
  ///
  /// In ar, this message translates to:
  /// **'يمكن تغيير معرّف OBIC مرة كل 365 يوماً.'**
  String get profileObicIdCooldownHint;

  /// No description provided for @meObicId.
  ///
  /// In ar, this message translates to:
  /// **'معرّف OBIC'**
  String get meObicId;

  /// No description provided for @meObicIdUnset.
  ///
  /// In ar, this message translates to:
  /// **'غير معيّن'**
  String get meObicIdUnset;

  /// No description provided for @meMyQr.
  ///
  /// In ar, this message translates to:
  /// **'رمز QR الخاص بي'**
  String get meMyQr;

  /// No description provided for @chatComposeHint.
  ///
  /// In ar, this message translates to:
  /// **'رسالة…'**
  String get chatComposeHint;

  /// No description provided for @chatGroup.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة'**
  String get chatGroup;

  /// No description provided for @ordersTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get ordersTitle;

  /// No description provided for @ordersHint.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات ملكك فقط؛ الخادم يفرض التحقق من الملكية.'**
  String get ordersHint;

  /// No description provided for @meTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get meTitle;

  /// No description provided for @meFavorites.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة'**
  String get meFavorites;

  /// No description provided for @mePayServices.
  ///
  /// In ar, this message translates to:
  /// **'الدفع والخدمات'**
  String get mePayServices;

  /// No description provided for @payDemoBannerTitle.
  ///
  /// In ar, this message translates to:
  /// **'مثال للتجربة'**
  String get payDemoBannerTitle;

  /// No description provided for @payDemoBannerBody.
  ///
  /// In ar, this message translates to:
  /// **'هذه صفحة تجريبية للدفع والخدمات — عرض واجهة فقط، بدون مدفوعات حقيقية بعد.'**
  String get payDemoBannerBody;

  /// No description provided for @payDemoSectionMoney.
  ///
  /// In ar, this message translates to:
  /// **'المال'**
  String get payDemoSectionMoney;

  /// No description provided for @payDemoSectionShortcuts.
  ///
  /// In ar, this message translates to:
  /// **'اختصارات الخدمات'**
  String get payDemoSectionShortcuts;

  /// No description provided for @payDemoSectionOffers.
  ///
  /// In ar, this message translates to:
  /// **'عروض OBIC'**
  String get payDemoSectionOffers;

  /// No description provided for @payDemoWallet.
  ///
  /// In ar, this message translates to:
  /// **'المحفظة'**
  String get payDemoWallet;

  /// No description provided for @payDemoTransfer.
  ///
  /// In ar, this message translates to:
  /// **'تحويل'**
  String get payDemoTransfer;

  /// No description provided for @payDemoReceive.
  ///
  /// In ar, this message translates to:
  /// **'استلام'**
  String get payDemoReceive;

  /// No description provided for @payDemoCards.
  ///
  /// In ar, this message translates to:
  /// **'البطاقات'**
  String get payDemoCards;

  /// No description provided for @payDemoDailyServices.
  ///
  /// In ar, this message translates to:
  /// **'خدمات يومية'**
  String get payDemoDailyServices;

  /// No description provided for @payDemoVisa.
  ///
  /// In ar, this message translates to:
  /// **'تأشيرة'**
  String get payDemoVisa;

  /// No description provided for @payDemoBanking.
  ///
  /// In ar, this message translates to:
  /// **'بنوك'**
  String get payDemoBanking;

  /// No description provided for @payDemoTravel.
  ///
  /// In ar, this message translates to:
  /// **'سفر'**
  String get payDemoTravel;

  /// No description provided for @payDemoOfferVip.
  ///
  /// In ar, this message translates to:
  /// **'VIP الصين'**
  String get payDemoOfferVip;

  /// No description provided for @payDemoOfferPartner.
  ///
  /// In ar, this message translates to:
  /// **'عرض شريك'**
  String get payDemoOfferPartner;

  /// No description provided for @payDemoOfferSeasonal.
  ///
  /// In ar, this message translates to:
  /// **'موسمي'**
  String get payDemoOfferSeasonal;

  /// No description provided for @payDemoOfferComing.
  ///
  /// In ar, this message translates to:
  /// **'قريباً'**
  String get payDemoOfferComing;

  /// No description provided for @payDemoOpenRealServices.
  ///
  /// In ar, this message translates to:
  /// **'فتح تبويب الخدمات الكامل'**
  String get payDemoOpenRealServices;

  /// No description provided for @payDemoFooter.
  ///
  /// In ar, this message translates to:
  /// **'واجهة تجريبية للمنتج. المحفظة والمدفوعات الحقيقية لاحقاً.'**
  String get payDemoFooter;

  /// No description provided for @payDemoTileSnack.
  ///
  /// In ar, this message translates to:
  /// **'{label} — مثال فقط'**
  String payDemoTileSnack(String label);

  /// No description provided for @meMyPosts.
  ///
  /// In ar, this message translates to:
  /// **'منشوراتي'**
  String get meMyPosts;

  /// No description provided for @meWorks.
  ///
  /// In ar, this message translates to:
  /// **'الأعمال'**
  String get meWorks;

  /// No description provided for @meChannelHint.
  ///
  /// In ar, this message translates to:
  /// **'شاهد قناتي هنا'**
  String get meChannelHint;

  /// No description provided for @meStatus.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get meStatus;

  /// No description provided for @meFriendsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} أصدقاء'**
  String meFriendsCount(int count);

  /// No description provided for @meHint.
  ///
  /// In ar, this message translates to:
  /// **'الملف، اللغة، وتسجيل الدخول — بدون صلاحيات على الجهاز.'**
  String get meHint;

  /// No description provided for @meGuestHint.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول للدردشة واللحظات والطلبات والخدمات اليومية في الصين.'**
  String get meGuestHint;

  /// No description provided for @meRole.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get meRole;

  /// No description provided for @addressesTitle.
  ///
  /// In ar, this message translates to:
  /// **'عناويني'**
  String get addressesTitle;

  /// No description provided for @addressesAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنوان'**
  String get addressesAdd;

  /// No description provided for @addressesEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العنوان'**
  String get addressesEdit;

  /// No description provided for @addressesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عناوين محفوظة. أضف عنواناً لتوصيل الطعام والطلبات.'**
  String get addressesEmpty;

  /// No description provided for @addressesLabel.
  ///
  /// In ar, this message translates to:
  /// **'التسمية'**
  String get addressesLabel;

  /// No description provided for @addressesLine1.
  ///
  /// In ar, this message translates to:
  /// **'الشارع / المبنى'**
  String get addressesLine1;

  /// No description provided for @addressesLine2.
  ///
  /// In ar, this message translates to:
  /// **'الشقة / الطابق'**
  String get addressesLine2;

  /// No description provided for @addressesCity.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get addressesCity;

  /// No description provided for @addressesDistrict.
  ///
  /// In ar, this message translates to:
  /// **'الحي / المنطقة'**
  String get addressesDistrict;

  /// No description provided for @addressesNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات التوصيل'**
  String get addressesNotes;

  /// No description provided for @addressesOptional.
  ///
  /// In ar, this message translates to:
  /// **'اختياري'**
  String get addressesOptional;

  /// No description provided for @addressesSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ العنوان'**
  String get addressesSave;

  /// No description provided for @addressesSetDefault.
  ///
  /// In ar, this message translates to:
  /// **'العنوان الافتراضي'**
  String get addressesSetDefault;

  /// No description provided for @addressesDefaultBadge.
  ///
  /// In ar, this message translates to:
  /// **'افتراضي'**
  String get addressesDefaultBadge;

  /// No description provided for @addressesDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف العنوان؟'**
  String get addressesDeleteTitle;

  /// No description provided for @addressesDeleteBody.
  ///
  /// In ar, this message translates to:
  /// **'سيُزال هذا العنوان من ملفك.'**
  String get addressesDeleteBody;

  /// No description provided for @addressesDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get addressesDeleteConfirm;

  /// No description provided for @addressesRequiredFields.
  ///
  /// In ar, this message translates to:
  /// **'التسمية والشارع والمدينة مطلوبة.'**
  String get addressesRequiredFields;

  /// No description provided for @addressesPickTitle.
  ///
  /// In ar, this message translates to:
  /// **'التوصيل إلى'**
  String get addressesPickTitle;

  /// No description provided for @aboutObicBlurb.
  ///
  /// In ar, this message translates to:
  /// **'أوبك أكثر من خدمات — تطبيق اجتماعي لحياتك في الصين: دردشة ولحظات وطعام وفنادق وصحة وسفر.'**
  String get aboutObicBlurb;

  /// No description provided for @aboutCredit.
  ///
  /// In ar, this message translates to:
  /// **'صُنع بواسطة د. علي'**
  String get aboutCredit;

  /// No description provided for @languageToggle.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageToggle;

  /// No description provided for @authLogin.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get authRegister;

  /// No description provided for @authEmailTab.
  ///
  /// In ar, this message translates to:
  /// **'البريد'**
  String get authEmailTab;

  /// No description provided for @authPhoneTab.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get authPhoneTab;

  /// No description provided for @authUseSmsCode.
  ///
  /// In ar, this message translates to:
  /// **'الدخول برمز SMS'**
  String get authUseSmsCode;

  /// No description provided for @authUsePassword.
  ///
  /// In ar, this message translates to:
  /// **'الدخول بكلمة المرور'**
  String get authUsePassword;

  /// No description provided for @authSendCode.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرمز'**
  String get authSendCode;

  /// No description provided for @authSmsCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'الأرقام الجديدة تُسجَّل تلقائياً'**
  String get authSmsCodeHint;

  /// No description provided for @authUseEmail.
  ///
  /// In ar, this message translates to:
  /// **'استخدام البريد'**
  String get authUseEmail;

  /// No description provided for @authUsePhone.
  ///
  /// In ar, this message translates to:
  /// **'استخدام الهاتف'**
  String get authUsePhone;

  /// No description provided for @authEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get authEmail;

  /// No description provided for @authPhone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get authPhone;

  /// No description provided for @authName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get authName;

  /// No description provided for @authPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In ar, this message translates to:
  /// **'٨ أحرف على الأقل'**
  String get authPasswordHint;

  /// No description provided for @authSignIn.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get authSignIn;

  /// No description provided for @authCreateAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get authCreateAccount;

  /// No description provided for @authLogout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get authLogout;

  /// No description provided for @authOrContinue.
  ///
  /// In ar, this message translates to:
  /// **'أو تابع عبر'**
  String get authOrContinue;

  /// No description provided for @authContinueGoogle.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة عبر Google'**
  String get authContinueGoogle;

  /// No description provided for @authContinueApple.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة عبر Apple'**
  String get authContinueApple;

  /// No description provided for @authSocialNotConfigured.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول عبر Google أو Apple غير مُعد في هذا الإصدار بعد.'**
  String get authSocialNotConfigured;

  /// No description provided for @authProviderEmailNotVerified.
  ///
  /// In ar, this message translates to:
  /// **'لم تؤكد Apple أو Google هذا البريد، لذلك لن يتخطى OBIC التحقق من البريد.'**
  String get authProviderEmailNotVerified;

  /// No description provided for @authSocialRoleNotAllowed.
  ///
  /// In ar, this message translates to:
  /// **'هذا البريد لحساب موظفين. سجّل الدخول بكلمة المرور.'**
  String get authSocialRoleNotAllowed;

  /// No description provided for @authInvalidSocialToken.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحقق من تسجيل الدخول عبر Google أو Apple. حاول مرة أخرى.'**
  String get authInvalidSocialToken;

  /// No description provided for @authComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريباً'**
  String get authComingSoon;

  /// No description provided for @authEmailRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني'**
  String get authEmailRequired;

  /// No description provided for @authPhoneRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتفك'**
  String get authPhoneRequired;

  /// No description provided for @authFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تسجيل الدخول'**
  String get authFailed;

  /// No description provided for @authTotpHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز المكوّن من 6 أرقام من تطبيق المصادقة'**
  String get authTotpHint;

  /// No description provided for @authTotpCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز المصادقة'**
  String get authTotpCode;

  /// No description provided for @authTotpVerify.
  ///
  /// In ar, this message translates to:
  /// **'تحقق'**
  String get authTotpVerify;

  /// No description provided for @authTotpBack.
  ///
  /// In ar, this message translates to:
  /// **'العودة لتسجيل الدخول'**
  String get authTotpBack;

  /// No description provided for @authNetworkError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في الشبكة — تحقق من الاتصال وحاول مرة أخرى'**
  String get authNetworkError;

  /// No description provided for @authServerWaking.
  ///
  /// In ar, this message translates to:
  /// **'الخادم يستيقظ — انتظر ثوانٍ ثم حاول مجدداً'**
  String get authServerWaking;

  /// No description provided for @authStillConnecting.
  ///
  /// In ar, this message translates to:
  /// **'ما زلنا نتصل — قد يستغرق الخادم وقتاً حتى يستيقظ'**
  String get authStillConnecting;

  /// No description provided for @authRequiredTitle.
  ///
  /// In ar, this message translates to:
  /// **'يلزم تسجيل الدخول'**
  String get authRequiredTitle;

  /// No description provided for @authRequiredBody.
  ///
  /// In ar, this message translates to:
  /// **'التصفّح متاح للجميع. لطلب خدمة أو إرسال طلب أو الدردشة أو نشر لحظة أو إضافة أصدقاء، سجّل الدخول أو أنشئ حساباً.'**
  String get authRequiredBody;

  /// No description provided for @authClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get authClose;

  /// No description provided for @authWelcomeBack.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بعودتك'**
  String get authWelcomeBack;

  /// No description provided for @authJoinHeadline.
  ///
  /// In ar, this message translates to:
  /// **'انضم إلى أوبك'**
  String get authJoinHeadline;

  /// No description provided for @authSignInSupport.
  ///
  /// In ar, this message translates to:
  /// **'دردشة مع الأصدقاء · اطلب طعاماً · احجز فنادق · صحة والمزيد'**
  String get authSignInSupport;

  /// No description provided for @authRegisterSupport.
  ///
  /// In ar, this message translates to:
  /// **'دردشة ولحظات وطعام وفنادق وصحة وخدمات أوبك — في تطبيق واحد.'**
  String get authRegisterSupport;

  /// No description provided for @authForgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get authForgotPassword;

  /// No description provided for @authNoAccount.
  ///
  /// In ar, this message translates to:
  /// **'جديد هنا؟'**
  String get authNoAccount;

  /// No description provided for @authHasAccount.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get authHasAccount;

  /// No description provided for @authGoRegister.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حساباً'**
  String get authGoRegister;

  /// No description provided for @authGoLogin.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get authGoLogin;

  /// No description provided for @actionRequestService.
  ///
  /// In ar, this message translates to:
  /// **'طلب هذه الخدمة'**
  String get actionRequestService;

  /// No description provided for @actionPlaceOrder.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء طلب'**
  String get actionPlaceOrder;

  /// No description provided for @actionChatStaff.
  ///
  /// In ar, this message translates to:
  /// **'محادثة مع الفريق'**
  String get actionChatStaff;

  /// No description provided for @obicAiTitle.
  ///
  /// In ar, this message translates to:
  /// **'أوبك AI'**
  String get obicAiTitle;

  /// No description provided for @obicAiWelcome.
  ///
  /// In ar, this message translates to:
  /// **'اسأل عن أي خدمة في التطبيق: عقارات، نقل، سفر، صحة، طعام، تسوق، تعليم، شحن، حكومة، أعمال، تأشيرات، فنادق، عروض أو فروع، أو عن حالة طلبك. الفريق جاهز للمساعدة دائماً.'**
  String get obicAiWelcome;

  /// No description provided for @obicAiInputHint.
  ///
  /// In ar, this message translates to:
  /// **'اسأل أوبك AI…'**
  String get obicAiInputHint;

  /// No description provided for @obicAiOfflineHint.
  ///
  /// In ar, this message translates to:
  /// **'مساعد أوبك غير مفعّل على هذا الخادم بعد. يمكنك محادثة الفريق.'**
  String get obicAiOfflineHint;

  /// No description provided for @obicAiEmptyReply.
  ///
  /// In ar, this message translates to:
  /// **'لا رد بعد — أعد المحاولة أو تواصل مع الفريق.'**
  String get obicAiEmptyReply;

  /// No description provided for @obicAiTabInstructions.
  ///
  /// In ar, this message translates to:
  /// **'دليل'**
  String get obicAiTabInstructions;

  /// No description provided for @obicAiTabChat.
  ///
  /// In ar, this message translates to:
  /// **'محادثة'**
  String get obicAiTabChat;

  /// No description provided for @obicAiTabHistory.
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get obicAiTabHistory;

  /// No description provided for @obicAiNewChat.
  ///
  /// In ar, this message translates to:
  /// **'محادثة جديدة'**
  String get obicAiNewChat;

  /// No description provided for @obicAiHistoryEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا محادثات سابقة بعد. اسأل في تبويب المحادثة وستظهر هنا.'**
  String get obicAiHistoryEmpty;

  /// No description provided for @obicAiHistoryOpen.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get obicAiHistoryOpen;

  /// No description provided for @obicAiHistoryDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get obicAiHistoryDelete;

  /// No description provided for @obicAiCopy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get obicAiCopy;

  /// No description provided for @obicAiCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get obicAiCopied;

  /// No description provided for @obicAiNothingToCopy.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد نص للنسخ'**
  String get obicAiNothingToCopy;

  /// No description provided for @obicAiRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإجابة'**
  String get obicAiRetry;

  /// No description provided for @obicAiStop.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get obicAiStop;

  /// No description provided for @obicAiAttach.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق'**
  String get obicAiAttach;

  /// No description provided for @obicAiAttachPhoto.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get obicAiAttachPhoto;

  /// No description provided for @obicAiAttachPdf.
  ///
  /// In ar, this message translates to:
  /// **'PDF'**
  String get obicAiAttachPdf;

  /// No description provided for @obicAiAttachSheet.
  ///
  /// In ar, this message translates to:
  /// **'جدول'**
  String get obicAiAttachSheet;

  /// No description provided for @obicAiRemoveAttachment.
  ///
  /// In ar, this message translates to:
  /// **'إزالة المرفق'**
  String get obicAiRemoveAttachment;

  /// No description provided for @obicAiFileTooLarge.
  ///
  /// In ar, this message translates to:
  /// **'الملف أكبر من ٤ ميغابايت. اختر ملفاً أصغر.'**
  String get obicAiFileTooLarge;

  /// No description provided for @obicAiUnsupportedFile.
  ///
  /// In ar, this message translates to:
  /// **'يُقبل فقط صور JPEG أو PNG أو WebP، أو PDF، أو Excel أو CSV.'**
  String get obicAiUnsupportedFile;

  /// No description provided for @obicAiAttachmentNotConfigured.
  ///
  /// In ar, this message translates to:
  /// **'قراءة الصور والملفات غير مهيأة.'**
  String get obicAiAttachmentNotConfigured;

  /// No description provided for @obicAiCouldNotReadFile.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر قراءة هذا الملف.'**
  String get obicAiCouldNotReadFile;

  /// No description provided for @obicAiInstructionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف تستخدم أوبك AI'**
  String get obicAiInstructionsTitle;

  /// No description provided for @obicAiInstructionsBody.
  ///
  /// In ar, this message translates to:
  /// **'ماذا يفعل أوبك AI\n• يجيب عن كامل كتالوج الخدمات: عقارات، نقل، سفر، رعاية صحية، طعام، تسوق، تعليم، شحن، خدمات حكومية وأعمال، بما فيها التأشيرات والفنادق والتوصيل وباقي البنود، إضافة إلى العروض والفروع.\n• يرد بلغتك — العربية والإنجليزية والصينية والفرنسية وغيرها. اكتب بحرية؛ يطابق لغتك.\n\nهذه الشاشة مقابل الرد التلقائي\n• تبويب المحادثة هو مساعدك المخصص. السجل يحفظ الأسئلة والأجوبة لتعود إليها لاحقاً.\n• محادثات الدعم والطلبات قد تحصل أيضاً على رد تلقائي قصير من الذكاء الاصطناعي.\n• محادثات الأصدقاء تبقى خاصة — بلا ذكاء اصطناعي.\n\nتحدث مع الفريق\n• للمساعدة البشرية: الرسائل ← دعم أوبك أو محادثة طلب ← تحدث مع الفريق.\n\nاللغات\n• لغة التطبيق (ع / EN / 中文 / FR) تتحكم بعناوين هذه الشاشة.\n• لغة رسالتك تتحكم برد المساعد.'**
  String get obicAiInstructionsBody;

  /// No description provided for @obicAiBalance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد: {amount}'**
  String obicAiBalance(String amount);

  /// No description provided for @obicAiTopUp.
  ///
  /// In ar, this message translates to:
  /// **'شحن'**
  String get obicAiTopUp;

  /// No description provided for @obicAiTopUpTitle.
  ///
  /// In ar, this message translates to:
  /// **'شحن رصيد أوبك AI'**
  String get obicAiTopUpTitle;

  /// No description provided for @obicAiTopUpBody.
  ///
  /// In ar, this message translates to:
  /// **'الدفعة الأولى ¥200 وتصبح رصيدك. بعد ذلك يُخصم من الرصيد: سؤال نصي ¥0.10، صورة ¥0.20، ملف PDF أو جدول ¥0.20. إذا لم يكفِ الرصيد للاستخدام التالي، يتوقف أوبك AI حتى تشحن باقة ¥200.'**
  String get obicAiTopUpBody;

  /// No description provided for @obicAiSandboxTopUp.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الشحن التجريبي ¥200'**
  String get obicAiSandboxTopUp;

  /// No description provided for @obicAiSandboxNote.
  ///
  /// In ar, this message translates to:
  /// **'تجريبي: لا يُخصم مال حقيقي.'**
  String get obicAiSandboxNote;

  /// No description provided for @obicAiTopUpSuccess.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت ¥200 إلى رصيدك (تجريبي).'**
  String get obicAiTopUpSuccess;

  /// No description provided for @obicAiBalanceLow.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد غير كافٍ. اشحن باقة ¥200 للمتابعة.'**
  String get obicAiBalanceLow;

  /// No description provided for @obicAiTopUpFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الشحن. أعد المحاولة.'**
  String get obicAiTopUpFailed;

  /// No description provided for @obicAiCardNotConnected.
  ///
  /// In ar, this message translates to:
  /// **'الدفع بالبطاقة غير متصل بعد.'**
  String get obicAiCardNotConnected;

  /// No description provided for @msgTranslate.
  ///
  /// In ar, this message translates to:
  /// **'ترجمة'**
  String get msgTranslate;

  /// No description provided for @msgShowOriginal.
  ///
  /// In ar, this message translates to:
  /// **'إظهار الأصل'**
  String get msgShowOriginal;

  /// No description provided for @msgShowTranslation.
  ///
  /// In ar, this message translates to:
  /// **'إظهار الترجمة'**
  String get msgShowTranslation;

  /// No description provided for @msgTranslating.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الترجمة…'**
  String get msgTranslating;

  /// No description provided for @msgTranslateFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت الترجمة — أعد المحاولة.'**
  String get msgTranslateFailed;

  /// No description provided for @authSuccessContinue.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدخول — يمكنك المتابعة.'**
  String get authSuccessContinue;

  /// No description provided for @brandTag.
  ///
  /// In ar, this message translates to:
  /// **'دردشة · طعام · فنادق · صحة والمزيد'**
  String get brandTag;

  /// No description provided for @searchPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن طعام، فنادق، صحة، تأشيرات…'**
  String get searchPlaceholder;

  /// No description provided for @featured.
  ///
  /// In ar, this message translates to:
  /// **'مميز'**
  String get featured;

  /// No description provided for @vipTrip.
  ///
  /// In ar, this message translates to:
  /// **'رحلة VIP إلى الصين'**
  String get vipTrip;

  /// No description provided for @vipTripDesc.
  ///
  /// In ar, this message translates to:
  /// **'استقبال من المطار · فنادق · زيارات مصانع · مدير مخصص'**
  String get vipTripDesc;

  /// No description provided for @bookPkg.
  ///
  /// In ar, this message translates to:
  /// **'احجز الباقة ←'**
  String get bookPkg;

  /// No description provided for @fastTrack.
  ///
  /// In ar, this message translates to:
  /// **'مسار سريع'**
  String get fastTrack;

  /// No description provided for @visaExpress.
  ///
  /// In ar, this message translates to:
  /// **'تأشيرة سريعة'**
  String get visaExpress;

  /// No description provided for @visaExpressDesc.
  ///
  /// In ar, this message translates to:
  /// **'دعم تأشيرات العمل والسياحة مع قائمة مستندات ومستشار'**
  String get visaExpressDesc;

  /// No description provided for @from120.
  ///
  /// In ar, this message translates to:
  /// **'من 120\$ ←'**
  String get from120;

  /// No description provided for @setup.
  ///
  /// In ar, this message translates to:
  /// **'تهيئة'**
  String get setup;

  /// No description provided for @openBank.
  ///
  /// In ar, this message translates to:
  /// **'فتح حساب بنكي'**
  String get openBank;

  /// No description provided for @openBankDesc.
  ///
  /// In ar, this message translates to:
  /// **'فتح حساب محلي بإرشاد وتنسيق مع الفرع'**
  String get openBankDesc;

  /// No description provided for @startReq.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الطلب ←'**
  String get startReq;

  /// No description provided for @topServices.
  ///
  /// In ar, this message translates to:
  /// **'أبرز الخدمات'**
  String get topServices;

  /// No description provided for @seeAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get seeAll;

  /// No description provided for @recommended.
  ///
  /// In ar, this message translates to:
  /// **'موصى به'**
  String get recommended;

  /// No description provided for @regionDetecting.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحديد موقعك…'**
  String get regionDetecting;

  /// No description provided for @regionRefresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get regionRefresh;

  /// No description provided for @regionUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متوفرة في هذه المنطقة'**
  String get regionUnavailable;

  /// No description provided for @nearMeTitle.
  ///
  /// In ar, this message translates to:
  /// **'مكاتب قريبة منك'**
  String get nearMeTitle;

  /// No description provided for @nearMeHint.
  ///
  /// In ar, this message translates to:
  /// **'مرتّبة حسب المسافة من موقعك'**
  String get nearMeHint;

  /// No description provided for @allServices.
  ///
  /// In ar, this message translates to:
  /// **'كل الخدمات'**
  String get allServices;

  /// No description provided for @serviceLabel.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة'**
  String get serviceLabel;

  /// No description provided for @officialBadge.
  ///
  /// In ar, this message translates to:
  /// **'رسمي من OBIC'**
  String get officialBadge;

  /// No description provided for @includedTitle.
  ///
  /// In ar, this message translates to:
  /// **'ما يشمله'**
  String get includedTitle;

  /// No description provided for @advisorTitle.
  ///
  /// In ar, this message translates to:
  /// **'مستشار مخصص'**
  String get advisorTitle;

  /// No description provided for @advisorDesc.
  ///
  /// In ar, this message translates to:
  /// **'يُعيَّن بعد تقديم الطلب'**
  String get advisorDesc;

  /// No description provided for @checklistTitle.
  ///
  /// In ar, this message translates to:
  /// **'قائمة المستندات'**
  String get checklistTitle;

  /// No description provided for @checklistDesc.
  ///
  /// In ar, this message translates to:
  /// **'خطوات واضحة في طلبك'**
  String get checklistDesc;

  /// No description provided for @statusUpdatesTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديثات الحالة'**
  String get statusUpdatesTitle;

  /// No description provided for @statusUpdatesDesc.
  ///
  /// In ar, this message translates to:
  /// **'تابع التقدم في الطلبات'**
  String get statusUpdatesDesc;

  /// No description provided for @requestSvc.
  ///
  /// In ar, this message translates to:
  /// **'اطلب هذه الخدمة'**
  String get requestSvc;

  /// No description provided for @chatSupport.
  ///
  /// In ar, this message translates to:
  /// **'محادثة الدعم'**
  String get chatSupport;

  /// No description provided for @chatComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'جاري فتح محادثة الدعم…'**
  String get chatComingSoon;

  /// No description provided for @requestTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب'**
  String get requestTitle;

  /// No description provided for @prefBranch.
  ///
  /// In ar, this message translates to:
  /// **'الفرع المفضل'**
  String get prefBranch;

  /// No description provided for @notesLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get notesLabel;

  /// No description provided for @notesHint.
  ///
  /// In ar, this message translates to:
  /// **'التواريخ، الأهداف، المستندات...'**
  String get notesHint;

  /// No description provided for @submitOrder.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب'**
  String get submitOrder;

  /// No description provided for @orderSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال الطلب بنجاح.'**
  String get orderSubmitted;

  /// No description provided for @ordersEmptyGuest.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لعرض طلباتك.'**
  String get ordersEmptyGuest;

  /// No description provided for @ordersEmptyAuth.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات بعد — اطلب خدمة من الرئيسية أو تواصل مع فريق أوبك.'**
  String get ordersEmptyAuth;

  /// No description provided for @statusSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'مُقدَّم'**
  String get statusSubmitted;

  /// No description provided for @statusInProgress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get statusInProgress;

  /// No description provided for @statusAssigned.
  ///
  /// In ar, this message translates to:
  /// **'مُعيَّن'**
  String get statusAssigned;

  /// No description provided for @statusWaitingCustomer.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار العميل'**
  String get statusWaitingCustomer;

  /// No description provided for @statusCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغى'**
  String get statusCancelled;

  /// No description provided for @statusOpen.
  ///
  /// In ar, this message translates to:
  /// **'مفتوح'**
  String get statusOpen;

  /// No description provided for @statusWithAgent.
  ///
  /// In ar, this message translates to:
  /// **'مع الموظف'**
  String get statusWithAgent;

  /// No description provided for @requestTypeSupport.
  ///
  /// In ar, this message translates to:
  /// **'دعم أوبك'**
  String get requestTypeSupport;

  /// No description provided for @orderChat.
  ///
  /// In ar, this message translates to:
  /// **'محادثة حول هذا الطلب'**
  String get orderChat;

  /// No description provided for @legalTerms.
  ///
  /// In ar, this message translates to:
  /// **'الشروط'**
  String get legalTerms;

  /// No description provided for @legalPrivacy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get legalPrivacy;

  /// No description provided for @legalAgreePrefix.
  ///
  /// In ar, this message translates to:
  /// **'بإنشاء حساب فإنك توافق على'**
  String get legalAgreePrefix;

  /// No description provided for @legalAnd.
  ///
  /// In ar, this message translates to:
  /// **'و'**
  String get legalAnd;

  /// No description provided for @offlineBanner.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الشبكة…'**
  String get offlineBanner;

  /// No description provided for @offlineConnecting.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الاتصال…'**
  String get offlineConnecting;

  /// No description provided for @offlineNeedsNetwork.
  ///
  /// In ar, this message translates to:
  /// **'أنت غير متصل — أعد المحاولة عند توفر الإنترنت.'**
  String get offlineNeedsNetwork;

  /// No description provided for @offlineNoInternet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت. تحقق من إعدادات الشبكة'**
  String get offlineNoInternet;

  /// No description provided for @msgWaitingNetwork.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الشبكة…'**
  String get msgWaitingNetwork;

  /// No description provided for @msgTapToResend.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لإعادة الإرسال'**
  String get msgTapToResend;

  /// No description provided for @networkUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الشبكة غير متاحة. حاول مرة أخرى.'**
  String get networkUnavailable;

  /// No description provided for @actionOk.
  ///
  /// In ar, this message translates to:
  /// **'حسناً'**
  String get actionOk;

  /// No description provided for @actionCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get actionCancel;

  /// No description provided for @chatDayToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get chatDayToday;

  /// No description provided for @chatDayYesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get chatDayYesterday;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get settingsAccount;

  /// No description provided for @settingsGeneral.
  ///
  /// In ar, this message translates to:
  /// **'عام'**
  String get settingsGeneral;

  /// No description provided for @settingsFeatures.
  ///
  /// In ar, this message translates to:
  /// **'الميزات'**
  String get settingsFeatures;

  /// No description provided for @settingsProfile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get settingsProfile;

  /// No description provided for @settingsAccountSecurity.
  ///
  /// In ar, this message translates to:
  /// **'أمان الحساب'**
  String get settingsAccountSecurity;

  /// No description provided for @settingsNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get settingsNotifications;

  /// No description provided for @settingsMomentsNotifications.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات اللحظات'**
  String get settingsMomentsNotifications;

  /// No description provided for @settingsMomentsNotifyFriends.
  ///
  /// In ar, this message translates to:
  /// **'أعلمني عند نشر الأصدقاء للحظات'**
  String get settingsMomentsNotifyFriends;

  /// No description provided for @settingsMomentsMute.
  ///
  /// In ar, this message translates to:
  /// **'كتم تحديثات اللحظات'**
  String get settingsMomentsMute;

  /// No description provided for @settingsInterface.
  ///
  /// In ar, this message translates to:
  /// **'اللغة والعرض'**
  String get settingsInterface;

  /// No description provided for @settingsFriendsPermissions.
  ///
  /// In ar, this message translates to:
  /// **'صلاحيات الأصدقاء'**
  String get settingsFriendsPermissions;

  /// No description provided for @settingsStorage.
  ///
  /// In ar, this message translates to:
  /// **'التخزين'**
  String get settingsStorage;

  /// No description provided for @settingsChats.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات'**
  String get settingsChats;

  /// No description provided for @settingsVoiceVideo.
  ///
  /// In ar, this message translates to:
  /// **'المكالمات الصوتية والمرئية'**
  String get settingsVoiceVideo;

  /// No description provided for @profileName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get profileName;

  /// No description provided for @profilePhoto.
  ///
  /// In ar, this message translates to:
  /// **'صورة الملف'**
  String get profilePhoto;

  /// No description provided for @profileGender.
  ///
  /// In ar, this message translates to:
  /// **'الجنس'**
  String get profileGender;

  /// No description provided for @profileGenderMale.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get profileGenderMale;

  /// No description provided for @profileGenderFemale.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get profileGenderFemale;

  /// No description provided for @profileGenderOther.
  ///
  /// In ar, this message translates to:
  /// **'آخر'**
  String get profileGenderOther;

  /// No description provided for @profileGenderUnset.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get profileGenderUnset;

  /// No description provided for @profileRegion.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة'**
  String get profileRegion;

  /// No description provided for @profileMobile.
  ///
  /// In ar, this message translates to:
  /// **'رقم الجوال'**
  String get profileMobile;

  /// No description provided for @profileWhatsUp.
  ///
  /// In ar, this message translates to:
  /// **'ماذا يحدث'**
  String get profileWhatsUp;

  /// No description provided for @profileWhatsUpHint.
  ///
  /// In ar, this message translates to:
  /// **'سطر حالة قصير يراه الأصدقاء على ألبومك'**
  String get profileWhatsUpHint;

  /// No description provided for @profileMyQr.
  ///
  /// In ar, this message translates to:
  /// **'رمز QR الخاص بي'**
  String get profileMyQr;

  /// No description provided for @profileId.
  ///
  /// In ar, this message translates to:
  /// **'المعرّف'**
  String get profileId;

  /// No description provided for @momentsPin.
  ///
  /// In ar, this message translates to:
  /// **'مثبّت'**
  String get momentsPin;

  /// No description provided for @profilePhone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get profilePhone;

  /// No description provided for @profileEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد'**
  String get profileEmail;

  /// No description provided for @profileCity.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get profileCity;

  /// No description provided for @profileCountry.
  ///
  /// In ar, this message translates to:
  /// **'البلد'**
  String get profileCountry;

  /// No description provided for @profileEmailReadOnly.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تغيير البريد من هنا'**
  String get profileEmailReadOnly;

  /// No description provided for @profileSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الملف'**
  String get profileSaved;

  /// No description provided for @securityChangePassword.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get securityChangePassword;

  /// No description provided for @securityCurrentPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية'**
  String get securityCurrentPassword;

  /// No description provided for @securityNewPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get securityNewPassword;

  /// No description provided for @securityPasswordChanged.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث كلمة المرور'**
  String get securityPasswordChanged;

  /// No description provided for @securityLinkedAccounts.
  ///
  /// In ar, this message translates to:
  /// **'طرق تسجيل الدخول'**
  String get securityLinkedAccounts;

  /// No description provided for @friendsMuteMoments.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء لحظاته'**
  String get friendsMuteMoments;

  /// No description provided for @friendsMuteMomentsHint.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء لحظاته من قائمتك وإيقاف الشارات والإشعارات'**
  String get friendsMuteMomentsHint;

  /// No description provided for @friendsHideMyMoments.
  ///
  /// In ar, this message translates to:
  /// **'عدم السماح له برؤية لحظاتي'**
  String get friendsHideMyMoments;

  /// No description provided for @friendsNoFriends.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أصدقاء بعد'**
  String get friendsNoFriends;

  /// No description provided for @storageClearCache.
  ///
  /// In ar, this message translates to:
  /// **'مسح التخزين المؤقت'**
  String get storageClearCache;

  /// No description provided for @storageCleared.
  ///
  /// In ar, this message translates to:
  /// **'تم المسح'**
  String get storageCleared;

  /// No description provided for @storageCacheHint.
  ///
  /// In ar, this message translates to:
  /// **'يمسح اللحظات والمحادثات والنسخ دون اتصال على هذا الجهاز'**
  String get storageCacheHint;

  /// No description provided for @storageClearConfirm.
  ///
  /// In ar, this message translates to:
  /// **'مسح الصور والملفات المؤقتة على هذا الهاتف؟ المحادثات وتسجيل الدخول تبقى.'**
  String get storageClearConfirm;

  /// No description provided for @storageFreed.
  ///
  /// In ar, this message translates to:
  /// **'تم تحرير {size}'**
  String storageFreed(String size);

  /// No description provided for @storageImages.
  ///
  /// In ar, this message translates to:
  /// **'الصور'**
  String get storageImages;

  /// No description provided for @storageVideos.
  ///
  /// In ar, this message translates to:
  /// **'الفيديو'**
  String get storageVideos;

  /// No description provided for @storageVoice.
  ///
  /// In ar, this message translates to:
  /// **'الصوت'**
  String get storageVoice;

  /// No description provided for @storageFiles.
  ///
  /// In ar, this message translates to:
  /// **'الملفات'**
  String get storageFiles;

  /// No description provided for @storageMusic.
  ///
  /// In ar, this message translates to:
  /// **'الموسيقى المنزّلة'**
  String get storageMusic;

  /// No description provided for @storageChats.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات'**
  String get storageChats;

  /// No description provided for @storageChatsHint.
  ///
  /// In ar, this message translates to:
  /// **'تبقى على هذا الهاتف. مسح التخزين المؤقت لا يحذفها.'**
  String get storageChatsHint;

  /// No description provided for @storageClearMusic.
  ///
  /// In ar, this message translates to:
  /// **'مسح الموسيقى المنزّلة'**
  String get storageClearMusic;

  /// No description provided for @storageAutoDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف التخزين المؤقت القديم'**
  String get storageAutoDelete;

  /// No description provided for @storageAutoNever.
  ///
  /// In ar, this message translates to:
  /// **'أبداً'**
  String get storageAutoNever;

  /// No description provided for @storageAutoDays.
  ///
  /// In ar, this message translates to:
  /// **'{days} يوم'**
  String storageAutoDays(int days);

  /// No description provided for @chatsEnterSend.
  ///
  /// In ar, this message translates to:
  /// **'Enter للإرسال'**
  String get chatsEnterSend;

  /// No description provided for @chatsConfirmDelete.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد قبل حذف الرسائل'**
  String get chatsConfirmDelete;

  /// No description provided for @voiceSpeakerDefault.
  ///
  /// In ar, this message translates to:
  /// **'مكبر الصوت افتراضياً في المكالمات الصوتية'**
  String get voiceSpeakerDefault;

  /// No description provided for @voiceVideoPreview.
  ///
  /// In ar, this message translates to:
  /// **'إظهار معاينة الفيديو'**
  String get voiceVideoPreview;

  /// No description provided for @settingsSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ'**
  String get settingsSaved;

  /// No description provided for @switchAccountTitle.
  ///
  /// In ar, this message translates to:
  /// **'تبديل الحساب'**
  String get switchAccountTitle;

  /// No description provided for @switchAccountHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط صورة الملف لتبديل الحسابات'**
  String get switchAccountHint;

  /// No description provided for @switchAccountAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة حساب'**
  String get switchAccountAdd;

  /// No description provided for @momentsCopyLink.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الرابط'**
  String get momentsCopyLink;

  /// No description provided for @momentsCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الرابط'**
  String get momentsCopied;

  /// No description provided for @momentsCopyText.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get momentsCopyText;

  /// No description provided for @momentsTextCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get momentsTextCopied;

  /// No description provided for @momentsTranslate.
  ///
  /// In ar, this message translates to:
  /// **'ترجمة'**
  String get momentsTranslate;

  /// No description provided for @momentsMyAlbum.
  ///
  /// In ar, this message translates to:
  /// **'لحظاتي'**
  String get momentsMyAlbum;

  /// No description provided for @momentsFriendAlbum.
  ///
  /// In ar, this message translates to:
  /// **'لحظات {name}'**
  String momentsFriendAlbum(String name);

  /// No description provided for @momentsCoverTapHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على الغلاف للتغيير'**
  String get momentsCoverTapHint;

  /// No description provided for @momentsCoverAdjust.
  ///
  /// In ar, this message translates to:
  /// **'ضبط الغلاف'**
  String get momentsCoverAdjust;

  /// No description provided for @momentsCoverSave.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get momentsCoverSave;

  /// No description provided for @momentsCoverAdjustHint.
  ///
  /// In ar, this message translates to:
  /// **'اسحب للتحريك · قرّب للتكبير · ثم اضغط تم'**
  String get momentsCoverAdjustHint;

  /// No description provided for @channelTitle.
  ///
  /// In ar, this message translates to:
  /// **'القنوات'**
  String get channelTitle;

  /// No description provided for @callErrorGeneric.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال — حاول مرة أخرى'**
  String get callErrorGeneric;

  /// No description provided for @callErrorPermission.
  ///
  /// In ar, this message translates to:
  /// **'يلزم إذن الكاميرا أو الميكروفون'**
  String get callErrorPermission;

  /// No description provided for @callErrorJoin.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر بدء المكالمة — تحقق من الشبكة وحاول مجدداً'**
  String get callErrorJoin;

  /// No description provided for @settingsSystem.
  ///
  /// In ar, this message translates to:
  /// **'النظام'**
  String get settingsSystem;

  /// No description provided for @settingsDarkMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الداكن'**
  String get settingsDarkMode;

  /// No description provided for @settingsSupportSafety.
  ///
  /// In ar, this message translates to:
  /// **'الدعم والأمان'**
  String get settingsSupportSafety;

  /// No description provided for @settingsContactSupport.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الدعم'**
  String get settingsContactSupport;

  /// No description provided for @settingsReportBug.
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ عن عطل'**
  String get settingsReportBug;

  /// No description provided for @settingsRestoreAccount.
  ///
  /// In ar, this message translates to:
  /// **'استعادة الحساب'**
  String get settingsRestoreAccount;

  /// No description provided for @restoreAccountHint.
  ///
  /// In ar, this message translates to:
  /// **'اطلب من موظفي OBIC استعادة الحساب من لوحة الإدارة'**
  String get restoreAccountHint;

  /// No description provided for @restoreAccountDialog.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد استعادة ذاتية. تواصل مع دعم OBIC بالبريد أو الهاتف — المشرف الأعلى أو موظف Ops يستعيد الحساب من الإدارة. بعد الاستعادة سجّل الدخول بنفس كلمة المرور.'**
  String get restoreAccountDialog;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In ar, this message translates to:
  /// **'سيتم تعطيل حسابك وتسجيل خروجك من هذا الجهاز. يمكن للموظفين استعادته من لوحة الإدارة عند الحاجة.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountPasswordRequired.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية (مطلوبة)'**
  String get deleteAccountPasswordRequired;

  /// No description provided for @deleteAccountSuperAdminRule.
  ///
  /// In ar, this message translates to:
  /// **'المشرف الأعلى: يمكنك حذف هذا الحساب فقط إن وُجد مشرف أعلى آخر نشط. لا يمكن حذف آخر مشرف أعلى.'**
  String get deleteAccountSuperAdminRule;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountDone.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الحساب من هذا الجهاز'**
  String get deleteAccountDone;

  /// No description provided for @reportBugTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ عن عطل'**
  String get reportBugTitle;

  /// No description provided for @reportBugDescriptionHint.
  ///
  /// In ar, this message translates to:
  /// **'صف المشكلة (5 أحرف على الأقل)'**
  String get reportBugDescriptionHint;

  /// No description provided for @reportBugAddPhotos.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صور'**
  String get reportBugAddPhotos;

  /// No description provided for @reportBugSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get reportBugSubmit;

  /// No description provided for @reportBugThanks.
  ///
  /// In ar, this message translates to:
  /// **'شكراً — سيراجع الفريق بلاغك'**
  String get reportBugThanks;

  /// No description provided for @reportBugTooShort.
  ///
  /// In ar, this message translates to:
  /// **'أضف المزيد من التفاصيل'**
  String get reportBugTooShort;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'مثل النظام'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @chatMute.
  ///
  /// In ar, this message translates to:
  /// **'كتم الإشعارات'**
  String get chatMute;

  /// No description provided for @chatUnmute.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الكتم'**
  String get chatUnmute;

  /// No description provided for @chatMuted.
  ///
  /// In ar, this message translates to:
  /// **'تم كتم المحادثة'**
  String get chatMuted;

  /// No description provided for @chatUnmuted.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الكتم'**
  String get chatUnmuted;

  /// No description provided for @chatHide.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء المحادثة'**
  String get chatHide;

  /// No description provided for @chatHideConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء من القائمة؟ فتحها مجدداً يعيدها.'**
  String get chatHideConfirm;

  /// No description provided for @chatClearHistory.
  ///
  /// In ar, this message translates to:
  /// **'مسح السجل'**
  String get chatClearHistory;

  /// No description provided for @chatClearHistoryConfirm.
  ///
  /// In ar, this message translates to:
  /// **'مسح الرسائل لك فقط؟ لا يمكن التراجع.'**
  String get chatClearHistoryConfirm;

  /// No description provided for @chatDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف المحادثة'**
  String get chatDelete;

  /// No description provided for @chatDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف المحادثة من القائمة ومسح السجل لك؟'**
  String get chatDeleteConfirm;

  /// No description provided for @chatMarkUnread.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كغير مقروء'**
  String get chatMarkUnread;

  /// No description provided for @chatPin.
  ///
  /// In ar, this message translates to:
  /// **'تثبيت في الأعلى'**
  String get chatPin;

  /// No description provided for @chatUnpin.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التثبيت'**
  String get chatUnpin;

  /// No description provided for @chatDraftPrefix.
  ///
  /// In ar, this message translates to:
  /// **'[مسودة]'**
  String get chatDraftPrefix;

  /// No description provided for @chatRecall.
  ///
  /// In ar, this message translates to:
  /// **'سحب الرسالة'**
  String get chatRecall;

  /// No description provided for @chatRecalledYou.
  ///
  /// In ar, this message translates to:
  /// **'لقد سحبت رسالة'**
  String get chatRecalledYou;

  /// No description provided for @chatRecalledPeer.
  ///
  /// In ar, this message translates to:
  /// **'تم سحب رسالة'**
  String get chatRecalledPeer;

  /// No description provided for @errorProfileFieldsUnsupported.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ الملف. حدّث التطبيق وحاول مجدداً.'**
  String get errorProfileFieldsUnsupported;

  /// No description provided for @errorWrongPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية غير صحيحة'**
  String get errorWrongPassword;

  /// No description provided for @errorEmailTaken.
  ///
  /// In ar, this message translates to:
  /// **'البريد مستخدم مسبقاً'**
  String get errorEmailTaken;

  /// No description provided for @errorObicIdTaken.
  ///
  /// In ar, this message translates to:
  /// **'معرّف OBIC مستخدم مسبقاً'**
  String get errorObicIdTaken;

  /// No description provided for @errorGenericRetry.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ — حاول مجدداً'**
  String get errorGenericRetry;

  /// No description provided for @errorUploadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر رفع الصورة — جرّب صورة أخرى'**
  String get errorUploadFailed;

  /// No description provided for @errorMomentsCoverFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديث غلاف اللحظات — حاول مجدداً'**
  String get errorMomentsCoverFailed;

  /// No description provided for @errorOnlySecretaryCanUpdateStatus.
  ///
  /// In ar, this message translates to:
  /// **'السكرتير فقط يمكنه تحديث الحالة'**
  String get errorOnlySecretaryCanUpdateStatus;

  /// No description provided for @profileObicIdCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ معرّف OBIC'**
  String get profileObicIdCopied;

  /// No description provided for @profileSetObicId.
  ///
  /// In ar, this message translates to:
  /// **'تعيين معرّف OBIC'**
  String get profileSetObicId;

  /// No description provided for @profileChangeObicId.
  ///
  /// In ar, this message translates to:
  /// **'تغيير المعرّف'**
  String get profileChangeObicId;

  /// No description provided for @profileEmailPasswordRequired.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية (لتغيير البريد)'**
  String get profileEmailPasswordRequired;

  /// No description provided for @profileEmailChangeHint.
  ///
  /// In ar, this message translates to:
  /// **'تغيير البريد يتطلب كلمة المرور. البريد القديم يتوقف عن تسجيل الدخول.'**
  String get profileEmailChangeHint;

  /// No description provided for @settingsLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get settingsLanguage;

  /// No description provided for @verifyOtpTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التحقق'**
  String get verifyOtpTitle;

  /// No description provided for @verifyOtpEmailHint.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا رمزاً من 6 أرقام إلى بريدك'**
  String get verifyOtpEmailHint;

  /// No description provided for @verifyOtpPhoneHint.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا رمزاً من 6 أرقام إلى هاتفك'**
  String get verifyOtpPhoneHint;

  /// No description provided for @verifyOtpPhoneViaEmailHint.
  ///
  /// In ar, this message translates to:
  /// **'حالياً نرسل رمز تأكيد الرقم إلى بريدك. التحقق بالرسائل القصيرة لاحقاً.'**
  String get verifyOtpPhoneViaEmailHint;

  /// No description provided for @verifyOtpPhoneTrialEmailHint.
  ///
  /// In ar, this message translates to:
  /// **'حالياً نرسل رمز تأكيد الرقم إلى بريدك. التحقق بالرسائل القصيرة لاحقاً.'**
  String get verifyOtpPhoneTrialEmailHint;

  /// No description provided for @verifyOtpPhoneTrialLogHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التحقق من بريدك'**
  String get verifyOtpPhoneTrialLogHint;

  /// No description provided for @verifyOtpSmsNotConfigured.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل القصيرة غير مُعدّة بعد. حاول لاحقاً أو تواصل مع الدعم'**
  String get verifyOtpSmsNotConfigured;

  /// No description provided for @verifyOtpSmsSendFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إرسال الرسالة القصيرة. حاول بعد قليل'**
  String get verifyOtpSmsSendFailed;

  /// No description provided for @verifyOtpEmailSendFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إرسال رمز البريد. تحقق من العنوان وحاول مجدداً'**
  String get verifyOtpEmailSendFailed;

  /// No description provided for @verifyOtpEmailRequiredForPhone.
  ///
  /// In ar, this message translates to:
  /// **'أضف بريداً إلكترونياً لاستلام رمز التحقق'**
  String get verifyOtpEmailRequiredForPhone;

  /// No description provided for @verifyOtpInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز المكون من 6 أرقام'**
  String get verifyOtpInvalid;

  /// No description provided for @verifyOtpWrongCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز غير صحيح'**
  String get verifyOtpWrongCode;

  /// No description provided for @verifyOtpExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية الرمز — اطلب رمزاً جديداً'**
  String get verifyOtpExpired;

  /// No description provided for @verifyOtpTooManyAttempts.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة — اطلب رمزاً جديداً'**
  String get verifyOtpTooManyAttempts;

  /// No description provided for @verifyOtpSessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت جلسة التحقق — ابدأ من جديد'**
  String get verifyOtpSessionExpired;

  /// No description provided for @verifyOtpConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تحقق'**
  String get verifyOtpConfirm;

  /// No description provided for @verifyOtpResend.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال الرمز'**
  String get verifyOtpResend;

  /// No description provided for @verifyOtpResendIn.
  ///
  /// In ar, this message translates to:
  /// **'أعد الإرسال بعد {seconds} ث'**
  String verifyOtpResendIn(Object seconds);

  /// No description provided for @verifyOtpResent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال الرمز'**
  String get verifyOtpResent;

  /// No description provided for @verifyOtpTrialCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز اختبار: {code}'**
  String verifyOtpTrialCode(Object code);

  /// No description provided for @friendsCopyObicId.
  ///
  /// In ar, this message translates to:
  /// **'نسخ معرّف OBIC'**
  String get friendsCopyObicId;

  /// No description provided for @phoneVerifyTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الهاتف'**
  String get phoneVerifyTitle;

  /// No description provided for @phoneVerifyHeadline.
  ///
  /// In ar, this message translates to:
  /// **'رقم جوال الصين مطلوب'**
  String get phoneVerifyHeadline;

  /// No description provided for @phoneVerifyBody.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون في الصين يجب أن يضيفوا ويؤكدوا رقم جوال صيني (+86) قبل الدردشة والطلبات. الإعدادات واللغة تبقى متاحة.'**
  String get phoneVerifyBody;

  /// No description provided for @phoneVerifyBodyEmailOtp.
  ///
  /// In ar, this message translates to:
  /// **'أدخل جوال الصين (+86). حالياً نؤكد الرقم برمز إلى بريدك؛ الرسائل القصيرة لاحقاً.'**
  String get phoneVerifyBodyEmailOtp;

  /// No description provided for @phoneVerifyEmailForCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'البريد لاستلام رمز التحقق'**
  String get phoneVerifyEmailForCodeHint;

  /// No description provided for @phoneVerifySendCode.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رمز التحقق'**
  String get phoneVerifySendCode;

  /// No description provided for @phoneVerifyOpenSettings.
  ///
  /// In ar, this message translates to:
  /// **'اللغة والمظهر'**
  String get phoneVerifyOpenSettings;

  /// No description provided for @phoneVerifyLater.
  ///
  /// In ar, this message translates to:
  /// **'التفعيل لاحقاً'**
  String get phoneVerifyLater;

  /// No description provided for @phoneVerifyLocked.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك التصفح. فعّل الرقم قبل أي إجراء.'**
  String get phoneVerifyLocked;

  /// No description provided for @phoneVerifyActivate.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الرقم'**
  String get phoneVerifyActivate;

  /// No description provided for @phoneChinaOnly.
  ///
  /// In ar, this message translates to:
  /// **'أرقام الصين القارية فقط (+86 / 1[3-9]…)'**
  String get phoneChinaOnly;

  /// No description provided for @smsPhoneCountries.
  ///
  /// In ar, this message translates to:
  /// **'استخدم رقم جوال من الصين أو السعودية أو اليمن.'**
  String get smsPhoneCountries;

  /// No description provided for @smsCountryChina.
  ///
  /// In ar, this message translates to:
  /// **'الصين +86'**
  String get smsCountryChina;

  /// No description provided for @smsCountrySaudi.
  ///
  /// In ar, this message translates to:
  /// **'السعودية +966'**
  String get smsCountrySaudi;

  /// No description provided for @smsCountryYemen.
  ///
  /// In ar, this message translates to:
  /// **'اليمن +967'**
  String get smsCountryYemen;

  /// No description provided for @phoneVerifyBlocked.
  ///
  /// In ar, this message translates to:
  /// **'أكد رقم جوال الصين للمتابعة'**
  String get phoneVerifyBlocked;

  /// No description provided for @emailVerifyTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد البريد'**
  String get emailVerifyTitle;

  /// No description provided for @emailVerifyHeadline.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد البريد مطلوب'**
  String get emailVerifyHeadline;

  /// No description provided for @emailVerifyBody.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون في الصين يجب تأكيد بريدهم قبل الدردشة والطلبات. نرسل الرمز إلى صندوق الوارد.'**
  String get emailVerifyBody;

  /// No description provided for @emailVerifySendCode.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رمز البريد'**
  String get emailVerifySendCode;

  /// No description provided for @authChinaPhoneRequired.
  ///
  /// In ar, this message translates to:
  /// **'في الصين سجّل بجوال (+86) وبريد لاستلام الرمز'**
  String get authChinaPhoneRequired;

  /// No description provided for @profileUseCurrentLocation.
  ///
  /// In ar, this message translates to:
  /// **'استخدم موقعي الحالي'**
  String get profileUseCurrentLocation;

  /// No description provided for @profileLocationDetecting.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحديد الموقع…'**
  String get profileLocationDetecting;

  /// No description provided for @profileLocationDetail.
  ///
  /// In ar, this message translates to:
  /// **'بالقرب: {detail}'**
  String profileLocationDetail(String detail);

  /// No description provided for @profilePickCountry.
  ///
  /// In ar, this message translates to:
  /// **'اختر الدولة'**
  String get profilePickCountry;

  /// No description provided for @profilePickCity.
  ///
  /// In ar, this message translates to:
  /// **'اختر المدينة'**
  String get profilePickCity;

  /// No description provided for @profileSearchCountry.
  ///
  /// In ar, this message translates to:
  /// **'بحث عن دولة'**
  String get profileSearchCountry;

  /// No description provided for @profileSearchCity.
  ///
  /// In ar, this message translates to:
  /// **'بحث عن مدينة'**
  String get profileSearchCity;

  /// No description provided for @profileLocationFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد الموقع — اختر الدولة والمدينة'**
  String get profileLocationFailed;

  /// No description provided for @miniAppsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تطبيقات أوبك'**
  String get miniAppsTitle;

  /// No description provided for @miniAppsPullCue.
  ///
  /// In ar, this message translates to:
  /// **'اسحب للأسفل لتطبيقات أوبك'**
  String get miniAppsPullCue;

  /// No description provided for @miniAppsPullHint.
  ///
  /// In ar, this message translates to:
  /// **'التطبيقات المصغّرة المعتمدة'**
  String get miniAppsPullHint;

  /// No description provided for @miniAppsTipTitle.
  ///
  /// In ar, this message translates to:
  /// **'تطبيقات أوبك هنا'**
  String get miniAppsTipTitle;

  /// No description provided for @miniAppsTipBody.
  ///
  /// In ar, this message translates to:
  /// **'اسحب للأسفل من أعلى الصفحة الرئيسية، أو اضغط شريط التطبيقات المصغّرة، لفتح التطبيقات المعتمدة.'**
  String get miniAppsTipBody;

  /// No description provided for @miniAppsTipTry.
  ///
  /// In ar, this message translates to:
  /// **'جرّب'**
  String get miniAppsTipTry;

  /// No description provided for @miniAppsTipDismiss.
  ///
  /// In ar, this message translates to:
  /// **'حسناً'**
  String get miniAppsTipDismiss;

  /// No description provided for @miniAppsSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'بحث في التطبيقات المصغّرة'**
  String get miniAppsSearchHint;

  /// No description provided for @miniAppsEmptySearch.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تطبيقات مطابقة'**
  String get miniAppsEmptySearch;

  /// No description provided for @miniAppsClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get miniAppsClose;

  /// No description provided for @miniAppsCloseHint.
  ///
  /// In ar, this message translates to:
  /// **'اسحب للأعلى للإغلاق'**
  String get miniAppsCloseHint;

  /// No description provided for @miniAppsExampleBadge.
  ///
  /// In ar, this message translates to:
  /// **'مثال'**
  String get miniAppsExampleBadge;

  /// No description provided for @miniAppsPartnerBadge.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق مصغّر تجريبي'**
  String get miniAppsPartnerBadge;

  /// No description provided for @miniAppsComingSoonBody.
  ///
  /// In ar, this message translates to:
  /// **'لا يفتح أوبك إلا تطبيقاً مصغّراً معتمداً.'**
  String get miniAppsComingSoonBody;

  /// No description provided for @miniAppsPartnerHint.
  ///
  /// In ar, this message translates to:
  /// **'أرسل الصفحة من الإعدادات ← التطبيقات المصغّرة. بعد موافقة المشرف الأعلى تظهر هنا. المرفوض والمعطّل لا يُفتح.'**
  String get miniAppsPartnerHint;

  /// No description provided for @channelDescription.
  ///
  /// In ar, this message translates to:
  /// **'مقاطع قصيرة من موظفي أوبك والأصدقاء'**
  String get channelDescription;

  /// No description provided for @channelFollow.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get channelFollow;

  /// No description provided for @channelFollowing.
  ///
  /// In ar, this message translates to:
  /// **'تتم المتابعة'**
  String get channelFollowing;

  /// No description provided for @channelStats.
  ///
  /// In ar, this message translates to:
  /// **'{followers} متابع · {videos} فيديو'**
  String channelStats(int followers, int videos);

  /// No description provided for @channelLimitsHint.
  ///
  /// In ar, this message translates to:
  /// **'مقاطع حتى {mb} ميجابايت و{sec} ثانية'**
  String channelLimitsHint(int mb, int sec);

  /// No description provided for @channelEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا فيديوهات بعد — كن أول من يرفع'**
  String get channelEmpty;

  /// No description provided for @channelUpload.
  ///
  /// In ar, this message translates to:
  /// **'رفع'**
  String get channelUpload;

  /// No description provided for @channelUploadTitle.
  ///
  /// In ar, this message translates to:
  /// **'رفع فيديو قصير'**
  String get channelUploadTitle;

  /// No description provided for @channelUploadLimits.
  ///
  /// In ar, this message translates to:
  /// **'بحد أقصى 40 ميجابايت و60 ثانية'**
  String get channelUploadLimits;

  /// No description provided for @channelCaptionHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف وصفاً (اختياري)'**
  String get channelCaptionHint;

  /// No description provided for @channelUploadDone.
  ///
  /// In ar, this message translates to:
  /// **'تم نشر الفيديو'**
  String get channelUploadDone;

  /// No description provided for @channelVideoTooLarge.
  ///
  /// In ar, this message translates to:
  /// **'الفيديو كبير جداً (الحد 40 ميجابايت)'**
  String get channelVideoTooLarge;

  /// No description provided for @channelVideoTooLong.
  ///
  /// In ar, this message translates to:
  /// **'الفيديو طويل جداً (الحد 60 ثانية)'**
  String get channelVideoTooLong;

  /// No description provided for @channelNoCaption.
  ///
  /// In ar, this message translates to:
  /// **'فيديو قصير'**
  String get channelNoCaption;

  /// No description provided for @discoverTitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتشف'**
  String get discoverTitle;

  /// No description provided for @discoverMiniAppsHint.
  ///
  /// In ar, this message translates to:
  /// **'افتح التطبيقات المصغّرة · أو اسحب من الرئيسية'**
  String get discoverMiniAppsHint;

  /// No description provided for @channelTabFollow.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get channelTabFollow;

  /// No description provided for @channelTabNearby.
  ///
  /// In ar, this message translates to:
  /// **'بالقرب'**
  String get channelTabNearby;

  /// No description provided for @channelTabFriends.
  ///
  /// In ar, this message translates to:
  /// **'الأصدقاء'**
  String get channelTabFriends;

  /// No description provided for @channelTabHot.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر رواجاً'**
  String get channelTabHot;

  /// No description provided for @channelMyChannel.
  ///
  /// In ar, this message translates to:
  /// **'قناتي'**
  String get channelMyChannel;

  /// No description provided for @channelOfficialShort.
  ///
  /// In ar, this message translates to:
  /// **'أوبك الرسمية'**
  String get channelOfficialShort;

  /// No description provided for @channelPostDenied.
  ///
  /// In ar, this message translates to:
  /// **'القنوات الشخصية للأصدقاء فقط. الموظفون ينشرون في الرسمية.'**
  String get channelPostDenied;

  /// No description provided for @channelShared.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ — تم تحديث عدد المشاركات'**
  String get channelShared;

  /// No description provided for @channelShareTitle.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get channelShareTitle;

  /// No description provided for @channelShareToMoments.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة في اللحظات'**
  String get channelShareToMoments;

  /// No description provided for @channelShareToChat.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة في الدردشة'**
  String get channelShareToChat;

  /// No description provided for @channelShareCopyLink.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الرابط'**
  String get channelShareCopyLink;

  /// No description provided for @channelShareCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الرابط'**
  String get channelShareCopied;

  /// No description provided for @channelShareMomentsDone.
  ///
  /// In ar, this message translates to:
  /// **'تمت المشاركة في اللحظات'**
  String get channelShareMomentsDone;

  /// No description provided for @channelShareChatDone.
  ///
  /// In ar, this message translates to:
  /// **'أُرسل إلى الدردشة'**
  String get channelShareChatDone;

  /// No description provided for @channelShareNoFriends.
  ///
  /// In ar, this message translates to:
  /// **'أضف أصدقاء للمشاركة في الدردشة'**
  String get channelShareNoFriends;

  /// No description provided for @channelSharePickFriend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال إلى…'**
  String get channelSharePickFriend;

  /// No description provided for @channelCommentsTitle.
  ///
  /// In ar, this message translates to:
  /// **'{count} تعليقات'**
  String channelCommentsTitle(int count);

  /// No description provided for @channelCommentsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا تعليقات بعد'**
  String get channelCommentsEmpty;

  /// No description provided for @channelCommentHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب شيئاً…'**
  String get channelCommentHint;

  /// No description provided for @chatNewChat.
  ///
  /// In ar, this message translates to:
  /// **'محادثة جديدة'**
  String get chatNewChat;

  /// No description provided for @momentsUnpin.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التثبيت'**
  String get momentsUnpin;

  /// No description provided for @momentsPinnedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم التثبيت بالأعلى'**
  String get momentsPinnedToast;

  /// No description provided for @momentsUnpinnedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء التثبيت'**
  String get momentsUnpinnedToast;

  /// No description provided for @momentsHideTheirs.
  ///
  /// In ar, this message translates to:
  /// **'عدم رؤية لحظاته'**
  String get momentsHideTheirs;

  /// No description provided for @momentsShowTheirs.
  ///
  /// In ar, this message translates to:
  /// **'عرض لحظاته'**
  String get momentsShowTheirs;

  /// No description provided for @momentsHideMine.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء لحظاتي عنه'**
  String get momentsHideMine;

  /// No description provided for @momentsShowMine.
  ///
  /// In ar, this message translates to:
  /// **'السماح له برؤية لحظاتي'**
  String get momentsShowMine;

  /// No description provided for @momentsPrefsSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم التحديث'**
  String get momentsPrefsSaved;

  /// No description provided for @settingsSounds.
  ///
  /// In ar, this message translates to:
  /// **'الأصوات'**
  String get settingsSounds;

  /// No description provided for @soundCall.
  ///
  /// In ar, this message translates to:
  /// **'نغمة المكالمة'**
  String get soundCall;

  /// No description provided for @soundMessage.
  ///
  /// In ar, this message translates to:
  /// **'نغمة الرسائل'**
  String get soundMessage;

  /// No description provided for @soundNotification.
  ///
  /// In ar, this message translates to:
  /// **'نغمة الإشعارات'**
  String get soundNotification;

  /// No description provided for @soundClassic.
  ///
  /// In ar, this message translates to:
  /// **'كلاسيكية'**
  String get soundClassic;

  /// No description provided for @soundSoft.
  ///
  /// In ar, this message translates to:
  /// **'هادئة'**
  String get soundSoft;

  /// No description provided for @soundBright.
  ///
  /// In ar, this message translates to:
  /// **'واضحة'**
  String get soundBright;

  /// No description provided for @friendsPickerSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get friendsPickerSearch;

  /// No description provided for @friendsPickerEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get friendsPickerEmpty;

  /// No description provided for @messagesFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get messagesFilterAll;

  /// No description provided for @messagesFilterUnread.
  ///
  /// In ar, this message translates to:
  /// **'غير مقروء'**
  String get messagesFilterUnread;

  /// No description provided for @messagesFilterGroups.
  ///
  /// In ar, this message translates to:
  /// **'المجموعات'**
  String get messagesFilterGroups;

  /// No description provided for @messagesFilterServices.
  ///
  /// In ar, this message translates to:
  /// **'الخدمات'**
  String get messagesFilterServices;

  /// No description provided for @messagesFilterEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا محادثات في هذا العرض'**
  String get messagesFilterEmpty;

  /// No description provided for @chatMarkRead.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كمقروء'**
  String get chatMarkRead;

  /// No description provided for @messagesMarkAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تعليم الكل كمقروء'**
  String get messagesMarkAllRead;

  /// No description provided for @messagesMarkAllReadDone.
  ///
  /// In ar, this message translates to:
  /// **'تم تعليم كل المحادثات كمقروءة'**
  String get messagesMarkAllReadDone;

  /// No description provided for @chatTimeYesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get chatTimeYesterday;

  /// No description provided for @chatWeekdayMon.
  ///
  /// In ar, this message translates to:
  /// **'الإثنين'**
  String get chatWeekdayMon;

  /// No description provided for @chatWeekdayTue.
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء'**
  String get chatWeekdayTue;

  /// No description provided for @chatWeekdayWed.
  ///
  /// In ar, this message translates to:
  /// **'الأربعاء'**
  String get chatWeekdayWed;

  /// No description provided for @chatWeekdayThu.
  ///
  /// In ar, this message translates to:
  /// **'الخميس'**
  String get chatWeekdayThu;

  /// No description provided for @chatWeekdayFri.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get chatWeekdayFri;

  /// No description provided for @chatWeekdaySat.
  ///
  /// In ar, this message translates to:
  /// **'السبت'**
  String get chatWeekdaySat;

  /// No description provided for @chatWeekdaySun.
  ///
  /// In ar, this message translates to:
  /// **'الأحد'**
  String get chatWeekdaySun;

  /// No description provided for @messagesSwipeRead.
  ///
  /// In ar, this message translates to:
  /// **'مقروء'**
  String get messagesSwipeRead;

  /// No description provided for @messagesSwipeUnread.
  ///
  /// In ar, this message translates to:
  /// **'غير مقروء'**
  String get messagesSwipeUnread;

  /// No description provided for @messagesSwipePin.
  ///
  /// In ar, this message translates to:
  /// **'تثبيت'**
  String get messagesSwipePin;

  /// No description provided for @messagesSwipeUnpin.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التثبيت'**
  String get messagesSwipeUnpin;

  /// No description provided for @messagesSwipeMute.
  ///
  /// In ar, this message translates to:
  /// **'كتم'**
  String get messagesSwipeMute;

  /// No description provided for @messagesSwipeUnmute.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الكتم'**
  String get messagesSwipeUnmute;

  /// No description provided for @messagesSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get messagesSearchHint;

  /// No description provided for @messagesSearchChats.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات'**
  String get messagesSearchChats;

  /// No description provided for @messagesSearchHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل المحادثات'**
  String get messagesSearchHistory;

  /// No description provided for @messagesSearchRelated.
  ///
  /// In ar, this message translates to:
  /// **'{n} رسائل ذات صلة'**
  String messagesSearchRelated(int n);

  /// No description provided for @messagesSearchEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get messagesSearchEmpty;

  /// No description provided for @chatSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'بحث في الدردشة'**
  String get chatSearchHint;

  /// No description provided for @chatSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get chatSearch;

  /// No description provided for @chatSearchEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد رسائل مطابقة'**
  String get chatSearchEmpty;

  /// No description provided for @chatSearchPosition.
  ///
  /// In ar, this message translates to:
  /// **'{current}/{total}'**
  String chatSearchPosition(int current, int total);

  /// No description provided for @chatSearchOlder.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get chatSearchOlder;

  /// No description provided for @chatSearchNewer.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get chatSearchNewer;

  /// No description provided for @chatSearchPhotos.
  ///
  /// In ar, this message translates to:
  /// **'الصور'**
  String get chatSearchPhotos;

  /// No description provided for @chatSearchVideos.
  ///
  /// In ar, this message translates to:
  /// **'الفيديو'**
  String get chatSearchVideos;

  /// No description provided for @chatSearchFiles.
  ///
  /// In ar, this message translates to:
  /// **'الملفات'**
  String get chatSearchFiles;

  /// No description provided for @chatSearchLinks.
  ///
  /// In ar, this message translates to:
  /// **'الروابط'**
  String get chatSearchLinks;

  /// No description provided for @chatSearchAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get chatSearchAll;

  /// No description provided for @chatFindInChat.
  ///
  /// In ar, this message translates to:
  /// **'بحث في الدردشة'**
  String get chatFindInChat;

  /// No description provided for @chatUnreadNotInView.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة غير المقروءة ليست ضمن السجل المحمّل'**
  String get chatUnreadNotInView;

  /// No description provided for @chatCopy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get chatCopy;

  /// No description provided for @chatQuote.
  ///
  /// In ar, this message translates to:
  /// **'اقتباس'**
  String get chatQuote;

  /// No description provided for @chatDeleteForMe.
  ///
  /// In ar, this message translates to:
  /// **'حذف لدي'**
  String get chatDeleteForMe;

  /// No description provided for @chatDeleteForMeConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف هذه الرسالة من هذا الجهاز فقط؟'**
  String get chatDeleteForMeConfirm;

  /// No description provided for @chatCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get chatCopied;

  /// No description provided for @chatNothingToCopy.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد نص للنسخ'**
  String get chatNothingToCopy;

  /// No description provided for @chatDeletedForMe.
  ///
  /// In ar, this message translates to:
  /// **'حُذفت لديك'**
  String get chatDeletedForMe;

  /// No description provided for @chatMessageActions.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات الرسالة'**
  String get chatMessageActions;

  /// No description provided for @friendsContactsTitle.
  ///
  /// In ar, this message translates to:
  /// **'جهات الاتصال'**
  String get friendsContactsTitle;

  /// No description provided for @friendsGroupChats.
  ///
  /// In ar, this message translates to:
  /// **'دردشات جماعية'**
  String get friendsGroupChats;

  /// No description provided for @friendsNewGroup.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة جديدة'**
  String get friendsNewGroup;

  /// No description provided for @friendsStarred.
  ///
  /// In ar, this message translates to:
  /// **'المميّزون'**
  String get friendsStarred;

  /// No description provided for @directoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'دليل الشركة'**
  String get directoryTitle;

  /// No description provided for @directoryHint.
  ///
  /// In ar, this message translates to:
  /// **'الزملاء المسموح لك برؤيتهم. أرقام الهاتف تبقى عند المشرف الأعلى.'**
  String get directoryHint;

  /// No description provided for @directoryEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد زملاء في نطاقك بعد.'**
  String get directoryEmpty;

  /// No description provided for @directorySearch.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن زميل'**
  String get directorySearch;

  /// No description provided for @directoryUnassigned.
  ///
  /// In ar, this message translates to:
  /// **'بدون قسم'**
  String get directoryUnassigned;

  /// No description provided for @directoryMessage.
  ///
  /// In ar, this message translates to:
  /// **'مراسلة'**
  String get directoryMessage;

  /// No description provided for @directoryLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الدليل'**
  String get directoryLoadFailed;

  /// No description provided for @approvalsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الموافقات'**
  String get approvalsTitle;

  /// No description provided for @approvalsHint.
  ///
  /// In ar, this message translates to:
  /// **'أرسل طلباً. يجيب الموافقون بالترتيب.'**
  String get approvalsHint;

  /// No description provided for @approvalsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا طلبات بعد.'**
  String get approvalsEmpty;

  /// No description provided for @approvalsNew.
  ///
  /// In ar, this message translates to:
  /// **'طلب جديد'**
  String get approvalsNew;

  /// No description provided for @approvalsTemplate.
  ///
  /// In ar, this message translates to:
  /// **'القالب'**
  String get approvalsTemplate;

  /// No description provided for @approvalsTitleField.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get approvalsTitleField;

  /// No description provided for @approvalsDetails.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل'**
  String get approvalsDetails;

  /// No description provided for @approvalsSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get approvalsSend;

  /// No description provided for @approvalsApprove.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get approvalsApprove;

  /// No description provided for @approvalsReject.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get approvalsReject;

  /// No description provided for @approvalsCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب'**
  String get approvalsCancel;

  /// No description provided for @approvalsWaiting.
  ///
  /// In ar, this message translates to:
  /// **'بانتظارك'**
  String get approvalsWaiting;

  /// No description provided for @approvalsMine.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get approvalsMine;

  /// No description provided for @approvalsLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الموافقات'**
  String get approvalsLoadFailed;

  /// No description provided for @approvalPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get approvalPending;

  /// No description provided for @approvalApproved.
  ///
  /// In ar, this message translates to:
  /// **'مقبول'**
  String get approvalApproved;

  /// No description provided for @approvalRejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get approvalRejected;

  /// No description provided for @approvalCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغى'**
  String get approvalCancelled;

  /// No description provided for @attendanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحضور'**
  String get attendanceTitle;

  /// No description provided for @attendanceHint.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول عند بدء العمل، والخروج عند الانتهاء. الساعات تتبع توقيت الشركة.'**
  String get attendanceHint;

  /// No description provided for @attendanceClockIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get attendanceClockIn;

  /// No description provided for @attendanceClockOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get attendanceClockOut;

  /// No description provided for @attendanceMissing.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسجَّل'**
  String get attendanceMissing;

  /// No description provided for @attendanceOnTime.
  ///
  /// In ar, this message translates to:
  /// **'في الوقت'**
  String get attendanceOnTime;

  /// No description provided for @attendanceLate.
  ///
  /// In ar, this message translates to:
  /// **'متأخر'**
  String get attendanceLate;

  /// No description provided for @attendanceEarly.
  ///
  /// In ar, this message translates to:
  /// **'خروج مبكر'**
  String get attendanceEarly;

  /// No description provided for @attendanceOffDay.
  ///
  /// In ar, this message translates to:
  /// **'خارج الجدول'**
  String get attendanceOffDay;

  /// No description provided for @attendanceRecent.
  ///
  /// In ar, this message translates to:
  /// **'الأيام الأخيرة'**
  String get attendanceRecent;

  /// No description provided for @attendanceNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختياري)'**
  String get attendanceNote;

  /// No description provided for @attendanceLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الحضور'**
  String get attendanceLoadFailed;

  /// No description provided for @reportsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reportsTitle;

  /// No description provided for @reportsHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ما أنجزته والخطوة التالية. يمكنك تعديل اليوم أو الأسبوع أو الشهر الحالي.'**
  String get reportsHint;

  /// No description provided for @reportsDaily.
  ///
  /// In ar, this message translates to:
  /// **'يومي'**
  String get reportsDaily;

  /// No description provided for @reportsWeekly.
  ///
  /// In ar, this message translates to:
  /// **'أسبوعي'**
  String get reportsWeekly;

  /// No description provided for @reportsMonthly.
  ///
  /// In ar, this message translates to:
  /// **'شهري'**
  String get reportsMonthly;

  /// No description provided for @reportsDone.
  ///
  /// In ar, this message translates to:
  /// **'ما تم'**
  String get reportsDone;

  /// No description provided for @reportsPlan.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة التالية'**
  String get reportsPlan;

  /// No description provided for @reportsBlockers.
  ///
  /// In ar, this message translates to:
  /// **'عوائق'**
  String get reportsBlockers;

  /// No description provided for @reportsSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get reportsSend;

  /// No description provided for @reportsMissing.
  ///
  /// In ar, this message translates to:
  /// **'لم يُرسل'**
  String get reportsMissing;

  /// No description provided for @reportsSent.
  ///
  /// In ar, this message translates to:
  /// **'أُرسل'**
  String get reportsSent;

  /// No description provided for @reportsInbox.
  ///
  /// In ar, this message translates to:
  /// **'التقارير الواردة'**
  String get reportsInbox;

  /// No description provided for @reportsMine.
  ///
  /// In ar, this message translates to:
  /// **'تقاريري'**
  String get reportsMine;

  /// No description provided for @reportsNone.
  ///
  /// In ar, this message translates to:
  /// **'لا شيء بعد.'**
  String get reportsNone;

  /// No description provided for @reportsLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل التقارير'**
  String get reportsLoadFailed;

  /// No description provided for @formsTitle.
  ///
  /// In ar, this message translates to:
  /// **'النماذج'**
  String get formsTitle;

  /// No description provided for @formsHint.
  ///
  /// In ar, this message translates to:
  /// **'املأ نموذج الشركة. المكتب يقرأ ما ترسله.'**
  String get formsHint;

  /// No description provided for @formsSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get formsSend;

  /// No description provided for @formsFillRequired.
  ///
  /// In ar, this message translates to:
  /// **'املأ كل الحقول المطلوبة'**
  String get formsFillRequired;

  /// No description provided for @formsNone.
  ///
  /// In ar, this message translates to:
  /// **'لا نماذج بعد.'**
  String get formsNone;

  /// No description provided for @formsMine.
  ///
  /// In ar, this message translates to:
  /// **'نماذجي'**
  String get formsMine;

  /// No description provided for @formsLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل النماذج'**
  String get formsLoadFailed;

  /// No description provided for @collectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'نماذج الجمع'**
  String get collectionTitle;

  /// No description provided for @collectionHint.
  ///
  /// In ar, this message translates to:
  /// **'املأ النموذج الذي أُرسل إليك. يمكنك تعديله ما دام مفتوحاً.'**
  String get collectionHint;

  /// No description provided for @collectionSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get collectionSend;

  /// No description provided for @collectionFillRequired.
  ///
  /// In ar, this message translates to:
  /// **'املأ كل الحقول المطلوبة'**
  String get collectionFillRequired;

  /// No description provided for @collectionNone.
  ///
  /// In ar, this message translates to:
  /// **'لم يُرسل إليك جمع بعد.'**
  String get collectionNone;

  /// No description provided for @collectionOpen.
  ///
  /// In ar, this message translates to:
  /// **'مفتوح'**
  String get collectionOpen;

  /// No description provided for @collectionClosed.
  ///
  /// In ar, this message translates to:
  /// **'مغلق'**
  String get collectionClosed;

  /// No description provided for @collectionLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل نماذج الجمع'**
  String get collectionLoadFailed;

  /// No description provided for @roomsTitle.
  ///
  /// In ar, this message translates to:
  /// **'غرف الاجتماعات'**
  String get roomsTitle;

  /// No description provided for @roomsHint.
  ///
  /// In ar, this message translates to:
  /// **'احجز غرفة. لا يُحجز الوقت نفسه مرتين.'**
  String get roomsHint;

  /// No description provided for @roomsBook.
  ///
  /// In ar, this message translates to:
  /// **'حجز'**
  String get roomsBook;

  /// No description provided for @roomsPurpose.
  ///
  /// In ar, this message translates to:
  /// **'الغرض'**
  String get roomsPurpose;

  /// No description provided for @roomsStart.
  ///
  /// In ar, this message translates to:
  /// **'البداية'**
  String get roomsStart;

  /// No description provided for @roomsEnd.
  ///
  /// In ar, this message translates to:
  /// **'النهاية'**
  String get roomsEnd;

  /// No description provided for @roomsPick.
  ///
  /// In ar, this message translates to:
  /// **'اختيار'**
  String get roomsPick;

  /// No description provided for @roomsUpcoming.
  ///
  /// In ar, this message translates to:
  /// **'القادمة'**
  String get roomsUpcoming;

  /// No description provided for @roomsNone.
  ///
  /// In ar, this message translates to:
  /// **'لا حجوزات في هذا النطاق.'**
  String get roomsNone;

  /// No description provided for @roomsCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get roomsCancel;

  /// No description provided for @roomsLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل غرف الاجتماعات'**
  String get roomsLoadFailed;

  /// No description provided for @rosterTitle.
  ///
  /// In ar, this message translates to:
  /// **'الانضمام والمغادرة'**
  String get rosterTitle;

  /// No description provided for @rosterHint.
  ///
  /// In ar, this message translates to:
  /// **'اطلب المغادرة في آخر يوم. التأكيد لا يغلق تسجيل الدخول.'**
  String get rosterHint;

  /// No description provided for @rosterAsk.
  ///
  /// In ar, this message translates to:
  /// **'طلب المغادرة'**
  String get rosterAsk;

  /// No description provided for @rosterJoined.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الانضمام'**
  String get rosterJoined;

  /// No description provided for @rosterLastDay.
  ///
  /// In ar, this message translates to:
  /// **'آخر يوم'**
  String get rosterLastDay;

  /// No description provided for @rosterNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get rosterNote;

  /// No description provided for @rosterActive.
  ///
  /// In ar, this message translates to:
  /// **'على رأس العمل'**
  String get rosterActive;

  /// No description provided for @rosterLeaving.
  ///
  /// In ar, this message translates to:
  /// **'طلب مغادرة'**
  String get rosterLeaving;

  /// No description provided for @rosterLeft.
  ///
  /// In ar, this message translates to:
  /// **'غادر'**
  String get rosterLeft;

  /// No description provided for @rosterUnrecorded.
  ///
  /// In ar, this message translates to:
  /// **'غير مسجّل'**
  String get rosterUnrecorded;

  /// No description provided for @rosterMissing.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ انضمامك غير مسجّل بعد.'**
  String get rosterMissing;

  /// No description provided for @rosterPending.
  ///
  /// In ar, this message translates to:
  /// **'طلب المغادرة بانتظار المكتب.'**
  String get rosterPending;

  /// No description provided for @rosterRecorded.
  ///
  /// In ar, this message translates to:
  /// **'سُجّلت مغادرتك. يبقى تسجيل الدخول مفتوحاً حتى يغلقه مكتب الموظفين.'**
  String get rosterRecorded;

  /// No description provided for @rosterLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل السجل'**
  String get rosterLoadFailed;

  /// No description provided for @payslipsTitle.
  ///
  /// In ar, this message translates to:
  /// **'قسائم الراتب'**
  String get payslipsTitle;

  /// No description provided for @payslipsHint.
  ///
  /// In ar, this message translates to:
  /// **'افتح قسيمة الراتب وأكد أنك اطّلعت عليها. هذا سجل ولا يرسل مالاً.'**
  String get payslipsHint;

  /// No description provided for @payslipsSeen.
  ///
  /// In ar, this message translates to:
  /// **'اطّلعت عليها'**
  String get payslipsSeen;

  /// No description provided for @payslipsConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'تم الاطلاع'**
  String get payslipsConfirmed;

  /// No description provided for @payslipsOpen.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الاطلاع'**
  String get payslipsOpen;

  /// No description provided for @payslipsEarning.
  ///
  /// In ar, this message translates to:
  /// **'راتب'**
  String get payslipsEarning;

  /// No description provided for @payslipsDeduction.
  ///
  /// In ar, this message translates to:
  /// **'خصم'**
  String get payslipsDeduction;

  /// No description provided for @payslipsNet.
  ///
  /// In ar, this message translates to:
  /// **'الصافي'**
  String get payslipsNet;

  /// No description provided for @payslipsNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get payslipsNote;

  /// No description provided for @payslipsNone.
  ///
  /// In ar, this message translates to:
  /// **'لا قسائم بعد.'**
  String get payslipsNone;

  /// No description provided for @payslipsLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل قسائم الراتب'**
  String get payslipsLoadFailed;

  /// No description provided for @companyContactsTitle.
  ///
  /// In ar, this message translates to:
  /// **'جهات اتصال العملاء'**
  String get companyContactsTitle;

  /// No description provided for @companyContactsHint.
  ///
  /// In ar, this message translates to:
  /// **'هذه الجهات ملك الشركة. ترى الأشخاص المسندين إليك.'**
  String get companyContactsHint;

  /// No description provided for @companyContactsName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get companyContactsName;

  /// No description provided for @companyContactsPhone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get companyContactsPhone;

  /// No description provided for @companyContactsOrg.
  ///
  /// In ar, this message translates to:
  /// **'الجهة'**
  String get companyContactsOrg;

  /// No description provided for @companyContactsNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get companyContactsNote;

  /// No description provided for @companyContactsSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get companyContactsSave;

  /// No description provided for @companyContactsNew.
  ///
  /// In ar, this message translates to:
  /// **'جهة جديدة'**
  String get companyContactsNew;

  /// No description provided for @companyContactsActive.
  ///
  /// In ar, this message translates to:
  /// **'نشطة'**
  String get companyContactsActive;

  /// No description provided for @companyContactsPaused.
  ///
  /// In ar, this message translates to:
  /// **'متوقفة'**
  String get companyContactsPaused;

  /// No description provided for @companyContactsSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get companyContactsSearch;

  /// No description provided for @companyContactsNone.
  ///
  /// In ar, this message translates to:
  /// **'لا جهات اتصال بعد.'**
  String get companyContactsNone;

  /// No description provided for @companyContactsLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل جهات اتصال العملاء'**
  String get companyContactsLoadFailed;

  /// No description provided for @companyTagsTitle.
  ///
  /// In ar, this message translates to:
  /// **'وسوم العملاء'**
  String get companyTagsTitle;

  /// No description provided for @companyTagsHint.
  ///
  /// In ar, this message translates to:
  /// **'وسوم تضعها الشركة. الأسماء المعروضة هي جهات الاتصال المسندة إليك.'**
  String get companyTagsHint;

  /// No description provided for @companyTagsActive.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم'**
  String get companyTagsActive;

  /// No description provided for @companyTagsPaused.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get companyTagsPaused;

  /// No description provided for @companyTagsNone.
  ///
  /// In ar, this message translates to:
  /// **'لا وسوم بعد.'**
  String get companyTagsNone;

  /// No description provided for @companyTagsLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل وسوم العملاء'**
  String get companyTagsLoadFailed;

  /// No description provided for @companyGroupsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مجموعات العملاء'**
  String get companyGroupsTitle;

  /// No description provided for @companyGroupsHint.
  ///
  /// In ar, this message translates to:
  /// **'قائمة من جهات اتصال الشركة المسندة إليك. هذه ليست محادثة.'**
  String get companyGroupsHint;

  /// No description provided for @companyGroupsName.
  ///
  /// In ar, this message translates to:
  /// **'المجموعة'**
  String get companyGroupsName;

  /// No description provided for @companyGroupsNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get companyGroupsNote;

  /// No description provided for @companyGroupsSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get companyGroupsSave;

  /// No description provided for @companyGroupsNew.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة جديدة'**
  String get companyGroupsNew;

  /// No description provided for @companyGroupsActive.
  ///
  /// In ar, this message translates to:
  /// **'مستخدمة'**
  String get companyGroupsActive;

  /// No description provided for @companyGroupsPaused.
  ///
  /// In ar, this message translates to:
  /// **'متوقفة'**
  String get companyGroupsPaused;

  /// No description provided for @companyGroupsNone.
  ///
  /// In ar, this message translates to:
  /// **'لا مجموعات بعد.'**
  String get companyGroupsNone;

  /// No description provided for @companyGroupsLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل مجموعات العملاء'**
  String get companyGroupsLoadFailed;

  /// No description provided for @companyWelcomesTitle.
  ///
  /// In ar, this message translates to:
  /// **'رسائل الترحيب'**
  String get companyWelcomesTitle;

  /// No description provided for @companyWelcomesHint.
  ///
  /// In ar, this message translates to:
  /// **'التحية التي تستخدمها مع عميل جديد. التطبيق يعرضها ولا يرسلها.'**
  String get companyWelcomesHint;

  /// No description provided for @companyWelcomesCopy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get companyWelcomesCopy;

  /// No description provided for @companyWelcomesCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ التحية'**
  String get companyWelcomesCopied;

  /// No description provided for @companyWelcomesAssigned.
  ///
  /// In ar, this message translates to:
  /// **'مسندة إليك'**
  String get companyWelcomesAssigned;

  /// No description provided for @companyWelcomesDefault.
  ///
  /// In ar, this message translates to:
  /// **'تحية الشركة'**
  String get companyWelcomesDefault;

  /// No description provided for @companyWelcomesNone.
  ///
  /// In ar, this message translates to:
  /// **'لا تحية بعد.'**
  String get companyWelcomesNone;

  /// No description provided for @companyWelcomesLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل التحية'**
  String get companyWelcomesLoadFailed;

  /// No description provided for @quickRepliesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الردود السريعة'**
  String get quickRepliesTitle;

  /// No description provided for @quickRepliesHint.
  ///
  /// In ar, this message translates to:
  /// **'انسخ رد الشركة، أو احفظ ردك. التطبيق لا يرسل الرد.'**
  String get quickRepliesHint;

  /// No description provided for @quickRepliesName.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get quickRepliesName;

  /// No description provided for @quickRepliesBody.
  ///
  /// In ar, this message translates to:
  /// **'الرد'**
  String get quickRepliesBody;

  /// No description provided for @quickRepliesSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get quickRepliesSave;

  /// No description provided for @quickRepliesNew.
  ///
  /// In ar, this message translates to:
  /// **'رد جديد'**
  String get quickRepliesNew;

  /// No description provided for @quickRepliesCopy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get quickRepliesCopy;

  /// No description provided for @quickRepliesCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الرد'**
  String get quickRepliesCopied;

  /// No description provided for @quickRepliesCompany.
  ///
  /// In ar, this message translates to:
  /// **'الشركة'**
  String get quickRepliesCompany;

  /// No description provided for @quickRepliesMine.
  ///
  /// In ar, this message translates to:
  /// **'ردودي'**
  String get quickRepliesMine;

  /// No description provided for @quickRepliesActive.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم'**
  String get quickRepliesActive;

  /// No description provided for @quickRepliesPaused.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get quickRepliesPaused;

  /// No description provided for @quickRepliesNone.
  ///
  /// In ar, this message translates to:
  /// **'لا ردود بعد.'**
  String get quickRepliesNone;

  /// No description provided for @quickRepliesLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الردود السريعة'**
  String get quickRepliesLoadFailed;

  /// No description provided for @companyHandoverTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسليم العملاء'**
  String get companyHandoverTitle;

  /// No description provided for @companyHandoverHint.
  ///
  /// In ar, this message translates to:
  /// **'هنا تظهر عمليات التسليم التي أعطتك جهات اتصال الشركة أو أخذتها منك. التطبيق لا يراسل العميل.'**
  String get companyHandoverHint;

  /// No description provided for @companyHandoverFrom.
  ///
  /// In ar, this message translates to:
  /// **'من {name}'**
  String companyHandoverFrom(String name);

  /// No description provided for @companyHandoverTo.
  ///
  /// In ar, this message translates to:
  /// **'إلى {name}'**
  String companyHandoverTo(String name);

  /// No description provided for @companyHandoverCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} جهات'**
  String companyHandoverCount(int count);

  /// No description provided for @companyHandoverNone.
  ///
  /// In ar, this message translates to:
  /// **'لا تسليم بعد.'**
  String get companyHandoverNone;

  /// No description provided for @companyHandoverLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل التسليم'**
  String get companyHandoverLoadFailed;

  /// No description provided for @companyDriveTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملفات الشركة'**
  String get companyDriveTitle;

  /// No description provided for @companyDriveHint.
  ///
  /// In ar, this message translates to:
  /// **'مجلدات الشركة. أضف صورة من هذا الهاتف. الملفات الأخرى تُضاف من مكتب الموظفين. الملف هنا ليس رابطاً عاماً.'**
  String get companyDriveHint;

  /// No description provided for @companyDriveNone.
  ///
  /// In ar, this message translates to:
  /// **'لا مجلدات بعد.'**
  String get companyDriveNone;

  /// No description provided for @companyDriveEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا ملفات في هذا المجلد.'**
  String get companyDriveEmpty;

  /// No description provided for @companyDriveOpenOnDesk.
  ///
  /// In ar, this message translates to:
  /// **'افتح هذا الملف من مكتب الموظفين.'**
  String get companyDriveOpenOnDesk;

  /// No description provided for @companyDriveLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الملفات'**
  String get companyDriveLoadFailed;

  /// No description provided for @companyDocumentsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مستندات مشتركة'**
  String get companyDocumentsTitle;

  /// No description provided for @companyDocumentsHint.
  ///
  /// In ar, this message translates to:
  /// **'افتح مستند الشركة وحدّث النص. آخر حفظ هو النسخة المعتمدة. هذا ليس ملفاً في الملفات.'**
  String get companyDocumentsHint;

  /// No description provided for @companyDocumentsBody.
  ///
  /// In ar, this message translates to:
  /// **'النص'**
  String get companyDocumentsBody;

  /// No description provided for @companyDocumentsSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get companyDocumentsSave;

  /// No description provided for @companyDocumentsSavedBy.
  ///
  /// In ar, this message translates to:
  /// **'آخر حفظ بواسطة {name}'**
  String companyDocumentsSavedBy(String name);

  /// No description provided for @companyDocumentsNone.
  ///
  /// In ar, this message translates to:
  /// **'لا مستندات بعد.'**
  String get companyDocumentsNone;

  /// No description provided for @companyDocumentsLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المستندات'**
  String get companyDocumentsLoadFailed;

  /// No description provided for @companySpreadsheetsTitle.
  ///
  /// In ar, this message translates to:
  /// **'جداول مشتركة'**
  String get companySpreadsheetsTitle;

  /// No description provided for @companySpreadsheetsHint.
  ///
  /// In ar, this message translates to:
  /// **'افتح الجدول وعدّل الخلايا. آخر حفظ هو النسخة المعتمدة. الخلية نص وليست معادلة.'**
  String get companySpreadsheetsHint;

  /// No description provided for @companySpreadsheetsSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get companySpreadsheetsSave;

  /// No description provided for @companySpreadsheetsSavedBy.
  ///
  /// In ar, this message translates to:
  /// **'آخر حفظ بواسطة {name}'**
  String companySpreadsheetsSavedBy(String name);

  /// No description provided for @companySpreadsheetsNone.
  ///
  /// In ar, this message translates to:
  /// **'لا جداول بعد.'**
  String get companySpreadsheetsNone;

  /// No description provided for @companySpreadsheetsLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الجداول'**
  String get companySpreadsheetsLoadFailed;

  /// No description provided for @companyCalendarTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقويم الشركة'**
  String get companyCalendarTitle;

  /// No description provided for @companyCalendarHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف حدثاً. الوقت بتوقيت الصين. التطبيق لا يرسل دعوة. هذا ليس حجز قاعة.'**
  String get companyCalendarHint;

  /// No description provided for @companyCalendarName.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get companyCalendarName;

  /// No description provided for @companyCalendarDate.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get companyCalendarDate;

  /// No description provided for @companyCalendarStart.
  ///
  /// In ar, this message translates to:
  /// **'البداية'**
  String get companyCalendarStart;

  /// No description provided for @companyCalendarEnd.
  ///
  /// In ar, this message translates to:
  /// **'النهاية'**
  String get companyCalendarEnd;

  /// No description provided for @companyCalendarNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get companyCalendarNote;

  /// No description provided for @companyCalendarSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get companyCalendarSave;

  /// No description provided for @companyCalendarNew.
  ///
  /// In ar, this message translates to:
  /// **'حدث جديد'**
  String get companyCalendarNew;

  /// No description provided for @companyCalendarActive.
  ///
  /// In ar, this message translates to:
  /// **'معروض'**
  String get companyCalendarActive;

  /// No description provided for @companyCalendarPaused.
  ///
  /// In ar, this message translates to:
  /// **'مخفي'**
  String get companyCalendarPaused;

  /// No description provided for @companyCalendarNone.
  ///
  /// In ar, this message translates to:
  /// **'لا أحداث في هذه الفترة.'**
  String get companyCalendarNone;

  /// No description provided for @companyCalendarLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل التقويم'**
  String get companyCalendarLoadFailed;

  /// No description provided for @companyMailTitle.
  ///
  /// In ar, this message translates to:
  /// **'بريد الشركة'**
  String get companyMailTitle;

  /// No description provided for @companyMailHint.
  ///
  /// In ar, this message translates to:
  /// **'أرسل رسالة إلى الموظفين. تبقى داخل OBIC ولا تُرسل إلى بريد خارجي.'**
  String get companyMailHint;

  /// No description provided for @companyMailSubject.
  ///
  /// In ar, this message translates to:
  /// **'الموضوع'**
  String get companyMailSubject;

  /// No description provided for @companyMailBody.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة'**
  String get companyMailBody;

  /// No description provided for @companyMailSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get companyMailSend;

  /// No description provided for @companyMailTo.
  ///
  /// In ar, this message translates to:
  /// **'إلى'**
  String get companyMailTo;

  /// No description provided for @companyMailInbox.
  ///
  /// In ar, this message translates to:
  /// **'الوارد'**
  String get companyMailInbox;

  /// No description provided for @companyMailOutbox.
  ///
  /// In ar, this message translates to:
  /// **'المرسل'**
  String get companyMailOutbox;

  /// No description provided for @companyMailNone.
  ///
  /// In ar, this message translates to:
  /// **'لا رسائل.'**
  String get companyMailNone;

  /// No description provided for @companyMailLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل البريد'**
  String get companyMailLoadFailed;

  /// No description provided for @companyMeetingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'اجتماعات الشركة'**
  String get companyMeetingsTitle;

  /// No description provided for @companyMeetingsHint.
  ///
  /// In ar, this message translates to:
  /// **'اجتماع بوقت وجدول أعمال والموظفون المطلوب حضورهم وملاحظات بعده. الوقت بتوقيت الصين. التطبيق لا يبدأ مكالمة.'**
  String get companyMeetingsHint;

  /// No description provided for @companyMeetingsName.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get companyMeetingsName;

  /// No description provided for @companyMeetingsDate.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get companyMeetingsDate;

  /// No description provided for @companyMeetingsStart.
  ///
  /// In ar, this message translates to:
  /// **'البداية'**
  String get companyMeetingsStart;

  /// No description provided for @companyMeetingsEnd.
  ///
  /// In ar, this message translates to:
  /// **'النهاية'**
  String get companyMeetingsEnd;

  /// No description provided for @companyMeetingsAgenda.
  ///
  /// In ar, this message translates to:
  /// **'جدول الأعمال'**
  String get companyMeetingsAgenda;

  /// No description provided for @companyMeetingsNotes.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات'**
  String get companyMeetingsNotes;

  /// No description provided for @companyMeetingsTo.
  ///
  /// In ar, this message translates to:
  /// **'الحضور'**
  String get companyMeetingsTo;

  /// No description provided for @companyMeetingsSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get companyMeetingsSave;

  /// No description provided for @companyMeetingsNew.
  ///
  /// In ar, this message translates to:
  /// **'اجتماع جديد'**
  String get companyMeetingsNew;

  /// No description provided for @companyMeetingsActive.
  ///
  /// In ar, this message translates to:
  /// **'ظاهر'**
  String get companyMeetingsActive;

  /// No description provided for @companyMeetingsPaused.
  ///
  /// In ar, this message translates to:
  /// **'مخفي'**
  String get companyMeetingsPaused;

  /// No description provided for @companyMeetingsNone.
  ///
  /// In ar, this message translates to:
  /// **'لا اجتماعات.'**
  String get companyMeetingsNone;

  /// No description provided for @companyMeetingsLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الاجتماعات'**
  String get companyMeetingsLoadFailed;

  /// No description provided for @companyFileAnswersTitle.
  ///
  /// In ar, this message translates to:
  /// **'أسئلة المستندات'**
  String get companyFileAnswersTitle;

  /// No description provided for @companyFileAnswersHint.
  ///
  /// In ar, this message translates to:
  /// **'اسأل عن مستندات الشركة المشتركة. الجواب من هذه المستندات فقط. عند تشغيل ذكاء الشركة، يكتب الرد من المقاطع المطابقة.'**
  String get companyFileAnswersHint;

  /// No description provided for @companyFileAnswersQuestion.
  ///
  /// In ar, this message translates to:
  /// **'السؤال'**
  String get companyFileAnswersQuestion;

  /// No description provided for @companyFileAnswersAsk.
  ///
  /// In ar, this message translates to:
  /// **'اسأل'**
  String get companyFileAnswersAsk;

  /// No description provided for @companyFileAnswersFromDocuments.
  ///
  /// In ar, this message translates to:
  /// **'من المستندات'**
  String get companyFileAnswersFromDocuments;

  /// No description provided for @companyFileAnswersFromAi.
  ///
  /// In ar, this message translates to:
  /// **'من ذكاء الشركة'**
  String get companyFileAnswersFromAi;

  /// No description provided for @companyFileAnswersNone.
  ///
  /// In ar, this message translates to:
  /// **'لا أسئلة.'**
  String get companyFileAnswersNone;

  /// No description provided for @companyFileAnswersLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الإجابات'**
  String get companyFileAnswersLoadFailed;

  /// No description provided for @companyAppsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تطبيقات الشركة'**
  String get companyAppsTitle;

  /// No description provided for @companyAppsHint.
  ///
  /// In ar, this message translates to:
  /// **'افتح أداة ويب للشركة. تبقى الصفحة في موقعها.'**
  String get companyAppsHint;

  /// No description provided for @companyAppsNone.
  ///
  /// In ar, this message translates to:
  /// **'لا تطبيقات.'**
  String get companyAppsNone;

  /// No description provided for @companyAppsLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح التطبيق'**
  String get companyAppsLoadFailed;

  /// No description provided for @friendsStar.
  ///
  /// In ar, this message translates to:
  /// **'تمييز'**
  String get friendsStar;

  /// No description provided for @friendsUnstar.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التمييز'**
  String get friendsUnstar;

  /// No description provided for @friendsMessage.
  ///
  /// In ar, this message translates to:
  /// **'رسالة'**
  String get friendsMessage;

  /// No description provided for @friendsRecent.
  ///
  /// In ar, this message translates to:
  /// **'المضافون حديثاً'**
  String get friendsRecent;

  /// No description provided for @friendsNewMark.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get friendsNewMark;

  /// No description provided for @friendsContactsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} جهات اتصال'**
  String friendsContactsCount(int count);

  /// No description provided for @friendsGroupsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد دردشات جماعية بعد'**
  String get friendsGroupsEmpty;

  /// No description provided for @friendsStarredEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مميّزون. اضغط مطولاً على صديق لتمييزه.'**
  String get friendsStarredEmpty;

  /// No description provided for @contactProfileYou.
  ///
  /// In ar, this message translates to:
  /// **'أنت'**
  String get contactProfileYou;

  /// No description provided for @contactProfileRemark.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة'**
  String get contactProfileRemark;

  /// No description provided for @contactProfileSetRemark.
  ///
  /// In ar, this message translates to:
  /// **'تعيين ملاحظة'**
  String get contactProfileSetRemark;

  /// No description provided for @contactProfileRemarkHint.
  ///
  /// In ar, this message translates to:
  /// **'اسم يظهر لك فقط على هذا الجهاز'**
  String get contactProfileRemarkHint;

  /// No description provided for @contactProfileRealName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم: {name}'**
  String contactProfileRealName(String name);

  /// No description provided for @contactProfileVoice.
  ///
  /// In ar, this message translates to:
  /// **'مكالمة صوتية'**
  String get contactProfileVoice;

  /// No description provided for @contactProfileVideo.
  ///
  /// In ar, this message translates to:
  /// **'مكالمة فيديو'**
  String get contactProfileVideo;

  /// No description provided for @contactProfileVoiceOrVideo.
  ///
  /// In ar, this message translates to:
  /// **'مكالمة صوتية أو فيديو'**
  String get contactProfileVoiceOrVideo;

  /// No description provided for @contactProfileSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ'**
  String get contactProfileSaved;

  /// No description provided for @contactProfileViewPhoto.
  ///
  /// In ar, this message translates to:
  /// **'عرض الصورة'**
  String get contactProfileViewPhoto;

  /// No description provided for @contactProfileCallFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر بدء المكالمة'**
  String get contactProfileCallFailed;

  /// No description provided for @contactMomentsNone.
  ///
  /// In ar, this message translates to:
  /// **'{name} لم ينشر أي شيء بعد.'**
  String contactMomentsNone(String name);

  /// No description provided for @contactMomentsNoneSelf.
  ///
  /// In ar, this message translates to:
  /// **'لم تنشر أي شيء بعد.'**
  String get contactMomentsNoneSelf;

  /// No description provided for @settingsMiniApps.
  ///
  /// In ar, this message translates to:
  /// **'التطبيقات المصغّرة'**
  String get settingsMiniApps;

  /// No description provided for @settingsMiniAppsHint.
  ///
  /// In ar, this message translates to:
  /// **'أرسل التطبيق المصغّر من موقع OBIC. يوافق المشرف الأعلى قبل أن يفتحه الآخرون.'**
  String get settingsMiniAppsHint;

  /// No description provided for @miniAppsWebsiteBody.
  ///
  /// In ar, this message translates to:
  /// **'تُرسل التطبيقات المصغّرة من موقع OBIC، وليس من الإعدادات. سجّل الدخول هناك بحساب OBIC، ثم أرسل الاسم والوصف والأيقونة وملف zip.'**
  String get miniAppsWebsiteBody;

  /// No description provided for @miniAppsOpenWebsite.
  ///
  /// In ar, this message translates to:
  /// **'فتح موقع OBIC'**
  String get miniAppsOpenWebsite;

  /// No description provided for @miniAppWebsiteName.
  ///
  /// In ar, this message translates to:
  /// **'موقع OBIC'**
  String get miniAppWebsiteName;

  /// No description provided for @miniAppFormTitle.
  ///
  /// In ar, this message translates to:
  /// **'إرسال تطبيق مصغّر'**
  String get miniAppFormTitle;

  /// No description provided for @miniAppName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get miniAppName;

  /// No description provided for @miniAppDescription.
  ///
  /// In ar, this message translates to:
  /// **'وصف قصير'**
  String get miniAppDescription;

  /// No description provided for @miniAppIconUrl.
  ///
  /// In ar, this message translates to:
  /// **'رابط الأيقونة (HTTPS)'**
  String get miniAppIconUrl;

  /// No description provided for @miniAppPickIcon.
  ///
  /// In ar, this message translates to:
  /// **'اختيار صورة الأيقونة'**
  String get miniAppPickIcon;

  /// No description provided for @miniAppIconUploading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ رفع الأيقونة…'**
  String get miniAppIconUploading;

  /// No description provided for @miniAppStartUrl.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الصفحة (HTTPS)'**
  String get miniAppStartUrl;

  /// No description provided for @miniAppSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get miniAppSubmit;

  /// No description provided for @miniAppMySubmissions.
  ///
  /// In ar, this message translates to:
  /// **'طلباتك'**
  String get miniAppMySubmissions;

  /// No description provided for @miniAppEmptyMine.
  ///
  /// In ar, this message translates to:
  /// **'لم ترسل تطبيقاً مصغّراً بعد.'**
  String get miniAppEmptyMine;

  /// No description provided for @miniAppSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'تم الإرسال. الحالة: قيد المراجعة حتى يراجعها المشرف الأعلى.'**
  String get miniAppSubmitted;

  /// No description provided for @miniAppHttpsRequired.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الصفحة يجب أن يكون رابط HTTPS.'**
  String get miniAppHttpsRequired;

  /// No description provided for @miniAppPickPackage.
  ///
  /// In ar, this message translates to:
  /// **'اختيار الحزمة'**
  String get miniAppPickPackage;

  /// No description provided for @miniAppPackageRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملف zip وفيه index.html في الجذر.'**
  String get miniAppPackageRequired;

  /// No description provided for @miniAppNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الاسم ووصفاً قصيراً.'**
  String get miniAppNameRequired;

  /// No description provided for @miniAppServerUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'التطبيقات المصغّرة ليست على هذا الخادم بعد. النموذج جاهز، وتبدأ المراجعة بعد تحديث واجهة البرمجة.'**
  String get miniAppServerUnavailable;

  /// No description provided for @miniAppStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get miniAppStatusPending;

  /// No description provided for @miniAppStatusApproved.
  ///
  /// In ar, this message translates to:
  /// **'مقبول'**
  String get miniAppStatusApproved;

  /// No description provided for @miniAppStatusRejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get miniAppStatusRejected;

  /// No description provided for @miniAppStatusDisabled.
  ///
  /// In ar, this message translates to:
  /// **'معطّل'**
  String get miniAppStatusDisabled;

  /// No description provided for @miniAppReviewReason.
  ///
  /// In ar, this message translates to:
  /// **'السبب'**
  String get miniAppReviewReason;

  /// No description provided for @miniAppEngineFail.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح هذا التطبيق المصغّر'**
  String get miniAppEngineFail;

  /// No description provided for @miniAppEngineReload.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تحميل'**
  String get miniAppEngineReload;

  /// No description provided for @miniAppEngineRestart.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تشغيل التطبيق المصغّر'**
  String get miniAppEngineRestart;

  /// No description provided for @miniAppEngineRetry.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get miniAppEngineRetry;

  /// No description provided for @discoverShortcuts.
  ///
  /// In ar, this message translates to:
  /// **'اختصارات'**
  String get discoverShortcuts;

  /// No description provided for @discoverTrending.
  ///
  /// In ar, this message translates to:
  /// **'الرائج'**
  String get discoverTrending;

  /// No description provided for @discoverOffers.
  ///
  /// In ar, this message translates to:
  /// **'العروض'**
  String get discoverOffers;

  /// No description provided for @discoverMusic.
  ///
  /// In ar, this message translates to:
  /// **'الموسيقى'**
  String get discoverMusic;

  /// No description provided for @discoverNew.
  ///
  /// In ar, this message translates to:
  /// **'الجديد'**
  String get discoverNew;

  /// No description provided for @discoverNewHint.
  ///
  /// In ar, this message translates to:
  /// **'التطبيقات المصغّرة والجديد'**
  String get discoverNewHint;

  /// No description provided for @discoverEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا شيء للعرض الآن'**
  String get discoverEmpty;

  /// No description provided for @servicesRecent.
  ///
  /// In ar, this message translates to:
  /// **'الأخيرة'**
  String get servicesRecent;

  /// No description provided for @servicesRecentEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد خدمات أخيرة'**
  String get servicesRecentEmpty;

  /// No description provided for @servicesHeroTitle.
  ///
  /// In ar, this message translates to:
  /// **'الصين والعالم'**
  String get servicesHeroTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
