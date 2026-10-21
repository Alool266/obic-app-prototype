// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OBIC';

  @override
  String get tagline => 'Social life & daily services in China';

  @override
  String get tabHome => 'Home';

  @override
  String get tabServices => 'Services';

  @override
  String get tabMoments => 'Moments';

  @override
  String get tabDiscover => 'Discover';

  @override
  String get tabMessages => 'Messages';

  @override
  String get tabOrders => 'Orders';

  @override
  String get tabMe => 'Me';

  @override
  String get tabContacts => 'Contacts';

  @override
  String get homeGreeting => 'Social life & daily China';

  @override
  String get homeHint =>
      'Chat, Moments, friends and calls — plus food, hotels, health, travel and more.';

  @override
  String get servicesTitle => 'All services';

  @override
  String get servicesHint =>
      'Browse the catalog freely. Requesting requires sign-in.';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messagesHint => 'Support chat, friends, and alerts.';

  @override
  String get messagesEmpty => 'No conversations yet. Start a chat with staff.';

  @override
  String get messagesEmptyGuest =>
      'Sign in to view your chats and message staff.';

  @override
  String get messagesNoPreview => 'No messages yet';

  @override
  String get chatSupportTitle => 'OBIC Support';

  @override
  String get chatTalkToStaff => 'Talk to staff';

  @override
  String get chatTalkToStaffDone => 'Staff will reply here soon';

  @override
  String get chatTalkToStaffBusy => 'Connecting…';

  @override
  String get chatHandoffTitle => 'Connect to staff';

  @override
  String get chatHandoffHint =>
      'Choose your branch and service so we route you to the right desk.';

  @override
  String get chatHandoffBranch => 'Branch';

  @override
  String get chatHandoffService => 'Service / desk';

  @override
  String get chatHandoffOrderRef => 'Order / case reference (optional)';

  @override
  String get chatHandoffOrderRefHint => 'e.g. visa or order number';

  @override
  String get chatHandoffNote => 'Note (optional)';

  @override
  String get chatHandoffNoteHint => 'Short note for staff';

  @override
  String get chatHandoffSubmit => 'Connect me';

  @override
  String get chatHandoffCancel => 'Cancel';

  @override
  String get chatHandoffUseNearest => 'Use nearest branch';

  @override
  String get chatAddPeopleTitle => 'Add people';

  @override
  String get chatAddPeopleHint =>
      'Invite other branch desk staff into this chat';

  @override
  String get chatAddPeopleEmpty => 'No other desk staff available to add';

  @override
  String get chatAddPeopleSubmit => 'Add selected';

  @override
  String get chatHandoffSummaryTitle => 'Summary for Secretary';

  @override
  String get chatInputHint => 'Type a message…';

  @override
  String get attachImage => 'Attach image';

  @override
  String get attachFile => 'Attach file';

  @override
  String get attachClear => 'Clear attachment';

  @override
  String get chatHoldToTalk => 'Hold to talk';

  @override
  String get chatReleaseToSend => 'Release to send';

  @override
  String get chatSlideToCancel => 'Release to cancel';

  @override
  String get chatVoiceTooShort => 'Voice message too short';

  @override
  String get chatMicPermissionDenied =>
      'Microphone permission is required for voice messages';

  @override
  String get chatVoiceMode => 'Voice message';

  @override
  String get chatVideoTooLarge =>
      'Video is too large (max 80MB). Try a shorter clip.';

  @override
  String get chatVideoLargeWarning =>
      'Video is over 12MB — may not survive trial redeploy until S3. Sending anyway.';

  @override
  String get chatVideoPickFailed =>
      'Could not read that video. Try another clip.';

  @override
  String get mediaAlbum => 'Album';

  @override
  String get mediaCamera => 'Camera';

  @override
  String get mediaVideo => 'Video';

  @override
  String get mediaVideoTitle => 'Video';

  @override
  String get mediaFromAlbum => 'From album';

  @override
  String get mediaRecordVideo => 'Record video';

  @override
  String get mediaCameraPermissionDenied =>
      'Camera permission is required. Enable it in Settings.';

  @override
  String get mediaPhotosPermissionDenied =>
      'Photo library permission is required. Enable it in Settings.';

  @override
  String get mediaPickFailed =>
      'Could not open the camera or album. Try again.';

  @override
  String get momentsAddMedia => 'Add';

  @override
  String get momentsTextOnly => 'Text';

  @override
  String get momentsTakePhoto => 'Take photo';

  @override
  String get chatImageLoadFailed =>
      'Couldn\'t load this image. Check your connection and try again.';

  @override
  String get chatPreviewVoice => '[Voice]';

  @override
  String get chatPreviewVideo => '[Video]';

  @override
  String get chatPreviewImage => '[Image]';

  @override
  String get chatPreviewFile => '[File]';

  @override
  String get momentsTitle => 'Moments';

  @override
  String get momentsEmpty => 'No moments yet — be the first to post.';

  @override
  String get momentsCreate => 'New moment';

  @override
  String get momentsHint => 'What\'s on your mind?';

  @override
  String get momentsPost => 'Post';

  @override
  String get momentsAnon => 'User';

  @override
  String get momentsDelete => 'Delete';

  @override
  String get momentsDeleteConfirm =>
      'Delete this Moment? Friends will no longer see it.';

  @override
  String get momentsDeleted => 'Moment deleted';

  @override
  String get momentsPrivacyWhoCanSee => 'Who can see';

  @override
  String get momentsPrivacyFriends => 'All friends';

  @override
  String get momentsPrivacyFriendsHint => 'Visible to your mutual friends';

  @override
  String get momentsPrivacyPrivate => 'Private';

  @override
  String get momentsPrivacyPrivateHint => 'Only you can see this';

  @override
  String get momentsPrivacyPartial => 'Share with…';

  @override
  String get momentsPrivacyPartialHint => 'Only selected friends can see';

  @override
  String momentsPrivacyPartialSelected(int n) {
    return '$n friends';
  }

  @override
  String get momentsPrivacyExclude => 'Don\'t share with…';

  @override
  String get momentsPrivacyExcludeHint => 'Hide from selected friends';

  @override
  String momentsPrivacyExcludeSelected(int n) {
    return 'Hidden from $n';
  }

  @override
  String get momentsPrivacyNeedFriends => 'Select at least one friend';

  @override
  String get momentsPrivacyDone => 'Done';

  @override
  String get momentsOfficial => 'Official';

  @override
  String get momentsAddPhotos => 'Photos';

  @override
  String get momentsAddVideos => 'Videos';

  @override
  String get momentsAddFiles => 'Files';

  @override
  String get momentsChangeAvatar => 'Change photo';

  @override
  String get momentsStaff => 'Staff';

  @override
  String get momentsJustNow => 'Just now';

  @override
  String momentsMinutesAgo(Object n) {
    return '${n}m ago';
  }

  @override
  String momentsHoursAgo(Object n) {
    return '${n}h ago';
  }

  @override
  String momentsDaysAgo(Object n) {
    return '${n}d ago';
  }

  @override
  String get momentsLike => 'Like';

  @override
  String get momentsUnlike => 'Unlike';

  @override
  String get momentsComment => 'Comment';

  @override
  String get momentsCommentHint => 'Write a comment…';

  @override
  String get momentsReplyHint => 'Write a reply…';

  @override
  String get momentsCommentAddPhoto => 'Add photo';

  @override
  String get momentsCommentTakePhoto => 'Take photo';

  @override
  String get momentsCommentSendFailed => 'Could not send comment';

  @override
  String get momentsCommentDelete => 'Delete';

  @override
  String get momentsCommentDeleteConfirm => 'Delete this comment?';

  @override
  String get momentsCommentDeleted => 'Comment deleted';

  @override
  String get momentsReply => 'Reply';

  @override
  String momentsReplyTo(Object name) {
    return 'Reply to $name';
  }

  @override
  String get momentsRepliedTo => 'replied to';

  @override
  String get momentsFavorite => 'Favorite';

  @override
  String get momentsFavorited => 'Saved to Favorites';

  @override
  String get momentsReport => 'Report';

  @override
  String get momentsReported => 'Reported — SuperAdmin will review';

  @override
  String get momentsDownload => 'Save to Photos';

  @override
  String get momentsSaved => 'Saved to Photos';

  @override
  String get momentsSaveFailed => 'Could not save';

  @override
  String get momentsFileSaved => 'File saved';

  @override
  String get momentsNoLikes => 'Be the first to like';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'You\'re all caught up.';

  @override
  String get notificationsMarkAll => 'Mark all read';

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsList => 'Your friends';

  @override
  String get friendsEmpty => 'No friends yet — search by phone or id.';

  @override
  String get friendsAdd => 'Add friend';

  @override
  String get friendsSearchHint => 'Phone number or OBIC ID';

  @override
  String get friendsIncoming => 'Friend requests';

  @override
  String get friendsAccept => 'Accept';

  @override
  String get friendsReject => 'Decline';

  @override
  String get friendsRequestSent => 'Friend request sent';

  @override
  String get friendsNewFriends => 'New Friends';

  @override
  String get friendsNewFriendsEmpty => 'No pending friend requests.';

  @override
  String get friendsOutgoing => 'Sent';

  @override
  String get friendsWaiting => 'Waiting';

  @override
  String get friendsAcceptedToast => 'You are now friends';

  @override
  String get friendsSendRequestTitle => 'Friend request';

  @override
  String get friendsVerificationHint => 'Say hello — optional note';

  @override
  String get friendsSend => 'Send';

  @override
  String get friendsCancel => 'Cancel';

  @override
  String get friendsAlreadyFriends => 'Friends';

  @override
  String friendsRequestAlert(String name) {
    return '$name sent you a friend request';
  }

  @override
  String get friendsViewRequests => 'View';

  @override
  String get friendsEmployeeNote =>
      'Employees cannot add customers as friends.';

  @override
  String get friendsByPhone => 'Search';

  @override
  String get friendsByQr => 'By QR';

  @override
  String get friendsMyQr => 'My QR';

  @override
  String get friendsScanQr => 'Scan QR';

  @override
  String get friendsQrHint =>
      'Ask a friend to scan your code, or scan theirs to add.';

  @override
  String get friendsQrPayloadHint => 'Or paste an OBIC QR code here';

  @override
  String get friendsQrInvalid => 'Invalid QR code';

  @override
  String get profileObicId => 'OBIC ID';

  @override
  String get profileObicIdHint => '6–20 chars, start with a letter';

  @override
  String get profileObicIdFirstHint =>
      'Set your OBIC ID so friends can find you. You can change it once per year.';

  @override
  String get profileObicIdYearHint =>
      'You can change your OBIC ID once every 365 days.';

  @override
  String profileObicIdCooldownAt(Object date) {
    return 'Next change available on $date';
  }

  @override
  String profileObicIdCooldownData(Object date) {
    return 'OBIC ID can only be changed once every 365 days. Next change on $date.';
  }

  @override
  String get profileObicIdCooldownHint =>
      'OBIC ID can only be changed once every 365 days.';

  @override
  String get meObicId => 'OBIC ID';

  @override
  String get meObicIdUnset => 'Not set';

  @override
  String get meMyQr => 'My QR code';

  @override
  String get chatComposeHint => 'Message…';

  @override
  String get chatGroup => 'Group';

  @override
  String get ordersTitle => 'My requests';

  @override
  String get ordersHint =>
      'Orders are yours only; the API enforces ownership checks.';

  @override
  String get meTitle => 'Me';

  @override
  String get meFavorites => 'Favorites';

  @override
  String get mePayServices => 'Pay and Services';

  @override
  String get payDemoBannerTitle => 'Example for trial';

  @override
  String get payDemoBannerBody =>
      'This is a demo Pay & Services hub — layout only, no real payments yet.';

  @override
  String get payDemoSectionMoney => 'Money';

  @override
  String get payDemoSectionShortcuts => 'Services shortcuts';

  @override
  String get payDemoSectionOffers => 'OBIC offers';

  @override
  String get payDemoWallet => 'Wallet';

  @override
  String get payDemoTransfer => 'Transfer';

  @override
  String get payDemoReceive => 'Receive';

  @override
  String get payDemoCards => 'Cards';

  @override
  String get payDemoDailyServices => 'Daily services';

  @override
  String get payDemoVisa => 'Visa';

  @override
  String get payDemoBanking => 'Banking';

  @override
  String get payDemoTravel => 'Travel';

  @override
  String get payDemoOfferVip => 'VIP China';

  @override
  String get payDemoOfferPartner => 'Partner deal';

  @override
  String get payDemoOfferSeasonal => 'Seasonal';

  @override
  String get payDemoOfferComing => 'Coming soon';

  @override
  String get payDemoOpenRealServices => 'Open full Services tab';

  @override
  String get payDemoFooter =>
      'Placeholder UI for product trial. Real wallet and payments come later.';

  @override
  String payDemoTileSnack(String label) {
    return '$label — example only';
  }

  @override
  String get meMyPosts => 'My Posts';

  @override
  String get meWorks => 'Works';

  @override
  String get meChannelHint => 'Watch my channel here';

  @override
  String get meStatus => 'Status';

  @override
  String meFriendsCount(int count) {
    return '$count friends';
  }

  @override
  String get meHint =>
      'Profile, language, and sign-in — no privilege lives on the device.';

  @override
  String get meGuestHint =>
      'Sign in for chat, Moments, orders, and daily services across China.';

  @override
  String get meRole => 'Role';

  @override
  String get addressesTitle => 'My addresses';

  @override
  String get addressesAdd => 'Add address';

  @override
  String get addressesEdit => 'Edit address';

  @override
  String get addressesEmpty =>
      'No saved addresses yet. Add one for food delivery and service requests.';

  @override
  String get addressesLabel => 'Label';

  @override
  String get addressesLine1 => 'Street / building';

  @override
  String get addressesLine2 => 'Apt / floor';

  @override
  String get addressesCity => 'City';

  @override
  String get addressesDistrict => 'District / area';

  @override
  String get addressesNotes => 'Delivery notes';

  @override
  String get addressesOptional => 'optional';

  @override
  String get addressesSave => 'Save address';

  @override
  String get addressesSetDefault => 'Default address';

  @override
  String get addressesDefaultBadge => 'Default';

  @override
  String get addressesDeleteTitle => 'Delete address?';

  @override
  String get addressesDeleteBody =>
      'This address will be removed from your profile.';

  @override
  String get addressesDeleteConfirm => 'Delete';

  @override
  String get addressesRequiredFields => 'Label, street, and city are required.';

  @override
  String get addressesPickTitle => 'Deliver to';

  @override
  String get aboutObicBlurb =>
      'OBIC is more than services — a social app for life in China: chat, Moments, food, hotels, health and travel.';

  @override
  String get aboutCredit => 'Made by Dr Ali';

  @override
  String get languageToggle => '中文';

  @override
  String get authLogin => 'Sign in';

  @override
  String get authRegister => 'Register';

  @override
  String get authEmailTab => 'Email';

  @override
  String get authPhoneTab => 'Phone';

  @override
  String get authUseSmsCode => 'Sign in with SMS code';

  @override
  String get authUsePassword => 'Sign in with password';

  @override
  String get authSendCode => 'Send code';

  @override
  String get authSmsCodeHint => 'New numbers are registered automatically';

  @override
  String get authUseEmail => 'Use email';

  @override
  String get authUsePhone => 'Use phone';

  @override
  String get authEmail => 'Email';

  @override
  String get authPhone => 'Phone';

  @override
  String get authName => 'Full name';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'At least 8 characters';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authLogout => 'Log out';

  @override
  String get authOrContinue => 'Or continue with';

  @override
  String get authContinueGoogle => 'Continue with Google';

  @override
  String get authContinueApple => 'Continue with Apple';

  @override
  String get authSocialNotConfigured =>
      'Google or Apple sign-in is not set up on this build yet.';

  @override
  String get authProviderEmailNotVerified =>
      'Apple or Google did not confirm this email, so OBIC will not skip email verification.';

  @override
  String get authSocialRoleNotAllowed =>
      'This email is a staff account. Sign in with your password.';

  @override
  String get authInvalidSocialToken =>
      'That Google or Apple sign-in could not be verified. Try again.';

  @override
  String get authComingSoon => 'Coming soon';

  @override
  String get authEmailRequired => 'Enter your email';

  @override
  String get authPhoneRequired => 'Enter your phone';

  @override
  String get authFailed => 'Could not sign in';

  @override
  String get authTotpHint =>
      'Enter the 6-digit code from your Authenticator app';

  @override
  String get authTotpCode => 'Authenticator code';

  @override
  String get authTotpVerify => 'Verify';

  @override
  String get authTotpBack => 'Back to sign in';

  @override
  String get authNetworkError =>
      'Network error — check connection and try again';

  @override
  String get authServerWaking =>
      'Server is waking up — wait a few seconds and try again';

  @override
  String get authStillConnecting =>
      'Still connecting — the server may be waking up';

  @override
  String get authRequiredTitle => 'Sign in required';

  @override
  String get authRequiredBody =>
      'Browsing is open to everyone. To request a service, place an order, chat, post a moment, or add friends, sign in or create an account.';

  @override
  String get authClose => 'Close';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authJoinHeadline => 'Join OBIC';

  @override
  String get authSignInSupport =>
      'Chat with friends · Order food · Book hotels · Health & more';

  @override
  String get authRegisterSupport =>
      'Chat, Moments, food, hotels, health and OBIC services — in one app.';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authNoAccount => 'New here?';

  @override
  String get authHasAccount => 'Already have an account?';

  @override
  String get authGoRegister => 'Create one';

  @override
  String get authGoLogin => 'Sign in';

  @override
  String get actionRequestService => 'Request this service';

  @override
  String get actionPlaceOrder => 'Place an order';

  @override
  String get actionChatStaff => 'Chat with staff';

  @override
  String get obicAiTitle => 'OBIC AI';

  @override
  String get obicAiWelcome =>
      'Ask about any app service — property, transport, travel, healthcare, food, shopping, education, logistics, government, business, visas, hotels, offers, or branches — or your order status. Staff can still help anytime.';

  @override
  String get obicAiInputHint => 'Ask OBIC AI…';

  @override
  String get obicAiOfflineHint =>
      'OBIC AI is off on this server until the team enables it. You can still chat with staff.';

  @override
  String get obicAiEmptyReply => 'No reply yet — try again or chat with staff.';

  @override
  String get obicAiTabInstructions => 'Guide';

  @override
  String get obicAiTabChat => 'Chat';

  @override
  String get obicAiTabHistory => 'History';

  @override
  String get obicAiNewChat => 'New chat';

  @override
  String get obicAiHistoryEmpty =>
      'No past chats yet. Ask something in Chat — it will appear here.';

  @override
  String get obicAiHistoryOpen => 'Open';

  @override
  String get obicAiHistoryDelete => 'Delete';

  @override
  String get obicAiCopy => 'Copy';

  @override
  String get obicAiCopied => 'Copied';

  @override
  String get obicAiNothingToCopy => 'Nothing to copy';

  @override
  String get obicAiRetry => 'Retry';

  @override
  String get obicAiStop => 'Stop';

  @override
  String get obicAiAttach => 'Attach';

  @override
  String get obicAiAttachPhoto => 'Photo';

  @override
  String get obicAiAttachPdf => 'PDF';

  @override
  String get obicAiAttachSheet => 'Spreadsheet';

  @override
  String get obicAiRemoveAttachment => 'Remove attachment';

  @override
  String get obicAiFileTooLarge =>
      'This file is over 4 MB. Choose a smaller one.';

  @override
  String get obicAiUnsupportedFile =>
      'Only JPEG, PNG, or WebP photos, PDF, and Excel or CSV spreadsheets are supported.';

  @override
  String get obicAiAttachmentNotConfigured =>
      'Image and file reading is not configured.';

  @override
  String get obicAiCouldNotReadFile => 'Could not read this file.';

  @override
  String get obicAiInstructionsTitle => 'How to use OBIC AI';

  @override
  String get obicAiInstructionsBody =>
      'What OBIC AI does\n• Answers questions about the full Services catalog — property, transport, travel, healthcare, food, shopping, education, logistics, government, and business — including visas, hotels, delivery, and the other listed items, plus Offers and branches.\n• Replies in your language — Arabic, English, Chinese, French, and others. Write naturally; it matches you.\n\nThis screen vs auto-reply\n• This Chat tab is your dedicated assistant. History keeps past Q&A so you can come back later.\n• Support and order chats may also get a short AI auto-reply.\n• Friend chats stay private — no AI there.\n\nTalk to staff\n• For a human, open Messages → OBIC Support or an order chat → Talk to staff.\n\nLanguages\n• App language (AR / EN / 中文 / FR) controls this screen’s labels.\n• Your message language controls the AI reply.';

  @override
  String obicAiBalance(String amount) {
    return 'Balance: $amount';
  }

  @override
  String get obicAiTopUp => 'Top up';

  @override
  String get obicAiTopUpTitle => 'Top up OBIC AI';

  @override
  String get obicAiTopUpBody =>
      'Pay ¥200 first. That becomes your balance. Each use then deducts a small amount: text ¥0.10, photo ¥0.20, PDF or spreadsheet ¥0.20. If the balance is too low for the next use, OBIC AI stops until you buy another ¥200 pack.';

  @override
  String get obicAiSandboxTopUp => 'Confirm sandbox top-up ¥200';

  @override
  String get obicAiSandboxNote => 'Sandbox: no real money is moved.';

  @override
  String get obicAiTopUpSuccess => '¥200 was added to your balance (sandbox).';

  @override
  String get obicAiBalanceLow =>
      'Balance too low. Top up a ¥200 pack to continue.';

  @override
  String get obicAiTopUpFailed => 'Top-up failed. Try again.';

  @override
  String get obicAiCardNotConnected => 'Card payment is not connected yet.';

  @override
  String get msgTranslate => 'Translate';

  @override
  String get msgShowOriginal => 'Show original';

  @override
  String get msgShowTranslation => 'Show translation';

  @override
  String get msgTranslating => 'Translating…';

  @override
  String get msgTranslateFailed => 'Translation failed — try again.';

  @override
  String get authSuccessContinue => 'Signed in — you can continue.';

  @override
  String get brandTag => 'Chat · Food · Hotels · Health & more';

  @override
  String get searchPlaceholder => 'Search food, hotels, health, visas…';

  @override
  String get featured => 'Featured';

  @override
  String get vipTrip => 'VIP China Trip';

  @override
  String get vipTripDesc =>
      'Airport pickup · Hotels · Factory visits · One dedicated manager';

  @override
  String get bookPkg => 'Book package →';

  @override
  String get fastTrack => 'Fast track';

  @override
  String get visaExpress => 'Visa Express';

  @override
  String get visaExpressDesc =>
      'Business & tourist visa support with checklist and advisor';

  @override
  String get from120 => 'From \$120 →';

  @override
  String get setup => 'Setup';

  @override
  String get openBank => 'Open bank account';

  @override
  String get openBankDesc => 'Local account guidance with branch coordination';

  @override
  String get startReq => 'Start request →';

  @override
  String get topServices => 'Top services';

  @override
  String get seeAll => 'See all';

  @override
  String get recommended => 'Recommended';

  @override
  String get regionDetecting => 'Detecting your region…';

  @override
  String get regionRefresh => 'Refresh';

  @override
  String get regionUnavailable => 'Not available in this region';

  @override
  String get nearMeTitle => 'Offices near you';

  @override
  String get nearMeHint => 'Sorted by distance from your location';

  @override
  String get allServices => 'All Services';

  @override
  String get serviceLabel => 'Service';

  @override
  String get officialBadge => 'OBIC Official';

  @override
  String get includedTitle => 'What\'s included';

  @override
  String get advisorTitle => 'Dedicated advisor';

  @override
  String get advisorDesc => 'Assigned after you submit a request';

  @override
  String get checklistTitle => 'Document checklist';

  @override
  String get checklistDesc => 'Clear steps inside your order';

  @override
  String get statusUpdatesTitle => 'Status updates';

  @override
  String get statusUpdatesDesc => 'Track progress under Orders';

  @override
  String get requestSvc => 'Request this service';

  @override
  String get chatSupport => 'Chat support';

  @override
  String get chatComingSoon => 'Opening support chat…';

  @override
  String get requestTitle => 'Request';

  @override
  String get prefBranch => 'Preferred branch';

  @override
  String get notesLabel => 'Notes';

  @override
  String get notesHint => 'Dates, goals, documents…';

  @override
  String get submitOrder => 'Submit order';

  @override
  String get orderSubmitted => 'Order submitted successfully.';

  @override
  String get ordersEmptyGuest => 'Sign in to see your requests.';

  @override
  String get ordersEmptyAuth =>
      'No requests yet — request a service from Home or talk to the OBIC team.';

  @override
  String get statusSubmitted => 'Submitted';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusWaitingCustomer => 'Waiting for you';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusWithAgent => 'With agent';

  @override
  String get requestTypeSupport => 'OBIC Support';

  @override
  String get orderChat => 'Chat about this order';

  @override
  String get legalTerms => 'Terms';

  @override
  String get legalPrivacy => 'Privacy Policy';

  @override
  String get legalAgreePrefix => 'By creating an account you agree to the';

  @override
  String get legalAnd => 'and';

  @override
  String get offlineBanner => 'Waiting for network…';

  @override
  String get offlineConnecting => 'Connecting…';

  @override
  String get offlineNeedsNetwork =>
      'You\'re offline — try again when connected.';

  @override
  String get offlineNoInternet =>
      'No internet connection. Check your network settings';

  @override
  String get msgWaitingNetwork => 'Waiting for network…';

  @override
  String get msgTapToResend => 'Tap to resend';

  @override
  String get networkUnavailable => 'Network unavailable. Please try again.';

  @override
  String get actionOk => 'OK';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get chatDayToday => 'Today';

  @override
  String get chatDayYesterday => 'Yesterday';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsFeatures => 'Features';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsAccountSecurity => 'Account security';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsMomentsNotifications => 'Moments notifications';

  @override
  String get settingsMomentsNotifyFriends =>
      'Notify me when friends post Moments';

  @override
  String get settingsMomentsMute => 'Mute Moments updates';

  @override
  String get settingsInterface => 'Language & display';

  @override
  String get settingsFriendsPermissions => 'Friends\' permissions';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsChats => 'Chats';

  @override
  String get settingsVoiceVideo => 'Voice & video calls';

  @override
  String get profileName => 'Name';

  @override
  String get profilePhoto => 'Profile Photo';

  @override
  String get profileGender => 'Gender';

  @override
  String get profileGenderMale => 'Male';

  @override
  String get profileGenderFemale => 'Female';

  @override
  String get profileGenderOther => 'Other';

  @override
  String get profileGenderUnset => 'Not set';

  @override
  String get profileRegion => 'Region';

  @override
  String get profileMobile => 'Mobile Number';

  @override
  String get profileWhatsUp => 'What\'s Up';

  @override
  String get profileWhatsUpHint =>
      'A short status line friends see on your album';

  @override
  String get profileMyQr => 'My QR Code';

  @override
  String get profileId => 'ID';

  @override
  String get momentsPin => 'Pin';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileCity => 'City';

  @override
  String get profileCountry => 'Country';

  @override
  String get profileEmailReadOnly => 'Email cannot be changed here';

  @override
  String get profileSave => 'Save';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get securityChangePassword => 'Change password';

  @override
  String get securityCurrentPassword => 'Current password';

  @override
  String get securityNewPassword => 'New password';

  @override
  String get securityPasswordChanged => 'Password updated';

  @override
  String get securityLinkedAccounts => 'Linked sign-in';

  @override
  String get friendsMuteMoments => 'Don\'t see their Moments';

  @override
  String get friendsMuteMomentsHint =>
      'Hide their Moments from your feed and stop badges/notifications';

  @override
  String get friendsHideMyMoments => 'Don\'t let them see my Moments';

  @override
  String get friendsNoFriends => 'No friends yet';

  @override
  String get storageClearCache => 'Clear offline cache';

  @override
  String get storageCleared => 'Cache cleared';

  @override
  String get storageCacheHint =>
      'Clears saved Moments, chats, and offline copies on this device';

  @override
  String get storageClearConfirm =>
      'Clear cached photos and files on this phone? Chats and sign-in stay.';

  @override
  String storageFreed(String size) {
    return '$size freed';
  }

  @override
  String get storageImages => 'Images';

  @override
  String get storageVideos => 'Videos';

  @override
  String get storageVoice => 'Voice';

  @override
  String get storageFiles => 'Files';

  @override
  String get storageMusic => 'Downloaded music';

  @override
  String get storageChats => 'Chats';

  @override
  String get storageChatsHint =>
      'Kept on this phone. Clearing cache does not remove them.';

  @override
  String get storageClearMusic => 'Clear downloaded music';

  @override
  String get storageAutoDelete => 'Delete old cache';

  @override
  String get storageAutoNever => 'Never';

  @override
  String storageAutoDays(int days) {
    return '$days days';
  }

  @override
  String get chatsEnterSend => 'Press Enter to send';

  @override
  String get chatsConfirmDelete => 'Ask before deleting messages';

  @override
  String get voiceSpeakerDefault => 'Speaker by default on voice calls';

  @override
  String get voiceVideoPreview => 'Show my video preview';

  @override
  String get settingsSaved => 'Saved';

  @override
  String get switchAccountTitle => 'Switch account';

  @override
  String get switchAccountHint => 'Tap profile photo to switch accounts';

  @override
  String get switchAccountAdd => 'Add account';

  @override
  String get momentsCopyLink => 'Copy link';

  @override
  String get momentsCopied => 'Link copied';

  @override
  String get momentsCopyText => 'Copy';

  @override
  String get momentsTextCopied => 'Copied';

  @override
  String get momentsTranslate => 'Translate';

  @override
  String get momentsMyAlbum => 'My Moments';

  @override
  String momentsFriendAlbum(String name) {
    return '$name\'s Moments';
  }

  @override
  String get momentsCoverTapHint => 'Tap cover to change';

  @override
  String get momentsCoverAdjust => 'Adjust cover';

  @override
  String get momentsCoverSave => 'Done';

  @override
  String get momentsCoverAdjustHint =>
      'Drag to move · pinch to zoom · then tap Done';

  @override
  String get channelTitle => 'Channels';

  @override
  String get callErrorGeneric => 'Could not connect — try again';

  @override
  String get callErrorPermission =>
      'Camera or microphone permission is required';

  @override
  String get callErrorJoin =>
      'Call could not start — check network and try again';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsDarkMode => 'Dark mode';

  @override
  String get settingsSupportSafety => 'Support & safety';

  @override
  String get settingsContactSupport => 'Contact support';

  @override
  String get settingsReportBug => 'Report a bug';

  @override
  String get settingsRestoreAccount => 'Restore account';

  @override
  String get restoreAccountHint =>
      'Ask OBIC staff to restore a soft-deleted account from Admin';

  @override
  String get restoreAccountDialog =>
      'There is no self-service restore. Contact OBIC support with your email or phone — SuperAdmin or Ops staff can restore your account from Admin. After restore, sign in with the same password.';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountBody =>
      'Your account will be deactivated. You will be signed out and removed from this device. Staff can restore it from Admin if needed.';

  @override
  String get deleteAccountPasswordRequired => 'Current password (required)';

  @override
  String get deleteAccountSuperAdminRule =>
      'SuperAdmin: you can only delete this account if another SuperAdmin still exists. The last SuperAdmin cannot self-delete.';

  @override
  String get deleteAccountConfirm => 'Delete';

  @override
  String get deleteAccountDone => 'Account deleted on this device';

  @override
  String get reportBugTitle => 'Report a bug';

  @override
  String get reportBugDescriptionHint =>
      'Describe what happened (5+ characters)';

  @override
  String get reportBugAddPhotos => 'Add photos';

  @override
  String get reportBugSubmit => 'Submit';

  @override
  String get reportBugThanks => 'Thanks — our team will review your report';

  @override
  String get reportBugTooShort => 'Please add a bit more detail';

  @override
  String get themeSystem => 'Match system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get chatMute => 'Mute notifications';

  @override
  String get chatUnmute => 'Unmute notifications';

  @override
  String get chatMuted => 'Chat muted';

  @override
  String get chatUnmuted => 'Chat unmuted';

  @override
  String get chatHide => 'Hide chat';

  @override
  String get chatHideConfirm =>
      'Hide this chat from your list? Opening it again will bring it back.';

  @override
  String get chatClearHistory => 'Clear history';

  @override
  String get chatClearHistoryConfirm =>
      'Clear messages in this chat for you? This cannot be undone.';

  @override
  String get chatDelete => 'Delete chat';

  @override
  String get chatDeleteConfirm =>
      'Delete this chat from your list and clear history for you?';

  @override
  String get chatMarkUnread => 'Mark as Unread';

  @override
  String get chatPin => 'Pin to Top';

  @override
  String get chatUnpin => 'Unpin';

  @override
  String get chatDraftPrefix => '[Draft]';

  @override
  String get chatRecall => 'Recall';

  @override
  String get chatRecalledYou => 'You recalled a message';

  @override
  String get chatRecalledPeer => 'A message was recalled';

  @override
  String get errorProfileFieldsUnsupported =>
      'Could not save profile. Please update the app and try again.';

  @override
  String get errorWrongPassword => 'Current password is incorrect';

  @override
  String get errorEmailTaken => 'That email is already in use';

  @override
  String get errorObicIdTaken => 'That OBIC ID is already taken';

  @override
  String get errorGenericRetry => 'Something went wrong — please try again';

  @override
  String get errorUploadFailed =>
      'Could not upload the photo — try another image';

  @override
  String get errorMomentsCoverFailed =>
      'Could not update Moments cover — try again';

  @override
  String get errorOnlySecretaryCanUpdateStatus =>
      'Only the Secretary can update status';

  @override
  String get profileObicIdCopied => 'OBIC ID copied';

  @override
  String get profileSetObicId => 'Set OBIC ID';

  @override
  String get profileChangeObicId => 'Change ID';

  @override
  String get profileEmailPasswordRequired =>
      'Current password (to change email)';

  @override
  String get profileEmailChangeHint =>
      'Changing email requires your password. The old email can no longer sign in.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get verifyOtpTitle => 'Enter verification code';

  @override
  String get verifyOtpEmailHint => 'We sent a 6-digit code to your email';

  @override
  String get verifyOtpPhoneHint => 'We sent a 6-digit code to your phone';

  @override
  String get verifyOtpPhoneViaEmailHint =>
      'For now the code is sent to your email. SMS verification comes later.';

  @override
  String get verifyOtpPhoneTrialEmailHint =>
      'For now the code is sent to your email. SMS verification comes later.';

  @override
  String get verifyOtpPhoneTrialLogHint =>
      'Enter the verification code from your email';

  @override
  String get verifyOtpSmsNotConfigured =>
      'SMS is not configured yet. Try again later or contact support';

  @override
  String get verifyOtpSmsSendFailed => 'Could not send SMS. Try again shortly';

  @override
  String get verifyOtpEmailSendFailed =>
      'Could not send the email code. Check your address and try again';

  @override
  String get verifyOtpEmailRequiredForPhone =>
      'Add an email address to receive the verification code';

  @override
  String get verifyOtpInvalid => 'Enter the 6-digit code';

  @override
  String get verifyOtpWrongCode => 'Invalid code';

  @override
  String get verifyOtpExpired => 'Code expired — request a new one';

  @override
  String get verifyOtpTooManyAttempts =>
      'Too many attempts — request a new code';

  @override
  String get verifyOtpSessionExpired =>
      'Verification session expired — start again';

  @override
  String get verifyOtpConfirm => 'Verify';

  @override
  String get verifyOtpResend => 'Resend code';

  @override
  String verifyOtpResendIn(Object seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get verifyOtpResent => 'Code sent';

  @override
  String verifyOtpTrialCode(Object code) {
    return 'Test code: $code';
  }

  @override
  String get friendsCopyObicId => 'Copy OBIC ID';

  @override
  String get phoneVerifyTitle => 'Verify phone';

  @override
  String get phoneVerifyHeadline => 'China mobile required';

  @override
  String get phoneVerifyBody =>
      'Users in China must add and verify a mainland mobile number (+86) before using chat and orders. Settings and language stay available.';

  @override
  String get phoneVerifyBodyEmailOtp =>
      'Enter your mainland mobile (+86). For now we verify it with an email code; SMS comes later.';

  @override
  String get phoneVerifyEmailForCodeHint => 'Email for verification code';

  @override
  String get phoneVerifySendCode => 'Send verification code';

  @override
  String get phoneVerifyOpenSettings => 'Language + Appearance';

  @override
  String get phoneVerifyLater => 'Activate later';

  @override
  String get phoneVerifyLocked =>
      'You can look around. Activate your number before you do anything.';

  @override
  String get phoneVerifyActivate => 'Activate number';

  @override
  String get phoneChinaOnly => 'China mainland numbers only (+86 / 1[3-9]…)';

  @override
  String get smsPhoneCountries =>
      'Use a mobile number from China, Saudi Arabia, or Yemen.';

  @override
  String get smsCountryChina => 'China +86';

  @override
  String get smsCountrySaudi => 'Saudi Arabia +966';

  @override
  String get smsCountryYemen => 'Yemen +967';

  @override
  String get phoneVerifyBlocked => 'Verify your China mobile to continue';

  @override
  String get emailVerifyTitle => 'Verify email';

  @override
  String get emailVerifyHeadline => 'Email verification required';

  @override
  String get emailVerifyBody =>
      'Users in China must verify their email before using chat and orders. We send a code to your inbox.';

  @override
  String get emailVerifySendCode => 'Send email code';

  @override
  String get authChinaPhoneRequired =>
      'In China, register with mainland mobile (+86) and email for the code';

  @override
  String get profileUseCurrentLocation => 'Use current location';

  @override
  String get profileLocationDetecting => 'Detecting location…';

  @override
  String profileLocationDetail(String detail) {
    return 'Nearby: $detail';
  }

  @override
  String get profilePickCountry => 'Choose country';

  @override
  String get profilePickCity => 'Choose city';

  @override
  String get profileSearchCountry => 'Search country';

  @override
  String get profileSearchCity => 'Search city';

  @override
  String get profileLocationFailed =>
      'Could not detect location — pick country and city';

  @override
  String get miniAppsTitle => 'Mini apps';

  @override
  String get miniAppsPullCue => 'Pull down for Mini apps';

  @override
  String get miniAppsPullHint => 'Approved mini apps';

  @override
  String get miniAppsTipTitle => 'Mini apps are here';

  @override
  String get miniAppsTipBody =>
      'Pull down from the top of Home, or tap the Mini apps bar, to open approved mini apps.';

  @override
  String get miniAppsTipTry => 'Try it';

  @override
  String get miniAppsTipDismiss => 'Got it';

  @override
  String get miniAppsSearchHint => 'Search mini-apps';

  @override
  String get miniAppsEmptySearch => 'No matching mini-apps';

  @override
  String get miniAppsClose => 'Close';

  @override
  String get miniAppsCloseHint => 'Swipe up to close';

  @override
  String get miniAppsExampleBadge => 'Ex.';

  @override
  String get miniAppsPartnerBadge => 'Example mini-app';

  @override
  String get miniAppsComingSoonBody =>
      'Only an approved mini app opens inside OBIC.';

  @override
  String get miniAppsPartnerHint =>
      'Submit a page from Settings → Mini apps. After SuperAdmin approval it appears here. Rejected and disabled apps stay closed.';

  @override
  String get channelDescription => 'Short videos from OBIC staff and friends';

  @override
  String get channelFollow => 'Follow';

  @override
  String get channelFollowing => 'Following';

  @override
  String channelStats(int followers, int videos) {
    return '$followers followers · $videos videos';
  }

  @override
  String channelLimitsHint(int mb, int sec) {
    return 'Clips up to $mb MB and $sec seconds';
  }

  @override
  String get channelEmpty => 'No videos yet — be the first to upload';

  @override
  String get channelUpload => 'Upload';

  @override
  String get channelUploadTitle => 'Upload short video';

  @override
  String get channelUploadLimits => 'Max 40 MB and 60 seconds';

  @override
  String get channelCaptionHint => 'Add a caption (optional)';

  @override
  String get channelUploadDone => 'Video posted';

  @override
  String get channelVideoTooLarge => 'Video is too large (max 40 MB)';

  @override
  String get channelVideoTooLong => 'Video is too long (max 60 seconds)';

  @override
  String get channelNoCaption => 'Short video';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get discoverMiniAppsHint => 'Open mini-apps · or pull down on Home';

  @override
  String get channelTabFollow => 'Follow';

  @override
  String get channelTabNearby => 'Nearby';

  @override
  String get channelTabFriends => 'Friends';

  @override
  String get channelTabHot => 'Hot';

  @override
  String get channelMyChannel => 'My Channel';

  @override
  String get channelOfficialShort => 'OBIC Official';

  @override
  String get channelPostDenied =>
      'Only friends can view personal Channels. Staff post on Official.';

  @override
  String get channelShared => 'Copied — share count updated';

  @override
  String get channelShareTitle => 'Share';

  @override
  String get channelShareToMoments => 'Share to Moments';

  @override
  String get channelShareToChat => 'Share to Chat';

  @override
  String get channelShareCopyLink => 'Copy link';

  @override
  String get channelShareCopied => 'Link copied';

  @override
  String get channelShareMomentsDone => 'Shared to Moments';

  @override
  String get channelShareChatDone => 'Sent to chat';

  @override
  String get channelShareNoFriends => 'Add friends to share in chat';

  @override
  String get channelSharePickFriend => 'Send to…';

  @override
  String channelCommentsTitle(int count) {
    return '$count comments';
  }

  @override
  String get channelCommentsEmpty => 'No comments yet';

  @override
  String get channelCommentHint => 'Say something…';

  @override
  String get chatNewChat => 'New Chat';

  @override
  String get momentsUnpin => 'Unpin';

  @override
  String get momentsPinnedToast => 'Pinned to top';

  @override
  String get momentsUnpinnedToast => 'Unpinned';

  @override
  String get momentsHideTheirs => 'Don\'t see their Moments';

  @override
  String get momentsShowTheirs => 'See their Moments';

  @override
  String get momentsHideMine => 'Hide my Moments';

  @override
  String get momentsShowMine => 'Let them see my Moments';

  @override
  String get momentsPrefsSaved => 'Updated';

  @override
  String get settingsSounds => 'Sounds';

  @override
  String get soundCall => 'Call ringtone';

  @override
  String get soundMessage => 'Message tone';

  @override
  String get soundNotification => 'Notification tone';

  @override
  String get soundClassic => 'Classic';

  @override
  String get soundSoft => 'Soft';

  @override
  String get soundBright => 'Bright';

  @override
  String get friendsPickerSearch => 'Search';

  @override
  String get friendsPickerEmpty => 'No matches';

  @override
  String get messagesFilterAll => 'All';

  @override
  String get messagesFilterUnread => 'Unread';

  @override
  String get messagesFilterGroups => 'Groups';

  @override
  String get messagesFilterServices => 'Services';

  @override
  String get messagesFilterEmpty => 'No chats in this view';

  @override
  String get chatMarkRead => 'Mark as Read';

  @override
  String get messagesMarkAllRead => 'Mark all as read';

  @override
  String get messagesMarkAllReadDone => 'All chats marked as read';

  @override
  String get chatTimeYesterday => 'Yesterday';

  @override
  String get chatWeekdayMon => 'Mon';

  @override
  String get chatWeekdayTue => 'Tue';

  @override
  String get chatWeekdayWed => 'Wed';

  @override
  String get chatWeekdayThu => 'Thu';

  @override
  String get chatWeekdayFri => 'Fri';

  @override
  String get chatWeekdaySat => 'Sat';

  @override
  String get chatWeekdaySun => 'Sun';

  @override
  String get messagesSwipeRead => 'Read';

  @override
  String get messagesSwipeUnread => 'Unread';

  @override
  String get messagesSwipePin => 'Pin';

  @override
  String get messagesSwipeUnpin => 'Unpin';

  @override
  String get messagesSwipeMute => 'Mute';

  @override
  String get messagesSwipeUnmute => 'Unmute';

  @override
  String get messagesSearchHint => 'Search';

  @override
  String get messagesSearchChats => 'Chats';

  @override
  String get messagesSearchHistory => 'Chat history';

  @override
  String messagesSearchRelated(int n) {
    return '$n related messages';
  }

  @override
  String get messagesSearchEmpty => 'No matches';

  @override
  String get chatSearchHint => 'Search this chat';

  @override
  String get chatSearch => 'Search';

  @override
  String get chatSearchEmpty => 'No matching messages';

  @override
  String chatSearchPosition(int current, int total) {
    return '$current/$total';
  }

  @override
  String get chatSearchOlder => 'Previous';

  @override
  String get chatSearchNewer => 'Next';

  @override
  String get chatSearchPhotos => 'Photos';

  @override
  String get chatSearchVideos => 'Videos';

  @override
  String get chatSearchFiles => 'Files';

  @override
  String get chatSearchLinks => 'Links';

  @override
  String get chatSearchAll => 'All';

  @override
  String get chatFindInChat => 'Find in chat';

  @override
  String get chatUnreadNotInView =>
      'The first unread message isn’t in the loaded history';

  @override
  String get chatCopy => 'Copy';

  @override
  String get chatQuote => 'Quote';

  @override
  String get chatDeleteForMe => 'Delete for me';

  @override
  String get chatDeleteForMeConfirm =>
      'Delete this message on this device only?';

  @override
  String get chatCopied => 'Copied';

  @override
  String get chatNothingToCopy => 'Nothing to copy';

  @override
  String get chatDeletedForMe => 'Deleted for you';

  @override
  String get chatMessageActions => 'Message actions';

  @override
  String get friendsContactsTitle => 'Contacts';

  @override
  String get friendsGroupChats => 'Group Chats';

  @override
  String get friendsNewGroup => 'New group';

  @override
  String get friendsStarred => 'Starred';

  @override
  String get directoryTitle => 'Company directory';

  @override
  String get directoryHint =>
      'Colleagues you are allowed to see. Phone numbers stay with SuperAdmin.';

  @override
  String get directoryEmpty => 'No colleagues in your view yet.';

  @override
  String get directorySearch => 'Search colleagues';

  @override
  String get directoryUnassigned => 'No department';

  @override
  String get directoryMessage => 'Message';

  @override
  String get directoryLoadFailed => 'Could not load the directory';

  @override
  String get approvalsTitle => 'Approvals';

  @override
  String get approvalsHint => 'Send a request. The approvers answer in order.';

  @override
  String get approvalsEmpty => 'No requests yet.';

  @override
  String get approvalsNew => 'New request';

  @override
  String get approvalsTemplate => 'Template';

  @override
  String get approvalsTitleField => 'Title';

  @override
  String get approvalsDetails => 'Details';

  @override
  String get approvalsSend => 'Send';

  @override
  String get approvalsApprove => 'Approve';

  @override
  String get approvalsReject => 'Reject';

  @override
  String get approvalsCancel => 'Cancel request';

  @override
  String get approvalsWaiting => 'Waiting for you';

  @override
  String get approvalsMine => 'My requests';

  @override
  String get approvalsLoadFailed => 'Could not load approvals';

  @override
  String get approvalPending => 'Pending';

  @override
  String get approvalApproved => 'Approved';

  @override
  String get approvalRejected => 'Rejected';

  @override
  String get approvalCancelled => 'Cancelled';

  @override
  String get attendanceTitle => 'Clock-in';

  @override
  String get attendanceHint =>
      'Clock in when you start, and clock out when you finish. Hours follow the company clock.';

  @override
  String get attendanceClockIn => 'Clock in';

  @override
  String get attendanceClockOut => 'Clock out';

  @override
  String get attendanceMissing => 'Not clocked';

  @override
  String get attendanceOnTime => 'On time';

  @override
  String get attendanceLate => 'Late';

  @override
  String get attendanceEarly => 'Left early';

  @override
  String get attendanceOffDay => 'Off schedule';

  @override
  String get attendanceRecent => 'Recent days';

  @override
  String get attendanceNote => 'Note (optional)';

  @override
  String get attendanceLoadFailed => 'Could not load clock-in';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsHint =>
      'Write what you finished and what is next. You can update the current day, week, or month.';

  @override
  String get reportsDaily => 'Daily';

  @override
  String get reportsWeekly => 'Weekly';

  @override
  String get reportsMonthly => 'Monthly';

  @override
  String get reportsDone => 'Done';

  @override
  String get reportsPlan => 'Next';

  @override
  String get reportsBlockers => 'Blockers';

  @override
  String get reportsSend => 'Send';

  @override
  String get reportsMissing => 'Not sent';

  @override
  String get reportsSent => 'Sent';

  @override
  String get reportsInbox => 'Received';

  @override
  String get reportsMine => 'My reports';

  @override
  String get reportsNone => 'None yet.';

  @override
  String get reportsLoadFailed => 'Could not load reports';

  @override
  String get formsTitle => 'Forms';

  @override
  String get formsHint =>
      'Fill a company form. The desk can read what you send.';

  @override
  String get formsSend => 'Send';

  @override
  String get formsFillRequired => 'Fill every required field';

  @override
  String get formsNone => 'No forms yet.';

  @override
  String get formsMine => 'My forms';

  @override
  String get formsLoadFailed => 'Could not load forms';

  @override
  String get collectionTitle => 'Collection forms';

  @override
  String get collectionHint =>
      'Fill the form that was sent to you. You can update it while it is open.';

  @override
  String get collectionSend => 'Send';

  @override
  String get collectionFillRequired => 'Fill every required field';

  @override
  String get collectionNone => 'No collection was sent to you.';

  @override
  String get collectionOpen => 'Open';

  @override
  String get collectionClosed => 'Closed';

  @override
  String get collectionLoadFailed => 'Could not load collection forms';

  @override
  String get roomsTitle => 'Meeting rooms';

  @override
  String get roomsHint => 'Book a room. The same time cannot be taken twice.';

  @override
  String get roomsBook => 'Book';

  @override
  String get roomsPurpose => 'Purpose';

  @override
  String get roomsStart => 'Start';

  @override
  String get roomsEnd => 'End';

  @override
  String get roomsPick => 'Choose';

  @override
  String get roomsUpcoming => 'Upcoming';

  @override
  String get roomsNone => 'Nothing booked in this range.';

  @override
  String get roomsCancel => 'Cancel';

  @override
  String get roomsLoadFailed => 'Could not load meeting rooms';

  @override
  String get rosterTitle => 'Joining and leaving';

  @override
  String get rosterHint =>
      'Ask to leave on your last day. Confirming it does not close your login.';

  @override
  String get rosterAsk => 'Ask to leave';

  @override
  String get rosterJoined => 'Joined';

  @override
  String get rosterLastDay => 'Last day';

  @override
  String get rosterNote => 'Note';

  @override
  String get rosterActive => 'Active';

  @override
  String get rosterLeaving => 'Leaving';

  @override
  String get rosterLeft => 'Left';

  @override
  String get rosterUnrecorded => 'Not recorded';

  @override
  String get rosterMissing => 'Your join date is not on the roster yet.';

  @override
  String get rosterPending => 'Your leave request is waiting for the desk.';

  @override
  String get rosterRecorded =>
      'Your leave is recorded. Your login stays open until the staff desk closes it.';

  @override
  String get rosterLoadFailed => 'Could not load the roster';

  @override
  String get payslipsTitle => 'Payslips';

  @override
  String get payslipsHint =>
      'Open your payslip and confirm you have seen it. This record does not send money.';

  @override
  String get payslipsSeen => 'I have seen this';

  @override
  String get payslipsConfirmed => 'Seen';

  @override
  String get payslipsOpen => 'Waiting to be seen';

  @override
  String get payslipsEarning => 'Pay';

  @override
  String get payslipsDeduction => 'Deduction';

  @override
  String get payslipsNet => 'Net';

  @override
  String get payslipsNote => 'Note';

  @override
  String get payslipsNone => 'No payslips yet.';

  @override
  String get payslipsLoadFailed => 'Could not load payslips';

  @override
  String get companyContactsTitle => 'Customer contacts';

  @override
  String get companyContactsHint =>
      'These contacts belong to the company. You see the people assigned to you.';

  @override
  String get companyContactsName => 'Name';

  @override
  String get companyContactsPhone => 'Phone';

  @override
  String get companyContactsOrg => 'Organization';

  @override
  String get companyContactsNote => 'Note';

  @override
  String get companyContactsSave => 'Save';

  @override
  String get companyContactsNew => 'New contact';

  @override
  String get companyContactsActive => 'Active';

  @override
  String get companyContactsPaused => 'Paused';

  @override
  String get companyContactsSearch => 'Search';

  @override
  String get companyContactsNone => 'No contacts yet.';

  @override
  String get companyContactsLoadFailed => 'Could not load customer contacts';

  @override
  String get companyTagsTitle => 'Customer tags';

  @override
  String get companyTagsHint =>
      'Tags set by the company. The people listed are the contacts assigned to you.';

  @override
  String get companyTagsActive => 'In use';

  @override
  String get companyTagsPaused => 'Paused';

  @override
  String get companyTagsNone => 'No tags yet.';

  @override
  String get companyTagsLoadFailed => 'Could not load customer tags';

  @override
  String get companyGroupsTitle => 'Customer groups';

  @override
  String get companyGroupsHint =>
      'A named set of company contacts assigned to you. This is not a chat.';

  @override
  String get companyGroupsName => 'Group';

  @override
  String get companyGroupsNote => 'Note';

  @override
  String get companyGroupsSave => 'Save';

  @override
  String get companyGroupsNew => 'New group';

  @override
  String get companyGroupsActive => 'In use';

  @override
  String get companyGroupsPaused => 'Paused';

  @override
  String get companyGroupsNone => 'No groups yet.';

  @override
  String get companyGroupsLoadFailed => 'Could not load customer groups';

  @override
  String get companyWelcomesTitle => 'Welcome messages';

  @override
  String get companyWelcomesHint =>
      'The greeting to use with a new customer. The app shows it and does not send it.';

  @override
  String get companyWelcomesCopy => 'Copy';

  @override
  String get companyWelcomesCopied => 'Greeting copied';

  @override
  String get companyWelcomesAssigned => 'Assigned to you';

  @override
  String get companyWelcomesDefault => 'Company greeting';

  @override
  String get companyWelcomesNone => 'No greeting yet.';

  @override
  String get companyWelcomesLoadFailed => 'Could not load the greeting';

  @override
  String get quickRepliesTitle => 'Quick replies';

  @override
  String get quickRepliesHint =>
      'Copy a company reply, or save your own. The app does not send it.';

  @override
  String get quickRepliesName => 'Title';

  @override
  String get quickRepliesBody => 'Reply';

  @override
  String get quickRepliesSave => 'Save';

  @override
  String get quickRepliesNew => 'New reply';

  @override
  String get quickRepliesCopy => 'Copy';

  @override
  String get quickRepliesCopied => 'Reply copied';

  @override
  String get quickRepliesCompany => 'Company';

  @override
  String get quickRepliesMine => 'Mine';

  @override
  String get quickRepliesActive => 'In use';

  @override
  String get quickRepliesPaused => 'Paused';

  @override
  String get quickRepliesNone => 'No replies yet.';

  @override
  String get quickRepliesLoadFailed => 'Could not load quick replies';

  @override
  String get companyHandoverTitle => 'Customer handover';

  @override
  String get companyHandoverHint =>
      'Moves that give you company contacts, or take them from you, are listed here. The app does not message the customer.';

  @override
  String companyHandoverFrom(String name) {
    return 'From $name';
  }

  @override
  String companyHandoverTo(String name) {
    return 'To $name';
  }

  @override
  String companyHandoverCount(int count) {
    return '$count contacts';
  }

  @override
  String get companyHandoverNone => 'No handover yet.';

  @override
  String get companyHandoverLoadFailed => 'Could not load handovers';

  @override
  String get companyDriveTitle => 'Company drive';

  @override
  String get companyDriveHint =>
      'Company folders. Add a photo from this phone. Other files are added on the staff desk. A file here is not a public link.';

  @override
  String get companyDriveNone => 'No folders yet.';

  @override
  String get companyDriveEmpty => 'No files in this folder.';

  @override
  String get companyDriveOpenOnDesk => 'Open this file on the staff desk.';

  @override
  String get companyDriveLoadFailed => 'Could not load the drive';

  @override
  String get companyDocumentsTitle => 'Shared documents';

  @override
  String get companyDocumentsHint =>
      'Open a company document and update the text. The latest save is the one that stays. This is not a drive file.';

  @override
  String get companyDocumentsBody => 'Text';

  @override
  String get companyDocumentsSave => 'Save';

  @override
  String companyDocumentsSavedBy(String name) {
    return 'Last saved by $name';
  }

  @override
  String get companyDocumentsNone => 'No documents yet.';

  @override
  String get companyDocumentsLoadFailed => 'Could not load documents';

  @override
  String get companySpreadsheetsTitle => 'Shared spreadsheets';

  @override
  String get companySpreadsheetsHint =>
      'Open a spreadsheet and edit the cells. The latest save is the one that stays. A cell holds text, not a formula.';

  @override
  String get companySpreadsheetsSave => 'Save';

  @override
  String companySpreadsheetsSavedBy(String name) {
    return 'Last saved by $name';
  }

  @override
  String get companySpreadsheetsNone => 'No spreadsheets yet.';

  @override
  String get companySpreadsheetsLoadFailed => 'Could not load spreadsheets';

  @override
  String get companyCalendarTitle => 'Company calendar';

  @override
  String get companyCalendarHint =>
      'Add an event. Times are China time. The app does not send an invitation. This is not a meeting-room booking.';

  @override
  String get companyCalendarName => 'Title';

  @override
  String get companyCalendarDate => 'Date';

  @override
  String get companyCalendarStart => 'Start';

  @override
  String get companyCalendarEnd => 'End';

  @override
  String get companyCalendarNote => 'Note';

  @override
  String get companyCalendarSave => 'Save';

  @override
  String get companyCalendarNew => 'New event';

  @override
  String get companyCalendarActive => 'Shown';

  @override
  String get companyCalendarPaused => 'Hidden';

  @override
  String get companyCalendarNone => 'No events in this range.';

  @override
  String get companyCalendarLoadFailed => 'Could not load the calendar';

  @override
  String get companyMailTitle => 'Company mail';

  @override
  String get companyMailHint =>
      'Send a message to other staff. It stays inside OBIC and is not sent to an outside inbox.';

  @override
  String get companyMailSubject => 'Subject';

  @override
  String get companyMailBody => 'Message';

  @override
  String get companyMailSend => 'Send';

  @override
  String get companyMailTo => 'To';

  @override
  String get companyMailInbox => 'Inbox';

  @override
  String get companyMailOutbox => 'Sent';

  @override
  String get companyMailNone => 'No messages.';

  @override
  String get companyMailLoadFailed => 'Could not load mail';

  @override
  String get companyMeetingsTitle => 'Company meetings';

  @override
  String get companyMeetingsHint =>
      'A meeting has a time, an agenda, the staff who should attend, and notes afterward. Times are China time. The app does not start a call.';

  @override
  String get companyMeetingsName => 'Title';

  @override
  String get companyMeetingsDate => 'Date';

  @override
  String get companyMeetingsStart => 'Start';

  @override
  String get companyMeetingsEnd => 'End';

  @override
  String get companyMeetingsAgenda => 'Agenda';

  @override
  String get companyMeetingsNotes => 'Notes';

  @override
  String get companyMeetingsTo => 'Attendees';

  @override
  String get companyMeetingsSave => 'Save';

  @override
  String get companyMeetingsNew => 'New meeting';

  @override
  String get companyMeetingsActive => 'Shown';

  @override
  String get companyMeetingsPaused => 'Hidden';

  @override
  String get companyMeetingsNone => 'No meetings.';

  @override
  String get companyMeetingsLoadFailed => 'Could not load meetings';

  @override
  String get companyFileAnswersTitle => 'Document answers';

  @override
  String get companyFileAnswersHint =>
      'Ask about the company shared documents. The answer uses those documents only. When company AI is on, it writes the reply from the matching lines.';

  @override
  String get companyFileAnswersQuestion => 'Question';

  @override
  String get companyFileAnswersAsk => 'Ask';

  @override
  String get companyFileAnswersFromDocuments => 'From the documents';

  @override
  String get companyFileAnswersFromAi => 'From company AI';

  @override
  String get companyFileAnswersNone => 'No questions.';

  @override
  String get companyFileAnswersLoadFailed => 'Could not load answers';

  @override
  String get companyAppsTitle => 'Company apps';

  @override
  String get companyAppsHint =>
      'Open a company web tool. The page stays on its own site.';

  @override
  String get companyAppsNone => 'No apps.';

  @override
  String get companyAppsLoadFailed => 'Could not open the app';

  @override
  String get friendsStar => 'Star';

  @override
  String get friendsUnstar => 'Unstar';

  @override
  String get friendsMessage => 'Message';

  @override
  String get friendsRecent => 'Recent';

  @override
  String get friendsNewMark => 'New';

  @override
  String friendsContactsCount(int count) {
    return '$count contacts';
  }

  @override
  String get friendsGroupsEmpty => 'No group chats yet';

  @override
  String get friendsStarredEmpty =>
      'No starred contacts yet. Long-press a friend to star them.';

  @override
  String get contactProfileYou => 'You';

  @override
  String get contactProfileRemark => 'Remark';

  @override
  String get contactProfileSetRemark => 'Set remark';

  @override
  String get contactProfileRemarkHint => 'A name only you see on this phone';

  @override
  String contactProfileRealName(String name) {
    return 'Name: $name';
  }

  @override
  String get contactProfileVoice => 'Voice call';

  @override
  String get contactProfileVideo => 'Video call';

  @override
  String get contactProfileVoiceOrVideo => 'Voice or video call';

  @override
  String get contactProfileSaved => 'Saved';

  @override
  String get contactProfileViewPhoto => 'View photo';

  @override
  String get contactProfileCallFailed => 'Could not start the call';

  @override
  String contactMomentsNone(String name) {
    return '$name hasn\'t posted anything yet.';
  }

  @override
  String get contactMomentsNoneSelf => 'You haven\'t posted anything yet.';

  @override
  String get settingsMiniApps => 'Mini apps';

  @override
  String get settingsMiniAppsHint =>
      'Submit a mini app on the OBIC website. SuperAdmin approves it before anyone else can open it.';

  @override
  String get miniAppsWebsiteBody =>
      'Mini apps are submitted on the OBIC website, not in Settings. Sign in there with your OBIC account, then send the name, description, icon, and zip package.';

  @override
  String get miniAppsOpenWebsite => 'Open the OBIC website';

  @override
  String get miniAppWebsiteName => 'OBIC website';

  @override
  String get miniAppFormTitle => 'Submit a mini app';

  @override
  String get miniAppName => 'Name';

  @override
  String get miniAppDescription => 'Short description';

  @override
  String get miniAppIconUrl => 'Icon URL (HTTPS)';

  @override
  String get miniAppPickIcon => 'Choose icon image';

  @override
  String get miniAppIconUploading => 'Uploading icon…';

  @override
  String get miniAppStartUrl => 'Page address (HTTPS)';

  @override
  String get miniAppSubmit => 'Submit';

  @override
  String get miniAppMySubmissions => 'Your submissions';

  @override
  String get miniAppEmptyMine => 'You have not submitted a mini app yet.';

  @override
  String get miniAppSubmitted =>
      'Submitted. Status: Pending until SuperAdmin reviews it.';

  @override
  String get miniAppHttpsRequired => 'The page address must be an HTTPS URL.';

  @override
  String get miniAppPickPackage => 'Choose package';

  @override
  String get miniAppPackageRequired =>
      'Choose a .zip package with index.html at the root.';

  @override
  String get miniAppNameRequired => 'Enter a name and a short description.';

  @override
  String get miniAppServerUnavailable =>
      'Mini apps are not on this server yet. The form is ready; review starts after the API is updated.';

  @override
  String get miniAppStatusPending => 'Pending';

  @override
  String get miniAppStatusApproved => 'Approved';

  @override
  String get miniAppStatusRejected => 'Rejected';

  @override
  String get miniAppStatusDisabled => 'Disabled';

  @override
  String get miniAppReviewReason => 'Reason';

  @override
  String get miniAppEngineFail => 'Could not open this mini app';

  @override
  String get miniAppEngineReload => 'Reload';

  @override
  String get miniAppEngineRestart => 'Restart mini app';

  @override
  String get miniAppEngineRetry => 'Try again';

  @override
  String get discoverShortcuts => 'Shortcuts';

  @override
  String get discoverTrending => 'Trending';

  @override
  String get discoverOffers => 'Offers';

  @override
  String get discoverMusic => 'Music';

  @override
  String get discoverNew => 'New';

  @override
  String get discoverNewHint => 'Mini apps and what\'s new';

  @override
  String get discoverEmpty => 'Nothing to show yet';

  @override
  String get servicesRecent => 'Recent';

  @override
  String get servicesRecentEmpty => 'No recent services';

  @override
  String get servicesHeroTitle => 'China and the world';
}
