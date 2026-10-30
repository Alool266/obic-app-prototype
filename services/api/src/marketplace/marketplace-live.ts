// Made by Dr Ali
// Free live place data via Nominatim + Overpass (OpenStreetMap) — no API key.
// Prices are estimates for browse UX; real booking stays OBIC order pipeline.

type OsmTags = Record<string, string | undefined>;

type OsmElement = {
  type: string;
  id: number;
  lat?: number;
  lon?: number;
  center?: { lat: number; lon: number };
  tags?: OsmTags;
};

const CITY_COORDS: Record<string, { lat: number; lon: number; name: string }> = {
  yiwu: { lat: 29.3069, lon: 120.0768, name: 'Yiwu' },
  hangzhou: { lat: 30.2741, lon: 120.1551, name: 'Hangzhou' },
  shanghai: { lat: 31.2304, lon: 121.4737, name: 'Shanghai' },
  beijing: { lat: 39.9042, lon: 116.4074, name: 'Beijing' },
  guangzhou: { lat: 23.1291, lon: 113.2644, name: 'Guangzhou' },
  shenzhen: { lat: 22.5431, lon: 114.0579, name: 'Shenzhen' },
  dubai: { lat: 25.2048, lon: 55.2708, name: 'Dubai' },
  riyadh: { lat: 24.7136, lon: 46.6753, name: 'Riyadh' },
  jeddah: { lat: 21.4858, lon: 39.1925, name: 'Jeddah' },
  cairo: { lat: 30.0444, lon: 31.2357, name: 'Cairo' },
};

function cityKey(raw?: string): string {
  return (raw ?? 'yiwu').trim().toLowerCase();
}

async function geocode(
  city: string,
): Promise<{ lat: number; lon: number; name: string } | null> {
  const key = cityKey(city);
  if (CITY_COORDS[key]) return CITY_COORDS[key];
  // Fuzzy known cities
  for (const [k, v] of Object.entries(CITY_COORDS)) {
    if (key.includes(k) || k.includes(key)) return v;
  }
  try {
    const url = new URL('https://nominatim.openstreetmap.org/search');
    url.searchParams.set('q', city);
    url.searchParams.set('format', 'json');
    url.searchParams.set('limit', '1');
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'OBIC-Marketplace/1.0 (support@obicgp.com)',
        Accept: 'application/json',
      },
      signal: AbortSignal.timeout(6_000),
    });
    if (!res.ok) return CITY_COORDS.yiwu;
    const data = (await res.json()) as Array<{
      lat: string;
      lon: string;
      display_name?: string;
    }>;
    if (!data.length) return CITY_COORDS.yiwu;
    return {
      lat: Number(data[0].lat),
      lon: Number(data[0].lon),
      name: city,
    };
  } catch {
    return CITY_COORDS.yiwu;
  }
}

const OVERPASS_ENDPOINTS = [
  'https://overpass.kumi.systems/api/interpreter',
  'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  'https://overpass-api.de/api/interpreter',
];

/** Soft ceiling so browse never waits on every mirror × long timeout. */
const OVERPASS_PER_TRY_MS = 2_800;

async function overpass(query: string): Promise<OsmElement[]> {
  const body = `data=${encodeURIComponent(query)}`;
  // Race the first two mirrors; fall back to the third only if both empty/fail.
  const tryOne = async (endpoint: string): Promise<OsmElement[]> => {
    try {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'OBIC-Marketplace/1.0 (support@obicgp.com)',
        },
        body,
        signal: AbortSignal.timeout(OVERPASS_PER_TRY_MS),
      });
      if (!res.ok) return [];
      const data = (await res.json()) as { elements?: OsmElement[] };
      return data.elements ?? [];
    } catch {
      // China ECS often blocks EU Overpass hosts — try next.
      return [];
    }
  };

  const firstWave = await Promise.all(
    OVERPASS_ENDPOINTS.slice(0, 2).map((ep) => tryOne(ep)),
  );
  for (const els of firstWave) {
    if (els.length > 0) return els;
  }
  return tryOne(OVERPASS_ENDPOINTS[2]!);
}

function nameOf(tags: OsmTags | undefined, fallback: string): {
  ar: string;
  en: string;
} {
  const en =
    tags?.name?.trim() ||
    tags?.['name:en']?.trim() ||
    tags?.brand?.trim() ||
    fallback;
  const ar = tags?.['name:ar']?.trim() || en;
  return { ar, en };
}

function distKm(
  a: { lat: number; lon: number },
  b: { lat: number; lon: number },
): number {
  const R = 6371;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLon = ((b.lon - a.lon) * Math.PI) / 180;
  const la1 = (a.lat * Math.PI) / 180;
  const la2 = (b.lat * Math.PI) / 180;
  const x =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(la1) * Math.cos(la2) * Math.sin(dLon / 2) ** 2;
  return Math.round(R * 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1 - x)) * 10) / 10;
}

function coords(el: OsmElement): { lat: number; lon: number } | null {
  if (typeof el.lat === 'number' && typeof el.lon === 'number') {
    return { lat: el.lat, lon: el.lon };
  }
  if (el.center) return el.center;
  return null;
}

/** Live hotels from OSM around a city (browse + request via OBIC). */
export async function liveHotels(city?: string) {
  const geo = await geocode(city || 'Yiwu');
  if (!geo) return [];
  const q = `
[out:json][timeout:6];
(
  node["tourism"="hotel"](around:8000,${geo.lat},${geo.lon});
  way["tourism"="hotel"](around:8000,${geo.lat},${geo.lon});
  node["tourism"="guest_house"](around:8000,${geo.lat},${geo.lon});
);
out center 24;
`;
  const els = await overpass(q);
  const out = [];
  let i = 0;
  for (const el of els) {
    const c = coords(el);
    if (!c) continue;
    const n = nameOf(el.tags, `Hotel ${++i}`);
    const stars = Number(el.tags?.stars || 0) || 3;
    const price =
      180 + Math.round(distKm(geo, c) * 40) + stars * 60;
    out.push({
      id: `osm-h-${el.type}${el.id}`,
      nameAr: n.ar,
      nameEn: n.en,
      photo: '/uploads/marketplace/hotel.jpg',
      city: geo.name,
      rating: Math.min(4.9, 3.8 + stars * 0.2),
      reviewCount: 40 + (el.id % 900),
      pricePerNightYuan: price,
      stars: Math.min(5, Math.max(2, stars)),
      tags: ['OSM', 'اطلب عبر أوبك'],
      distanceKm: distKm(geo, c),
      source: 'openstreetmap',
    });
    if (out.length >= 18) break;
  }
  return out;
}

/** Live restaurants / cafes for يومي food browse. */
export async function liveFoodMerchants(city?: string) {
  const geo = await geocode(city || 'Yiwu');
  if (!geo) return [];
  const q = `
[out:json][timeout:6];
(
  node["amenity"="restaurant"](around:5000,${geo.lat},${geo.lon});
  node["amenity"="cafe"](around:5000,${geo.lat},${geo.lon});
  node["amenity"="fast_food"](around:5000,${geo.lat},${geo.lon});
);
out body 30;
`;
  const els = await overpass(q);
  const out = [];
  let i = 0;
  for (const el of els) {
    const c = coords(el);
    if (!c || !el.tags?.name) continue;
    const n = nameOf(el.tags, `Place ${++i}`);
    const d = distKm(geo, c);
    const cuisine = el.tags.cuisine?.split(';')[0]?.trim();
    out.push({
      id: `osm-f-${el.id}`,
      nameAr: n.ar,
      nameEn: n.en,
      photo:
        el.tags.amenity === 'cafe'
          ? '/uploads/marketplace/cafe.jpg'
          : '/uploads/marketplace/food.jpg',
      rating: 4.2 + ((el.id % 7) / 10),
      distanceKm: d,
      etaMin: Math.max(18, Math.round(d * 12 + 15)),
      feeYuan: d < 1.5 ? 4 : 8,
      tags: [cuisine || el.tags.amenity || 'food', 'OSM'].filter(Boolean),
      category: 'food',
      minOrderYuan: 25,
      openNow: true,
      source: 'openstreetmap',
    });
    if (out.length >= 20) break;
  }
  return out;
}

/** Live attractions / tourism spots. */
export async function liveAttractions(city?: string) {
  const geo = await geocode(city || 'Hangzhou');
  if (!geo) return [];
  const q = `
[out:json][timeout:6];
(
  node["tourism"="attraction"](around:10000,${geo.lat},${geo.lon});
  node["tourism"="museum"](around:10000,${geo.lat},${geo.lon});
  node["tourism"="viewpoint"](around:10000,${geo.lat},${geo.lon});
);
out body 20;
`;
  const els = await overpass(q);
  const out = [];
  let i = 0;
  for (const el of els) {
    if (!el.tags?.name) continue;
    const n = nameOf(el.tags, `Spot ${++i}`);
    out.push({
      id: `osm-a-${el.id}`,
      nameAr: n.ar,
      nameEn: n.en,
      photo: '/uploads/marketplace/landmark.jpg',
      city: geo.name,
      rating: 4.3 + ((el.id % 6) / 10),
      priceYuan: el.tags.fee === 'yes' ? 80 : 0,
      openHours: el.tags.opening_hours || '—',
      source: 'openstreetmap',
    });
    if (out.length >= 16) break;
  }
  return out;
}
