// Made by Dr Ali
// Join, ask to leave, then confirm. A recorded leave does not close the login.

export const EMPLOYMENT_STATUSES = ['active', 'leaving', 'left'] as const;
export type EmploymentStatus = (typeof EMPLOYMENT_STATUSES)[number];

export function isEmploymentStatus(value: string): value is EmploymentStatus {
  return (EMPLOYMENT_STATUSES as readonly string[]).includes(value);
}

export function nextJoin(status: EmploymentStatus | null): 'active' {
  switch (status) {
    case null:
    case 'left':
      return 'active';
    case 'active':
    case 'leaving':
      throw new Error('ALREADY_EMPLOYED');
    default: {
      const neverStatus: never = status;
      throw new Error(neverStatus);
    }
  }
}

export function nextLeaveRequest(status: EmploymentStatus): 'leaving' {
  switch (status) {
    case 'active':
      return 'leaving';
    case 'leaving':
    case 'left':
      throw new Error('LEAVE_NOT_OPEN');
    default: {
      const neverStatus: never = status;
      throw new Error(neverStatus);
    }
  }
}

export function nextConfirmedLeave(status: EmploymentStatus): 'left' {
  switch (status) {
    case 'leaving':
      return 'left';
    case 'active':
    case 'left':
      throw new Error('LEAVE_NOT_PENDING');
    default: {
      const neverStatus: never = status;
      throw new Error(neverStatus);
    }
  }
}

export function nextCancelledLeave(status: EmploymentStatus): 'active' {
  switch (status) {
    case 'leaving':
      return 'active';
    case 'active':
    case 'left':
      throw new Error('LEAVE_NOT_PENDING');
    default: {
      const neverStatus: never = status;
      throw new Error(neverStatus);
    }
  }
}

/** Inclusive YYYY-MM-DD bounds. String order matches calendar order. */
export function assertRosterDate(
  value: string,
  earliest: string,
  latest: string,
): void {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value) || value < earliest || value > latest) {
    throw new Error('ROSTER_DATE');
  }
}
