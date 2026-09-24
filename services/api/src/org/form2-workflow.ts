// Made by Dr Ali — Form2 workflow rules locked 19 Sep 2026 (management FINAL).
// Shared ACL helpers for Admin order status / reassign / close. Mirror: admin-web lib/org.ts + Flutter obic_org.dart.

import { OrderStatus } from '../orders/order.entity';
import { UserRole } from '../common/enums/user-role.enum';

/** Management answers date — do not reopen without a new boss decision. */
export const FORM2_WORKFLOW_LOCKED_AT = '2026-09-19';

export type Form2WorkflowRule = {
  id: number;
  questionEn: string;
  questionAr: string;
  answerEn: string;
  answerAr: string;
};

/** Locked product rules (display + API policy source). */
export const FORM2_WORKFLOW_RULES: Form2WorkflowRule[] = [
  {
    id: 1,
    questionEn: 'Can the employee change order status alone?',
    questionAr: 'هل الموظف يغيّر حالة الطلب بنفسه؟',
    answerEn: 'Yes — when assigned to that order.',
    answerAr: 'نعم — إذا كان معيّناً على ذلك الطلب.',
  },
  {
    id: 2,
    questionEn: 'When do we set Waiting for customer?',
    questionAr: 'متى نضع «بانتظار العميل»؟',
    answerEn:
      'When staff needs a reply from the customer (text, documents, or confirmation).',
    answerAr:
      'عندما يحتاج الموظف رداً من العميل (نص / مستندات / تأكيد).',
  },
  {
    id: 3,
    questionEn: 'Is the order closed from the app only?',
    questionAr: 'هل يُغلق الطلب من التطبيق فقط؟',
    answerEn: 'No — close from mobile app and Admin web (both).',
    answerAr: 'لا — الإغلاق من تطبيق الموبايل ولوحة الإدارة (كلاهما).',
  },
  {
    id: 4,
    questionEn: 'Who reassigns when staff is off-duty?',
    questionAr: 'من يحوّل الطلب إذا كان الموظف خارج الدوام؟',
    answerEn:
      'Client’s sales rep or branch manager (same branch scope).',
    answerAr:
      'مندوب مبيعات العميل أو مدير الفرع (ضمن نطاق الفرع).',
  },
  {
    id: 5,
    questionEn: 'Can new staff be added from Admin?',
    questionAr: 'هل يمكن إضافة موظفين جدد من لوحة الإدارة؟',
    answerEn:
      'Yes — SuperAdmin adds staff from Admin. Production mobiles/emails are entered later via that UI.',
    answerAr:
      'نعم — المشرف الأعلى يضيف الموظفين من Admin. الجوالات والبريد الحقيقيان يُدخلان لاحقاً من نفس الواجهة.',
  },
];

/** Terminal “close” statuses — allowed from mobile Admin + Admin web (same API). */
export const ORDER_CLOSE_STATUSES: ReadonlySet<OrderStatus> = new Set([
  OrderStatus.Completed,
  OrderStatus.Cancelled,
]);

/**
 * Allowed status transitions for assigned Employee (and SuperAdmin).
 * WaitingCustomer = staff needs customer reply (text / docs / confirmation).
 */
export const ORDER_STATUS_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  [OrderStatus.Submitted]: [OrderStatus.Assigned, OrderStatus.Cancelled],
  [OrderStatus.Assigned]: [
    OrderStatus.InProgress,
    OrderStatus.WaitingCustomer,
    OrderStatus.Completed,
    OrderStatus.Cancelled,
  ],
  [OrderStatus.InProgress]: [
    OrderStatus.WaitingCustomer,
    OrderStatus.Completed,
    OrderStatus.Cancelled,
    OrderStatus.Assigned,
  ],
  [OrderStatus.WaitingCustomer]: [
    OrderStatus.InProgress,
    OrderStatus.Completed,
    OrderStatus.Cancelled,
  ],
  [OrderStatus.Completed]: [],
  [OrderStatus.Cancelled]: [],
};

export function isAllowedStatusTransition(
  from: OrderStatus,
  to: OrderStatus,
): boolean {
  if (from === to) return true;
  return (ORDER_STATUS_TRANSITIONS[from] ?? []).includes(to);
}

/** Branch manager desk titles (Form2 + Arabic). */
export function isBranchManagerTitle(
  staffTitle: string | null | undefined,
): boolean {
  const raw = (staffTitle ?? '').trim();
  if (!raw) return false;
  const t = raw.toLowerCase();
  if (t.includes('branch manager')) return true;
  if (t.includes('general manager') || t.includes('owner')) return true;
  if (/مدير\s*فرع/.test(raw)) return true;
  if (/مدير\s*عام/.test(raw) || /صاحب\s*الشركة/.test(raw)) return true;
  return false;
}

/**
 * Sales-rep / marketing desk titles — Form2 “client’s sales rep”
 * for off-duty reassignment.
 */
export function isSalesRepTitle(
  staffTitle: string | null | undefined,
): boolean {
  const raw = (staffTitle ?? '').trim();
  if (!raw) return false;
  const t = raw.toLowerCase();
  if (t.includes('marketing') || t.includes('marketer')) return true;
  if (raw.includes('تسويق')) return true;
  return false;
}

export type StaffAclUser = {
  role: UserRole;
  staffTitle: string | null;
  branchLabel: string | null;
};

/** Off-duty reassignment ACL (rule 4). SuperAdmin always. */
export function canReassignOrders(user: StaffAclUser): boolean {
  if (user.role === UserRole.SuperAdmin) return true;
  if (user.role !== UserRole.Employee) return false;
  return (
    isBranchManagerTitle(user.staffTitle) || isSalesRepTitle(user.staffTitle)
  );
}

/**
 * Branch-scoped reassignment: order preferredBranch matches staff branchLabel.
 * SuperAdmin: any order.
 */
export function orderInReassignScope(
  order: { preferredBranch: string | null },
  staff: StaffAclUser,
): boolean {
  if (staff.role === UserRole.SuperAdmin) return true;
  if (!canReassignOrders(staff)) return false;
  const branch = (staff.branchLabel ?? '').trim();
  if (!branch) return false;
  const preferred = (order.preferredBranch ?? '').trim();
  return preferred.length > 0 && preferred === branch;
}

/** Customer-facing copy when status → WaitingCustomer. */
export function waitingCustomerNotifyBody(): string {
  return 'Staff is waiting for your reply on this order (text, documents, or confirmation)';
}
