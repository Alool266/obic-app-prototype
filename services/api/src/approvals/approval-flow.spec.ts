// Made by Dr Ali

import {
  canViewApproval,
  decidableStepIndex,
  decideApprovalStep,
  startApprovalSteps,
} from './approval-flow';

describe('approval flow', () => {
  it('starts with the first approver and holds the rest', () => {
    expect(startApprovalSteps(['a', 'b'])).toEqual([
      { approverUserId: 'a', status: 'pending' },
      { approverUserId: 'b', status: 'waiting' },
    ]);
  });

  it('moves to the next approver, then finishes', () => {
    const started = startApprovalSteps(['a', 'b']);
    const mid = decideApprovalStep(started, 0, 'approved');
    expect(mid.requestStatus).toBe('pending');
    expect(mid.steps.map((step) => step.status)).toEqual([
      'approved',
      'pending',
    ]);
    const done = decideApprovalStep(mid.steps, 1, 'approved');
    expect(done.requestStatus).toBe('approved');
  });

  it('stops the request when an approver rejects', () => {
    const started = startApprovalSteps(['a', 'b']);
    const rejected = decideApprovalStep(started, 0, 'rejected');
    expect(rejected.requestStatus).toBe('rejected');
    expect(rejected.steps[1].status).toBe('waiting');
  });

  it('refuses a decision on a step that is not current', () => {
    const started = startApprovalSteps(['a', 'b']);
    expect(() => decideApprovalStep(started, 1, 'approved')).toThrow(
      'APPROVAL_STEP_NOT_PENDING',
    );
  });

  it('shows a request to the requester, the approvers, and SuperAdmin', () => {
    const request = {
      requesterId: 'req',
      approverUserIds: ['a', 'b'],
    };
    expect(
      canViewApproval({
        viewerId: 'req',
        viewerRole: 'Employee',
        ...request,
      }),
    ).toBe(true);
    expect(
      canViewApproval({
        viewerId: 'b',
        viewerRole: 'Employee',
        ...request,
      }),
    ).toBe(true);
    expect(
      canViewApproval({
        viewerId: 'other',
        viewerRole: 'Employee',
        ...request,
      }),
    ).toBe(false);
    expect(
      canViewApproval({
        viewerId: 'sa',
        viewerRole: 'SuperAdmin',
        ...request,
      }),
    ).toBe(true);
  });

  it('lets only the current approver, or SuperAdmin, decide', () => {
    const steps = startApprovalSteps(['a', 'b']);
    expect(
      decidableStepIndex({
        viewerId: 'a',
        viewerRole: 'Employee',
        requestStatus: 'pending',
        steps,
      }),
    ).toBe(0);
    expect(
      decidableStepIndex({
        viewerId: 'b',
        viewerRole: 'Employee',
        requestStatus: 'pending',
        steps,
      }),
    ).toBe(null);
    expect(
      decidableStepIndex({
        viewerId: 'sa',
        viewerRole: 'SuperAdmin',
        requestStatus: 'pending',
        steps,
      }),
    ).toBe(0);
    expect(
      decidableStepIndex({
        viewerId: 'a',
        viewerRole: 'Employee',
        requestStatus: 'approved',
        steps,
      }),
    ).toBe(null);
  });
});
