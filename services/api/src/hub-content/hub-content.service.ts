// Made by Dr Ali
// Hub CMS seed + in-memory publish toggles (staff desk).

import { Injectable } from '@nestjs/common';
import {
  HUB_CATEGORY_COPY,
  HUB_DEALS,
  HUB_GUIDES,
  HUB_PLACES,
  HubDeal,
  HubGuide,
  HubKey,
  HubPlace,
} from './hub-content.seed';

@Injectable()
export class HubContentService {
  private guides = HUB_GUIDES.map((g) => ({ ...g }));
  private places = HUB_PLACES.map((p) => ({ ...p }));
  private deals = HUB_DEALS.map((d) => ({ ...d }));

  private matchCity(city: string | undefined, rowCity?: string) {
    if (!city?.trim()) return true;
    if (!rowCity) return true;
    return rowCity.toLowerCase().includes(city.trim().toLowerCase());
  }

  bundle(hub?: string, city?: string) {
    const h = (hub || '').trim().toLowerCase() as HubKey | '';
    const guides = this.guides.filter(
      (g) =>
        g.published &&
        (!h || g.hub === h) &&
        this.matchCity(city, g.city),
    );
    const places = this.places.filter(
      (p) =>
        p.published &&
        (!h || p.hub === h) &&
        this.matchCity(city, p.city),
    );
    const deals = this.deals.filter(
      (d) => d.published && (!h || d.hub === h),
    );
    const categories = HUB_CATEGORY_COPY.filter((c) => !h || c.hub === h);
    return {
      guides,
      places,
      deals,
      categories,
      seedNote: 'Yiwu + major cities · staff can toggle publish in Admin',
    };
  }

  adminList() {
    return {
      guides: this.guides,
      places: this.places,
      deals: this.deals,
      categories: HUB_CATEGORY_COPY,
    };
  }

  setPublished(kind: 'guides' | 'places' | 'deals', id: string, published: boolean) {
    const list =
      kind === 'guides'
        ? this.guides
        : kind === 'places'
          ? this.places
          : this.deals;
    const row = list.find((r) => r.id === id) as
      | HubGuide
      | HubPlace
      | HubDeal
      | undefined;
    if (!row) return { ok: false as const, message: 'not_found' };
    row.published = published;
    return { ok: true as const, id, published };
  }

  upsertGuide(body: Partial<HubGuide> & { id: string }) {
    const i = this.guides.findIndex((g) => g.id === body.id);
    const next: HubGuide = {
      id: body.id,
      hub: (body.hub as HubKey) || 'china',
      categoryId: body.categoryId,
      city: body.city,
      titleAr: body.titleAr || '',
      titleEn: body.titleEn || '',
      titleZh: body.titleZh || body.titleEn || '',
      summaryAr: body.summaryAr || '',
      summaryEn: body.summaryEn || '',
      summaryZh: body.summaryZh || body.summaryEn || '',
      bodyAr: body.bodyAr || '',
      bodyEn: body.bodyEn || '',
      bodyZh: body.bodyZh || body.bodyEn || '',
      imageUrl: body.imageUrl,
      ctaLabelAr: body.ctaLabelAr,
      ctaLabelEn: body.ctaLabelEn,
      published: body.published ?? true,
    };
    if (i >= 0) this.guides[i] = next;
    else this.guides.push(next);
    return next;
  }
}
