// Made by Dr Ali
// Route service requests to branch desk employees by service slug / mega category.
// Desk keys align with temp.{branch}.{desk}@obic.local seed accounts.
// Service owners (Cathy, Sally, Salima…) land after Form2 mobiles/emails arrive.

/** Desk key suffix in temp.{branch}.{desk}@obic.local seed accounts. */
const SERVICE_DESK: Record<string, string> = {
  // Legacy single-service slugs
  hotels: 'marketing',
  flights: 'marketing',
  vip: 'marketing',
  ads: 'marketing',
  biz: 'marketing',
  expand: 'marketing',
  visa: 'secretary',
  visas: 'secretary',
  legal: 'branchmgr',
  company: 'branchmgr',
  hr: 'branchmgr',
  plan: 'branchmgr',
  bank: 'finance',
  transfer: 'finance',
  scholarship: 'scholarships',
  scholarships: 'scholarships',
  insurance: 'secretary',
  tech: 'dataentry',
  cars: 'marketing',
  delivery: 'dataentry',
  consultations: 'secretary',
  translation: 'secretary',
  tourism: 'marketing',

  // Boss mega catalog (Form 1) — 10 parents → desk by org chart
  property: 'branchmgr', // Cathy / property ops
  transport: 'marketing', // Elin / Wadi travel & flights
  travel: 'marketing',
  healthcare: 'secretary', // no dedicated desk yet
  food: 'marketing', // لا يوجد حالياً — marketing holds
  shopping: 'marketing', // purchasing / sourcing desks
  education: 'scholarships', // Max / Khadijah scholarships
  logistics: 'dataentry', // Sally shipping ops
  government: 'secretary', // Salima / Sara visas & docs
  business: 'branchmgr', // Ali / Milly / Nancy / Ana
};

export function deskKeyForServiceSlug(slug: string): string {
  return SERVICE_DESK[slug] ?? 'secretary';
}

export function branchEmailDesk(branch: string, deskKey: string): string {
  const slug = branch.trim().toLowerCase();
  return `temp.${slug}.${deskKey}@obic.local`;
}
