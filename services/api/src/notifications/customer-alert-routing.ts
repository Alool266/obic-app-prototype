// Made by Dr Ali
// Who is told about a customer action. Change this map only.
// Chat messages and calls are not listed here — those stay with the people in that chat.
// Desk keys match temp.{branch}.{desk}@obic.local (see support-desk-routing).

import { supportDeskEmail } from '../chat/support-desk-routing';

export type CustomerAlertAction =
  | 'order'
  | 'offer'
  | 'handoff'
  | 'bug_report'
  | 'mini_app'
  | 'content_report';

/**
 * One desk per action. Default is the Yiwu Secretary account
 * (temp.yiwu.secretary@obic.local). Do not list every employee.
 */
export const CUSTOMER_ALERT_RECIPIENT: Record<CustomerAlertAction, string> = {
  order: 'secretary',
  offer: 'secretary',
  handoff: 'secretary',
  bug_report: 'secretary',
  mini_app: 'secretary',
  content_report: 'secretary',
};

/** Branch of the desk account named above. */
export const CUSTOMER_ALERT_BRANCH = 'Yiwu';

export function customerAlertDeskEmail(action: CustomerAlertAction): string {
  return supportDeskEmail(
    CUSTOMER_ALERT_BRANCH,
    CUSTOMER_ALERT_RECIPIENT[action],
  );
}
