// Made by Dr Ali
// TypeORM CLI data source — used by migration:run / migration:generate.

import { config as loadEnv } from 'dotenv';
import { resolve } from 'path';
import { DataSource } from 'typeorm';
import { RefreshSession } from '../auth/refresh-session.entity';
import { AuditLog } from '../chat/audit-log.entity';
import { ConversationParticipant } from '../chat/conversation-participant.entity';
import { Conversation } from '../chat/conversation.entity';
import { Message } from '../chat/message.entity';
import { FriendRequest } from '../friends/friend-request.entity';
import { Friendship } from '../friends/friendship.entity';
import { BannedWord } from '../moderation/banned-word.entity';
import { ContentReport } from '../moderation/content-report.entity';
import { Moment } from '../moments/moment.entity';
import { MomentComment } from '../moments/moment-comment.entity';
import { MomentLike } from '../moments/moment-like.entity';
import { Notification } from '../notifications/notification.entity';
import { PushDevice } from '../notifications/push-device.entity';
import { Offer } from '../offers/offer.entity';
import { Order } from '../orders/order.entity';
import { Service } from '../services/service.entity';
import { ServiceSub } from '../services/service-sub.entity';
import { User } from '../users/user.entity';
import { InitAuth1765068000000 } from './migrations/1765068000000-InitAuth';
import { ServicesAndOrders1765072000000 } from './migrations/1765072000000-ServicesAndOrders';
import { Phase3Social1765080000000 } from './migrations/1765080000000-Phase3Social';
import { MomentsMediaAvatars1765090000000 } from './migrations/1765090000000-MomentsMediaAvatars';
import { MomentLikesComments1765100000000 } from './migrations/1765100000000-MomentLikesComments';
import { Phase4AdminOrders1765110000000 } from './migrations/1765110000000-Phase4AdminOrders';
import { MomentCommentReplies1765120000000 } from './migrations/1765120000000-MomentCommentReplies';
import { UserStaffTitleBranch1765130000000 } from './migrations/1765130000000-UserStaffTitleBranch';
import { ChatGroups1765140000000 } from './migrations/1765140000000-ChatGroups';
import { Offers1765150000000 } from './migrations/1765150000000-Offers';
import { UserOpsAccess1765160000000 } from './migrations/1765160000000-UserOpsAccess';
import { UserOffersAccess1765170000000 } from './migrations/1765170000000-UserOffersAccess';
import { OfferAvailabilityAndOrderOfferId1765180000000 } from './migrations/1765180000000-OfferAvailabilityAndOrderOfferId';
import { OfferAttributesAndIndexes1765190000000 } from './migrations/1765190000000-OfferAttributesAndIndexes';
import { NotificationOrderKinds1765200000000 } from './migrations/1765200000000-NotificationOrderKinds';
import { ContentModeration1765300000000 } from './migrations/1765300000000-ContentModeration';
import { BannedWordsWiden1765310000000 } from './migrations/1765310000000-BannedWordsWiden';
import { OrderFormData1765320000000 } from './migrations/1765320000000-OrderFormData';
import { ServiceZhAndPhase1Categories1765330000000 } from './migrations/1765330000000-ServiceZhAndPhase1Categories';
import { SubServices1765340000000 } from './migrations/1765340000000-SubServices';
import { UserTotp1765350000000 } from './migrations/1765350000000-UserTotp';
import { MegaCatalogAndCountries1765360000000 } from './migrations/1765360000000-MegaCatalogAndCountries';
import { Phase2Crm1765370000000 } from './migrations/1765370000000-Phase2Crm';
import { UserAddresses1765380000000 } from './migrations/1765380000000-UserAddresses';
import { Phase5Ai1765390000000 } from './migrations/1765390000000-Phase5Ai';
import { UploadedFilesAndMomentSoftDelete1765400000000 } from './migrations/1765400000000-UploadedFilesAndMomentSoftDelete';
import { MomentVisibility1765410000000 } from './migrations/1765410000000-MomentVisibility';
import { Phase5AiDeepen1765420000000 } from './migrations/1765420000000-Phase5AiDeepen';
import { ProfileAndMomentNotifyPrefs1765430000000 } from './migrations/1765430000000-ProfileAndMomentNotifyPrefs';
import { UserObicId1765440000000 } from './migrations/1765440000000-UserObicId';
import { WechatParitySettings1765450000000 } from './migrations/1765450000000-WechatParitySettings';
import { UserVerification1765460000000 } from './migrations/1765460000000-UserVerification';
import { ChatAudioVideoAttachments1765470000000 } from './migrations/1765470000000-ChatAudioVideoAttachments';
import { MomentsCoverFocusAndChannels1765480000000 } from './migrations/1765480000000-MomentsCoverFocusAndChannels';
import { MomentCommentMedia1765490000000 } from './migrations/1765490000000-MomentCommentMedia';
import { MomentPrivacyAcl1765500000000 } from './migrations/1765500000000-MomentPrivacyAcl';
import { MomentCommentSoftDelete1765510000000 } from './migrations/1765510000000-MomentCommentSoftDelete';
import { ChatPinUnreadRecall1765520000000 } from './migrations/1765520000000-ChatPinUnreadRecall';
import { UserGenderWhatsUp1765530000000 } from './migrations/1765530000000-UserGenderWhatsUp';
import { PerUserChannelsAndEngagement1765540000000 } from './migrations/1765540000000-PerUserChannelsAndEngagement';
import { HandoffSummary1765550000000 } from './migrations/1765550000000-HandoffSummary';
import { FriendRequestMessage1765560000000 } from './migrations/1765560000000-FriendRequestMessage';
import { UserSocialSubjects1765570000000 } from './migrations/1765570000000-UserSocialSubjects';
import { MiniApps1765580000000 } from './migrations/1765580000000-MiniApps';
import { MiniAppPackages1765590000000 } from './migrations/1765590000000-MiniAppPackages';
import { DirectoryDepartments1765600000000 } from './migrations/1765600000000-DirectoryDepartments';
import { Approvals1765610000000 } from './migrations/1765610000000-Approvals';
import { Attendance1765620000000 } from './migrations/1765620000000-Attendance';
import { WorkReports1765630000000 } from './migrations/1765630000000-WorkReports';
import { OfficeForms1765640000000 } from './migrations/1765640000000-OfficeForms';
import { CollectionForms1765650000000 } from './migrations/1765650000000-CollectionForms';
import { MeetingRooms1765660000000 } from './migrations/1765660000000-MeetingRooms';
import { StaffRoster1765670000000 } from './migrations/1765670000000-StaffRoster';
import { Payslips1765680000000 } from './migrations/1765680000000-Payslips';
import { CompanyContacts1765690000000 } from './migrations/1765690000000-CompanyContacts';
import { CompanyTags1765700000000 } from './migrations/1765700000000-CompanyTags';
import { CompanyGroups1765710000000 } from './migrations/1765710000000-CompanyGroups';
import { CompanyWelcomes1765720000000 } from './migrations/1765720000000-CompanyWelcomes';
import { QuickReplies1765730000000 } from './migrations/1765730000000-QuickReplies';
import { CompanyHandovers1765740000000 } from './migrations/1765740000000-CompanyHandovers';
import { CompanyDrive1765750000000 } from './migrations/1765750000000-CompanyDrive';
import { CompanyDocuments1765760000000 } from './migrations/1765760000000-CompanyDocuments';
import { CompanySpreadsheets1765770000000 } from './migrations/1765770000000-CompanySpreadsheets';
import { CompanyCalendar1765780000000 } from './migrations/1765780000000-CompanyCalendar';
import { CompanyMail1765790000000 } from './migrations/1765790000000-CompanyMail';
import { CompanyMeetings1765800000000 } from './migrations/1765800000000-CompanyMeetings';
import { CompanyFileAnswers1765810000000 } from './migrations/1765810000000-CompanyFileAnswers';
import { CompanyApps1765820000000 } from './migrations/1765820000000-CompanyApps';
import { PushDevices1765830000000 } from './migrations/1765830000000-PushDevices';
import { PriceVersions1765840000000 } from './migrations/1765840000000-PriceVersions';
import { RegistrationApplications1765850000000 } from './migrations/1765850000000-RegistrationApplications';
import { DocumentExtractions1765860000000 } from './migrations/1765860000000-DocumentExtractions';
import { Vip1765870000000 } from './migrations/1765870000000-Vip';
import { ActivateVipPrices1765900000000 } from './migrations/1765900000000-ActivateVipPrices';
import { LogisticsTools1765910000000 } from './migrations/1765910000000-LogisticsTools';
import { UserHomeLayout1765920000000 } from './migrations/1765920000000-UserHomeLayout';
import { MiniAppsLayoutAndUserOffice1765930000000 } from './migrations/1765930000000-MiniAppsLayoutAndUserOffice';
import { UserHomeLayout } from '../users/user-home-layout.entity';
import { UserOfficeItem } from '../user-office/user-office-item.entity';
import { DeskMiniAppFlag } from '../mini-apps/desk-mini-app-flag.entity';
import { PriceVersion } from '../prices/price-version.entity';
import { DocumentExtraction } from '../registration/document-extraction.entity';
import { VipConsultation } from '../vip/vip-consultation.entity';
import { VipTrip } from '../vip/vip-trip.entity';
import { EligibilityRule } from '../registration/eligibility-rule.entity';
import { RegistrationApplication } from '../registration/registration-application.entity';
import { RegistrationDocument } from '../registration/registration-document.entity';
import { RegistrationEvent } from '../registration/registration-event.entity';
import {
  AttendancePunch,
  AttendanceRule,
} from '../attendance/attendance.entities';
import {
  WorkReport,
  WorkReportReviewer,
  WorkReportSetting,
} from '../reports/report.entities';
import {
  OfficeForm,
  OfficeFormField,
  OfficeFormSubmission,
} from '../office-forms/office-form.entities';
import {
  CollectionForm,
  CollectionFormField,
  CollectionFormMember,
  CollectionFormResponse,
} from '../collection-forms/collection-form.entities';
import { MeetingBooking, MeetingRoom } from '../meeting-rooms/meeting-room.entities';
import { StaffEmployment } from '../roster/roster.entity';
import { StaffPayslip } from '../payslips/payslip.entity';
import { CompanyContact } from '../company-contacts/company-contact.entity';
import { CompanyContactTag, CompanyTag } from '../company-tags/company-tag.entities';
import {
  CompanyContactGroup,
  CompanyContactGroupMember,
} from '../company-groups/company-group.entities';
import {
  CompanyWelcome,
  CompanyWelcomeAssignment,
} from '../company-welcomes/company-welcome.entities';
import { QuickReply } from '../quick-replies/quick-reply.entity';
import { CompanyContactHandover } from '../company-handovers/company-handover.entity';
import { CompanyDriveFile, CompanyDriveFolder } from '../company-drive/company-drive.entities';
import { CompanyDocument } from '../company-documents/company-document.entity';
import { CompanySpreadsheet } from '../company-spreadsheets/company-spreadsheet.entity';
import { CompanyCalendarEvent } from '../company-calendar/company-calendar.entity';
import { CompanyMailMessage, CompanyMailRecipient } from '../company-mail/company-mail.entities';
import { CompanyMeeting, CompanyMeetingAttendee } from '../company-meetings/company-meeting.entities';
import { CompanyFileAnswer } from '../company-file-answers/company-file-answer.entity';
import { CompanyApp } from '../company-apps/company-app.entity';
import { Department } from '../directory/department.entity';
import {
  ApprovalRequest,
  ApprovalRequestStep,
  ApprovalTemplate,
  ApprovalTemplateStep,
} from '../approvals/approval.entities';
import { MiniApp } from '../mini-apps/mini-app.entity';
import { MiniAppFile } from '../mini-apps/mini-app-file.entity';
import { UploadedFile } from '../uploads/uploaded-file.entity';
import { AiAssistantMessage } from '../ai/assistant-message.entity';
import { AiAssistantThread } from '../ai/assistant-thread.entity';
import { AppSetting } from '../ai/app-setting.entity';
import { MomentFriendHide } from '../moments/moment-friend-hide.entity';
import { MomentFriendMute } from '../moments/moment-friend-mute.entity';
import { MomentNotifyPrefs } from '../moments/moment-notify-prefs.entity';
import { BugReport } from '../moderation/bug-report.entity';
import { VerificationChallenge } from '../auth/verification-challenge.entity';
import { Channel } from '../channels/channel.entity';
import { ChannelFollow } from '../channels/channel-follow.entity';
import { ChannelVideo } from '../channels/channel-video.entity';
import { ChannelVideoComment } from '../channels/channel-video-comment.entity';
import { ChannelVideoLike } from '../channels/channel-video-like.entity';

// Load services/api/.env then repo-root .env (local only — never commit secrets).
loadEnv({ path: resolve(__dirname, '../../.env') });
loadEnv({ path: resolve(__dirname, '../../../../.env') });

const url = process.env.DATABASE_URL;
if (!url) {
  throw new Error('DATABASE_URL is required for TypeORM migrations');
}

export default new DataSource({
  type: 'postgres',
  url,
  ssl:
    process.env.DATABASE_SSL === 'true'
      ? { rejectUnauthorized: false }
      : undefined,
  entities: [
    User,
    UserHomeLayout,
    UserOfficeItem,
    DeskMiniAppFlag,
    RefreshSession,
    Service,
    ServiceSub,
    Order,
    Conversation,
    ConversationParticipant,
    Message,
    AuditLog,
    Moment,
    MomentLike,
    MomentComment,
    MomentNotifyPrefs,
    MomentFriendMute,
    MomentFriendHide,
    Notification,
    PushDevice,
    Friendship,
    FriendRequest,
    Offer,
    BannedWord,
    ContentReport,
    BugReport,
    VerificationChallenge,
    UploadedFile,
    AiAssistantThread,
    AiAssistantMessage,
    AppSetting,
    Channel,
    ChannelFollow,
    ChannelVideo,
    ChannelVideoLike,
    ChannelVideoComment,
    MiniApp,
    MiniAppFile,
    Department,
    ApprovalTemplate,
    ApprovalTemplateStep,
    ApprovalRequest,
    ApprovalRequestStep,
    AttendanceRule,
    AttendancePunch,
    WorkReportSetting,
    WorkReportReviewer,
    WorkReport,
    OfficeForm,
    OfficeFormField,
    OfficeFormSubmission,
    CollectionForm,
    CollectionFormField,
    CollectionFormMember,
    CollectionFormResponse,
    MeetingRoom,
    MeetingBooking,
    StaffEmployment,
    StaffPayslip,
    CompanyContact,
    CompanyTag,
    CompanyContactTag,
    CompanyContactGroup,
    CompanyContactGroupMember,
    CompanyWelcome,
    CompanyWelcomeAssignment,
    QuickReply,
    CompanyContactHandover,
    CompanyDriveFolder,
    CompanyDriveFile,
    CompanyDocument,
    CompanySpreadsheet,
    CompanyCalendarEvent,
    CompanyMailMessage,
    CompanyMailRecipient,
    CompanyMeeting,
    CompanyMeetingAttendee,
    CompanyFileAnswer,
    CompanyApp,
    PriceVersion,
    RegistrationApplication,
    RegistrationDocument,
    RegistrationEvent,
    EligibilityRule,
    DocumentExtraction,
    VipTrip,
    VipConsultation,
  ],
  migrations: [
    InitAuth1765068000000,
    ServicesAndOrders1765072000000,
    Phase3Social1765080000000,
    MomentsMediaAvatars1765090000000,
    MomentLikesComments1765100000000,
    Phase4AdminOrders1765110000000,
    MomentCommentReplies1765120000000,
    UserStaffTitleBranch1765130000000,
    ChatGroups1765140000000,
    Offers1765150000000,
    UserOpsAccess1765160000000,
    UserOffersAccess1765170000000,
    OfferAvailabilityAndOrderOfferId1765180000000,
    OfferAttributesAndIndexes1765190000000,
    NotificationOrderKinds1765200000000,
    ContentModeration1765300000000,
    BannedWordsWiden1765310000000,
    OrderFormData1765320000000,
    ServiceZhAndPhase1Categories1765330000000,
    SubServices1765340000000,
    UserTotp1765350000000,
    MegaCatalogAndCountries1765360000000,
    Phase2Crm1765370000000,
    UserAddresses1765380000000,
    Phase5Ai1765390000000,
    UploadedFilesAndMomentSoftDelete1765400000000,
    MomentVisibility1765410000000,
    Phase5AiDeepen1765420000000,
    ProfileAndMomentNotifyPrefs1765430000000,
    UserObicId1765440000000,
    WechatParitySettings1765450000000,
    UserVerification1765460000000,
    ChatAudioVideoAttachments1765470000000,
    MomentsCoverFocusAndChannels1765480000000,
    MomentCommentMedia1765490000000,
    MomentPrivacyAcl1765500000000,
    MomentCommentSoftDelete1765510000000,
    ChatPinUnreadRecall1765520000000,
    UserGenderWhatsUp1765530000000,
    PerUserChannelsAndEngagement1765540000000,
    HandoffSummary1765550000000,
    FriendRequestMessage1765560000000,
    UserSocialSubjects1765570000000,
    MiniApps1765580000000,
    MiniAppPackages1765590000000,
    DirectoryDepartments1765600000000,
    Approvals1765610000000,
    Attendance1765620000000,
    WorkReports1765630000000,
    OfficeForms1765640000000,
    CollectionForms1765650000000,
    MeetingRooms1765660000000,
    StaffRoster1765670000000,
    Payslips1765680000000,
    CompanyContacts1765690000000,
    CompanyTags1765700000000,
    CompanyGroups1765710000000,
    CompanyWelcomes1765720000000,
    QuickReplies1765730000000,
    CompanyHandovers1765740000000,
    CompanyDrive1765750000000,
    CompanyDocuments1765760000000,
    CompanySpreadsheets1765770000000,
    CompanyCalendar1765780000000,
    CompanyMail1765790000000,
    CompanyMeetings1765800000000,
    CompanyFileAnswers1765810000000,
    CompanyApps1765820000000,
    PushDevices1765830000000,
    PriceVersions1765840000000,
    RegistrationApplications1765850000000,
    DocumentExtractions1765860000000,
    Vip1765870000000,
    ActivateVipPrices1765900000000,
    LogisticsTools1765910000000,
    UserHomeLayout1765920000000,
    MiniAppsLayoutAndUserOffice1765930000000,
  ],
  synchronize: false,
});
