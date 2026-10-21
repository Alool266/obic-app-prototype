// Made by Dr Ali
// Unit tests for Form2 workflow ACL + status transitions (locked 19 Sep 2026).

import { UserRole } from '../common/enums/user-role.enum';
import { OrderStatus } from '../orders/order.entity';
import {
  FORM2_WORKFLOW_RULES,
  SECRETARY_STATUS_FORBIDDEN,
  canReassignOrders,
  canUpdateOrderStatus,
  isAllowedStatusTransition,
  isBranchManagerTitle,
  isSalesRepTitle,
  isSecretaryTitle,
  isYiwuRequestBranch,
  isYiwuSecretary,
  orderInReassignScope,
} from './form2-workflow';

describe('form2-workflow', () => {
  it('locks five management answers', () => {
    expect(FORM2_WORKFLOW_RULES).toHaveLength(5);
    expect(FORM2_WORKFLOW_RULES.map((r) => r.id)).toEqual([1, 2, 3, 4, 5]);
  });

  it('allows assignee status transitions including WaitingCustomer + close', () => {
    expect(
      isAllowedStatusTransition(OrderStatus.Assigned, OrderStatus.InProgress),
    ).toBe(true);
    expect(
      isAllowedStatusTransition(
        OrderStatus.InProgress,
        OrderStatus.WaitingCustomer,
      ),
    ).toBe(true);
    expect(
      isAllowedStatusTransition(
        OrderStatus.WaitingCustomer,
        OrderStatus.InProgress,
      ),
    ).toBe(true);
    expect(
      isAllowedStatusTransition(OrderStatus.InProgress, OrderStatus.Completed),
    ).toBe(true);
    expect(
      isAllowedStatusTransition(OrderStatus.Completed, OrderStatus.InProgress),
    ).toBe(false);
  });

  it('matches branch manager and sales-rep titles', () => {
    expect(isBranchManagerTitle('Yiwu Branch Manager')).toBe(true);
    expect(isBranchManagerTitle('مدير فرع إيوو')).toBe(true);
    expect(isSalesRepTitle('Marketing Manager — All Services')).toBe(true);
    expect(isSalesRepTitle('تسويق المنح')).toBe(true);
    expect(isSalesRepTitle('Visa Group Assistant')).toBe(false);
  });

  it('matches secretary titles and Yiwu secretary desk', () => {
    expect(isSecretaryTitle('Secretary')).toBe(true);
    expect(isSecretaryTitle('Secretary (GM)')).toBe(true);
    expect(isSecretaryTitle('سكرتاري المدير العام')).toBe(true);
    expect(isSecretaryTitle('Marketing Manager')).toBe(false);
    expect(isYiwuRequestBranch('Yiwu')).toBe(true);
    expect(isYiwuRequestBranch('Guangzhou')).toBe(false);
    expect(
      isYiwuSecretary({
        role: UserRole.Employee,
        staffTitle: 'Secretary',
        branchLabel: 'Yiwu',
        email: 'temp.yiwu.secretary@obic.local',
      }),
    ).toBe(true);
    expect(
      isYiwuSecretary({
        role: UserRole.Employee,
        staffTitle: 'Marketing Manager',
        branchLabel: 'Yiwu',
        email: 'temp.yiwu.marketing@obic.local',
      }),
    ).toBe(false);
    expect(SECRETARY_STATUS_FORBIDDEN).toMatch(/Secretary/);
  });

  it('scopes Yiwu status updates to Secretary (+ SuperAdmin escape)', () => {
    const sa = {
      role: UserRole.SuperAdmin,
      staffTitle: null,
      branchLabel: null,
    };
    const secretary = {
      role: UserRole.Employee,
      staffTitle: 'Secretary',
      branchLabel: 'Yiwu',
      email: 'temp.yiwu.secretary@obic.local',
    };
    const marketing = {
      role: UserRole.Employee,
      staffTitle: 'Marketing Manager',
      branchLabel: 'Yiwu',
      email: 'temp.yiwu.marketing@obic.local',
    };
    const yiwuOrder = { preferredBranch: 'Yiwu' };
    const gzOrder = { preferredBranch: 'Guangzhou' };

    expect(
      canUpdateOrderStatus(sa, yiwuOrder, { assignedToSelf: false }),
    ).toBe(true);
    expect(
      canUpdateOrderStatus(secretary, yiwuOrder, { assignedToSelf: false }),
    ).toBe(true);
    expect(
      canUpdateOrderStatus(marketing, yiwuOrder, { assignedToSelf: true }),
    ).toBe(false);
    expect(
      canUpdateOrderStatus(marketing, gzOrder, { assignedToSelf: true }),
    ).toBe(true);
    expect(
      canUpdateOrderStatus(marketing, gzOrder, { assignedToSelf: false }),
    ).toBe(false);
  });

  it('scopes reassignment to SuperAdmin / BM / sales-rep + branch', () => {
    const sa = {
      role: UserRole.SuperAdmin,
      staffTitle: null,
      branchLabel: null,
    };
    const bm = {
      role: UserRole.Employee,
      staffTitle: 'Guangzhou Branch Manager',
      branchLabel: 'Guangzhou',
    };
    const emp = {
      role: UserRole.Employee,
      staffTitle: 'General Employee',
      branchLabel: 'Guangzhou',
    };

    expect(canReassignOrders(sa)).toBe(true);
    expect(canReassignOrders(bm)).toBe(true);
    expect(canReassignOrders(emp)).toBe(false);

    expect(
      orderInReassignScope({ preferredBranch: 'Guangzhou' }, bm),
    ).toBe(true);
    expect(orderInReassignScope({ preferredBranch: 'Yiwu' }, bm)).toBe(false);
    expect(
      orderInReassignScope({ preferredBranch: 'Yiwu' }, sa),
    ).toBe(true);
  });
});
