// Made by Dr Ali
// Support / order thread titles: "{customer} — {request}".

const TITLE_MAX = 120;

/** Human-readable request topic from service slug / desk / free note. */
export function requestTopicLabel(opts: {
  serviceKey?: string | null;
  note?: string | null;
  orderRef?: string | null;
  serviceName?: string | null;
  fallback?: string;
}): string {
  const note = (opts.note ?? '').trim();
  if (note) return note.slice(0, 80);

  const named = (opts.serviceName ?? '').trim();
  if (named) return named.slice(0, 80);

  const key = (opts.serviceKey ?? '').trim().toLowerCase();
  const map: Record<string, string> = {
    visa: 'Visa inquiry',
    visas: 'Visa inquiry',
    government: 'Visa / government',
    travel: 'Travel inquiry',
    tourism: 'Travel inquiry',
    transport: 'Travel / transport',
    hotels: 'Hotels inquiry',
    flights: 'Flights inquiry',
    vip: 'VIP inquiry',
    business: 'Business inquiry',
    company: 'Business inquiry',
    property: 'Property inquiry',
    education: 'Education inquiry',
    scholarships: 'Scholarships inquiry',
    scholarship: 'Scholarships inquiry',
    logistics: 'Logistics inquiry',
    healthcare: 'Healthcare inquiry',
    food: 'Food inquiry',
    shopping: 'Shopping inquiry',
    legal: 'Legal inquiry',
    bank: 'Banking inquiry',
    transfer: 'Transfer inquiry',
    consultations: 'Consultation',
    translation: 'Translation inquiry',
    insurance: 'Insurance inquiry',
    secretary: 'General support',
    marketing: 'Marketing inquiry',
  };
  if (key && map[key]) return map[key];
  if (key) {
    return key.charAt(0).toUpperCase() + key.slice(1).replace(/[-_]/g, ' ');
  }

  const ref = (opts.orderRef ?? '').trim();
  if (ref) return `Case ${ref.slice(0, 40)}`;

  return (opts.fallback ?? 'Support request').slice(0, 80);
}

/** "{customerDisplayName} — {request}" clipped to DB title length. */
export function formatHandoffTitle(
  customerName: string | null | undefined,
  requestLabel: string | null | undefined,
): string {
  const name = (customerName ?? '').trim() || 'Customer';
  const topic = (requestLabel ?? '').trim() || 'Support request';
  const full = `${name} — ${topic}`;
  if (full.length <= TITLE_MAX) return full;
  const budget = TITLE_MAX - name.length - 3; // " — "
  if (budget < 12) return full.slice(0, TITLE_MAX);
  return `${name} — ${topic.slice(0, budget)}`;
}
