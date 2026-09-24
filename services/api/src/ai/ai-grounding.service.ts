// Made by Dr Ali
// Keyword retrieval over curated FAQ + mega catalog (titles/prices).
// No user data — corpus is static seed only (never other users' chats).

import { Injectable } from '@nestjs/common';
import { MEGA_CATALOG_SEED } from '../services/mega-catalog.seed';
import { AiLocale } from './obic-ai.constants';
import { FaqEntry, OBIC_FAQ } from './ai-grounding.faq';

type CatalogHit = {
  score: number;
  line: string;
};

const MAX_FAQ = 3;
const MAX_CATALOG = 5;
const MAX_CONTEXT_CHARS = 2200;

@Injectable()
export class AiGroundingService {
  /**
   * Build a short grounding block for the system prompt.
   * Prefer catalog price lines when they match — model must not invent prices.
   */
  retrieve(query: string, locale: AiLocale = 'en'): string {
    const tokens = this.tokenize(query);
    if (tokens.length === 0) {
      return this.fallbackRules(locale);
    }

    const faqHits = this.scoreFaq(tokens, locale);
    const catalogHits = this.scoreCatalog(tokens, locale);

    const parts: string[] = [
      'Grounded OBIC facts (use these; do not invent prices or confirmations):',
    ];

    if (faqHits.length > 0) {
      parts.push('FAQ:');
      for (const f of faqHits) {
        parts.push(`- ${f}`);
      }
    }

    if (catalogHits.length > 0) {
      parts.push(
        'Catalog (use listed prices only; if unsure say staff will confirm):',
      );
      for (const c of catalogHits) {
        parts.push(`- ${c.line}`);
      }
    } else {
      parts.push(
        'No strong catalog price match — do not invent a price; suggest Services catalog or staff.',
      );
    }

    parts.push(this.fallbackRules(locale));

    let out = parts.join('\n');
    if (out.length > MAX_CONTEXT_CHARS) {
      out = out.slice(0, MAX_CONTEXT_CHARS - 1) + '…';
    }
    return out;
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

  private scoreCatalog(tokens: string[], locale: AiLocale): CatalogHit[] {
    const hits: CatalogHit[] = [];
    for (const parent of MEGA_CATALOG_SEED) {
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
