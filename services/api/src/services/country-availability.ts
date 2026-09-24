// Made by Dr Ali
// Country availability — empty list = worldwide.

export function normalizeCountryCode(code?: string | null): string | undefined {
  if (!code?.trim()) return undefined;
  return code.trim().toUpperCase();
}

/** Empty/null countries array means available in all countries. */
export function isAvailableInCountry(
  countries: string[] | null | undefined,
  country?: string | null,
): boolean {
  const c = normalizeCountryCode(country);
  if (!c) return true;
  if (!countries || countries.length === 0) return true;
  return countries.map((x) => x.toUpperCase()).includes(c);
}

export function parseCountriesInput(raw?: string | null): string[] {
  if (!raw?.trim()) return [];
  return raw
   .split(/[,;\s]+/)
    .map((s) => s.trim().toUpperCase())
    .filter((s) => /^[A-Z]{2}$/.test(s));
}
