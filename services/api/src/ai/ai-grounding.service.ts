// Made by Dr Ali
// Full customer catalog + FAQ grounding for OBIC AI.
// Live active services when the DB is up; mega-catalog seed otherwise.
// No user data and no staff-only admin modules.

import { Injectable, Logger, Optional } from '@nestjs/common';
import { AiCatalogItem, AiCatalogParent } from '../services/ai-catalog-snapshot';
import { MEGA_CATALOG_SEED } from '../services/mega-catalog.seed';
import { ServicesService } from '../services/services.service';
import { AiLocale } from './obic-ai.constants';
import { FaqEntry, OBIC_FAQ } from './ai-grounding.faq';

type CatalogHit = {
  score: number;
  line: string;
};

const MAX_FAQ = 3;
const MAX_CATALOG = 6;
const CATALOG_TTL_MS = 60_000;

/** Customer branches only — mirrors apps/mobile lib/core/obic_org.dart. No managers. */
const CUSTOMER_BRANCHES = [
  'Yiwu | إيوو | 义乌',
  'Guangzhou | قوانغتشو | 广州',
  'Foshan | فوشان | 佛山',
  'Hangzhou | هانغتشو | 杭州',
  'Hainan | هاينان | 海南',
  'Yemen | اليمن | 也门',
  'Shanghai | شنغهاي | 上海',
];

@Injectable()
export class AiGroundingService {
  private readonly logger = new Logger(AiGroundingService.name);
  private catalogCache: { at: number; parents: AiCatalogParent[] } | null =
    null;

  constructor(@Optional() private readonly services?: ServicesService) {}

  /**
   * Grounding block from the shared mega-catalog seed (tests and DB fallback).
   * Always includes the full customer catalog, not only keyword hits.
   */
  retrieve(
    query: string,
    locale: AiLocale = 'en',
    catalog?: AiCatalogParent[],
  ): string {
    return this.compose(query, locale, catalog ?? this.seedCatalog());
  }

  /**
   * Prefer the live active catalog so newly added services are included.
   * Falls back to the mega-catalog seed when the DB is empty or unavailable.
   */
  async retrieveForMessage(
    query: string,
    locale: AiLocale = 'en',
  ): Promise<string> {
    return this.compose(query, locale, await this.resolveCatalog());
  }

  /** Exposed for tests — corpus must never include user ids / messages. */
  corpusSources(): { faqCount: number; catalogParents: number; sources: string[] } {
    return {
      faqCount: OBIC_FAQ.length,
      catalogParents: MEGA_CATALOG_SEED.length,
      sources: [
        'services/api/src/ai/ai-grounding.faq.ts',
        'services/api/src/services/mega-catalog.seed.ts',
      ],
    };
  }

  private fallbackRules(locale: AiLocale): string {
    switch (locale) {
      case 'ar':
        return 'قاعدة: إن لم يوجد سعر في السياق، قل إن التأكيد عبر الطلب أو الموظف.';
      case 'zh':
        return '规则：上下文无价格时，说明需经订单或人工确认。';
      default:
        return 'Rule: if no price is in context, say confirmation is via order or staff.';
    }
  }

  private tokenize(raw: string): string[] {
    const lower = raw.toLowerCase();
    const parts = lower
      .split(/[^\p{L}\p{N}]+/u)
      .map((t) => t.trim())
      .filter((t) => t.length >= 2);
    // Also keep short CJK single chars that appear in keywords.
    const cjk = lower.match(/[\u4e00-\u9fff]/g) ?? [];
    return [...new Set([...parts, ...cjk])];
  }

  private scoreFaq(tokens: string[], locale: AiLocale): string[] {
    const scored = OBIC_FAQ.map((entry) => ({
      entry,
      score: this.faqScore(entry, tokens),
    }))
      .filter((x) => x.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, MAX_FAQ);

    return scored.map((x) => {
      switch (locale) {
        case 'ar':
          return x.entry.ar;
        case 'zh':
          return x.entry.zh;
        default:
          return x.entry.en;
      }
    });
  }

  private faqScore(entry: FaqEntry, tokens: string[]): number {
    let score = 0;
    const hay = entry.keywords.map((k) => k.toLowerCase());
    for (const t of tokens) {
      for (const k of hay) {
        if (k === t || k.includes(t) || t.includes(k)) {
          score += k === t ? 3 : 1;
        }
      }
    }
    return score;
  }

  private compose(
    query: string,
    locale: AiLocale,
    parents: AiCatalogParent[],
  ): string {
    const parts: string[] = [
      'Grounded OBIC facts (use these; do not invent services, prices, or confirmations):',
      this.catalogIndex(parents),
    ];

    const tokens = this.tokenize(query);
    if (tokens.length > 0) {
      const faqHits = this.scoreFaq(tokens, locale);
      const catalogHits = this.scoreCatalog(tokens, locale, parents);
      if (faqHits.length > 0) {
        parts.push('FAQ:');
        for (const f of faqHits) {
          parts.push(`- ${f}`);
        }
      }
      if (catalogHits.length > 0) {
        parts.push(
          'Closest catalog matches (use these descriptions and listed prices only):',
        );
        for (const c of catalogHits) {
          parts.push(`- ${c.line}`);
        }
      }
    }

    parts.push(this.fallbackRules(locale));
    return parts.join('\n');
  }

  private seedCatalog(): AiCatalogParent[] {
    return MEGA_CATALOG_SEED.map((parent) => ({
      slug: parent.slug,
      nameAr: parent.nameAr,
      nameEn: parent.nameEn,
      nameZh: parent.nameZh,
      descAr: parent.descAr,
      descEn: parent.descEn,
      descZh: parent.descZh,
      priceAr: parent.priceAr,
      priceEn: parent.priceEn,
      priceZh: parent.priceZh,
      subs: parent.subs.map((sub) => ({
        id: sub.id,
        nameAr: sub.nameAr,
        nameEn: sub.nameEn,
        nameZh: sub.nameZh,
        descAr: sub.descAr,
        descEn: sub.descEn,
        descZh: sub.descZh,
        priceAr: sub.priceAr,
        priceEn: sub.priceEn,
        priceZh: sub.priceZh,
      })),
    }));
  }

  private async resolveCatalog(): Promise<AiCatalogParent[]> {
    const now = Date.now();
    if (
      this.catalogCache &&
      now - this.catalogCache.at < CATALOG_TTL_MS
    ) {
      return this.catalogCache.parents;
    }
    const live = await this.loadLiveCatalog();
    const parents = live.length > 0 ? live : this.seedCatalog();
    this.catalogCache = { at: now, parents };
    return parents;
  }

  private async loadLiveCatalog(): Promise<AiCatalogParent[]> {
    if (!this.services) return [];
    try {
      return await this.services.listActiveCatalogForAi();
    } catch {
      this.logger.warn('ai_catalog_live_unavailable');
      return [];
    }
  }

  private catalogIndex(parents: AiCatalogParent[]): string {
    // Names only. Descriptions and prices stay on the closest matches so a
    // short question is not waiting on the whole catalog.
    const lines = [
      'Services that exist (Arabic | English | 中文). Do not invent others.',
      'Request path: Services, category, item, order. Published hotel and flight deals are in Offers. Demande : Services → catégorie → élément → commande.',
      'Home shortcuts: VIP trip opens Travel; visa express opens Government; the open-bank banner opens Business. There is no separate bank service.',
      `Branches: ${CUSTOMER_BRANCHES.join('; ')}.`,
    ];
    for (const parent of parents) {
      const subs = parent.subs.map((sub) => this.triName(sub)).join('; ');
      lines.push(
        subs ? `- ${this.triName(parent)}: ${subs}` : `- ${this.triName(parent)}`,
      );
    }
    return lines.join('\n');
  }

  private triName(item: AiCatalogItem): string {
    return `${item.nameAr} | ${item.nameEn} | ${item.nameZh}`;
  }

  private scoreCatalog(
    tokens: string[],
    locale: AiLocale,
    parents: AiCatalogParent[],
  ): CatalogHit[] {
    const hits: CatalogHit[] = [];
    for (const parent of parents) {
      const parentText = this.catalogBlob(parent, locale);
      const parentScore = this.textScore(parentText, tokens);
      if (parentScore > 0) {
        hits.push({
          score: parentScore,
          line: this.formatCatalogLine(
            this.pickName(parent, locale),
            this.pickPrice(parent, locale),
            this.pickDesc(parent, locale),
          ),
        });
      }
      for (const sub of parent.subs) {
        const subText = this.catalogBlob(sub, locale);
        const subScore = this.textScore(subText, tokens) + parentScore * 0.15;
        if (subScore > 0) {
          hits.push({
            score: subScore,
            line: this.formatCatalogLine(
              `${this.pickName(parent, locale)} › ${this.pickName(sub, locale)}`,
              this.pickPrice(sub, locale),
              this.pickDesc(sub, locale),
            ),
          });
        }
      }
    }
    hits.sort((a, b) => b.score - a.score);
    const seen = new Set<string>();
    const out: CatalogHit[] = [];
    for (const h of hits) {
      if (seen.has(h.line)) continue;
      seen.add(h.line);
      out.push(h);
      if (out.length >= MAX_CATALOG) break;
    }
    return out;
  }

  private catalogBlob(
    item: {
      nameAr: string;
      nameEn: string;
      nameZh: string;
      descAr: string;
      descEn: string;
      descZh: string;
      priceAr: string;
      priceEn: string;
      priceZh: string;
      id?: string;
      slug?: string;
    },
    locale: AiLocale,
  ): string {
    return [
      item.slug ?? item.id ?? '',
      item.nameAr,
      item.nameEn,
      item.nameZh,
      item.descAr,
      item.descEn,
      item.descZh,
      item.priceAr,
      item.priceEn,
      item.priceZh,
      this.pickName(item, locale),
      this.pickDesc(item, locale),
    ]
      .join(' ')
      .toLowerCase();
  }

  private textScore(haystack: string, tokens: string[]): number {
    let score = 0;
    for (const t of tokens) {
      if (haystack.includes(t)) {
        score += t.length >= 4 ? 2 : 1;
      }
    }
    return score;
  }

  private pickName(
    item: { nameAr: string; nameEn: string; nameZh: string },
    locale: AiLocale,
  ): string {
    switch (locale) {
      case 'ar':
        return item.nameAr;
      case 'zh':
        return item.nameZh;
      default:
        return item.nameEn;
    }
  }

  private pickDesc(
    item: { descAr: string; descEn: string; descZh: string },
    locale: AiLocale,
  ): string {
    switch (locale) {
      case 'ar':
        return item.descAr;
      case 'zh':
        return item.descZh;
      default:
        return item.descEn;
    }
  }

  private pickPrice(
    item: { priceAr: string; priceEn: string; priceZh: string },
    locale: AiLocale,
  ): string {
    switch (locale) {
      case 'ar':
        return item.priceAr;
      case 'zh':
        return item.priceZh;
      default:
        return item.priceEn;
    }
  }

  private formatCatalogLine(
    name: string,
    price: string,
    desc: string,
  ): string {
    const shortDesc =
      desc.length > 80 ? `${desc.slice(0, 79)}…` : desc;
    return `${name} — ${price}${shortDesc ? ` · ${shortDesc}` : ''}`;
  }
}
