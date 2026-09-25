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
import { UploadedFile } from '../uploads/uploaded-file.entity';
import { AiAssistantMessage } from '../ai/assistant-message.entity';
import { AiAssistantThread } from '../ai/assistant-thread.entity';
import { AppSetting } from '../ai/app-setting.entity';
import { MomentFriendMute } from '../moments/moment-friend-mute.entity';
import { MomentNotifyPrefs } from '../moments/moment-notify-prefs.entity';
import { BugReport } from '../moderation/bug-report.entity';

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
    Notification,
    Friendship,
    FriendRequest,
    Offer,
    BannedWord,
    ContentReport,
    BugReport,
    UploadedFile,
    AiAssistantThread,
    AiAssistantMessage,
    AppSetting,
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
  ],
  synchronize: false,
});
