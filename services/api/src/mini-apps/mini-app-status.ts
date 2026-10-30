// Made by Dr Ali
// Mini-app review states. Disabled is the SuperAdmin kill switch after approval.

import { BadRequestException } from '@nestjs/common';

export enum MiniAppStatus {
  Pending = 'pending',
  Approved = 'approved',
  Rejected = 'rejected',
  Disabled = 'disabled',
}

export type MiniAppReviewAction = 'approve' | 'reject' | 'disable';

/** Next status for a SuperAdmin action. Invalid transitions throw via the caller. */
export function assertReviewTransition(
  current: MiniAppStatus,
  action: MiniAppReviewAction,
): MiniAppStatus {
  switch (action) {
    case 'approve':
      if (current !== MiniAppStatus.Pending) {
        throw new BadRequestException('Only a pending mini app can be approved');
      }
      return MiniAppStatus.Approved;
    case 'reject':
      if (current !== MiniAppStatus.Pending) {
        throw new BadRequestException('Only a pending mini app can be rejected');
      }
      return MiniAppStatus.Rejected;
    case 'disable':
      if (current !== MiniAppStatus.Approved) {
        throw new BadRequestException('Only an approved mini app can be disabled');
      }
      return MiniAppStatus.Disabled;
    default: {
      const _exhaustive: never = action;
      return _exhaustive;
    }
  }
}
