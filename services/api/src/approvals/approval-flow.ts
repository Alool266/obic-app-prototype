// Made by Dr Ali
// Sequential approval: one person at a time, then the next. A rejection stops the request.

export const APPROVAL_STEP_STATUSES = [
  'waiting',
  'pending',
  'approved',
  'rejected',
] as const;

export type ApprovalStepStatus = (typeof APPROVAL_STEP_STATUSES)[number];

export const APPROVAL_REQUEST_STATUSES = [
  'pending',
  'approved',
  'rejected',
  'cancelled',
] as const;

export type ApprovalRequestStatus = (typeof APPROVAL_REQUEST_STATUSES)[number];

export type FlowStep = {
  status: ApprovalStepStatus;
  approverUserId: string;
};

export function startApprovalSteps(approverUserIds: string[]): FlowStep[] {
  return approverUserIds.map((approverUserId, index) => ({
    approverUserId,
    status: index === 0 ? 'pending' : 'waiting',
  }));
}

export function decideApprovalStep(
  steps: FlowStep[],
  index: number,
  decision: 'approved' | 'rejected',
): { steps: FlowStep[]; requestStatus: ApprovalRequestStatus } {
  const current = steps[index];
  if (!current || current.status !== 'pending') {
    throw new Error('APPROVAL_STEP_NOT_PENDING');
  }
  const next = steps.map((step) => ({ ...step }));
  if (decision === 'rejected') {
    next[index] = { ...next[index], status: 'rejected' };
    return { steps: next, requestStatus: 'rejected' };
  }
  next[index] = { ...next[index], status: 'approved' };
  const following = next.findIndex((step) => step.status === 'waiting');
  if (following === -1) {
    return { steps: next, requestStatus: 'approved' };
  }
  next[following] = { ...next[following], status: 'pending' };
  return { steps: next, requestStatus: 'pending' };
}

export function canViewApproval(input: {
  viewerId: string;
  viewerRole: 'Employee' | 'SuperAdmin';
  requesterId: string;
  approverUserIds: string[];
}): boolean {
  if (input.viewerRole === 'SuperAdmin') return true;
  if (input.viewerId === input.requesterId) return true;
  return input.approverUserIds.includes(input.viewerId);
}

/** Index of the step this person may decide, or null. */
export function decidableStepIndex(input: {
  viewerId: string;
  viewerRole: 'Employee' | 'SuperAdmin';
  requestStatus: ApprovalRequestStatus;
  steps: FlowStep[];
}): number | null {
  if (input.requestStatus !== 'pending') return null;
  const index = input.steps.findIndex((step) => step.status === 'pending');
  if (index < 0) return null;
  if (input.viewerRole === 'SuperAdmin') return index;
  if (input.steps[index].approverUserId === input.viewerId) return index;
  return null;
}
