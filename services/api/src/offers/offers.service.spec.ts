// Made by Dr Ali
import { Offer } from './offer.entity';
import {
  OffersService,
  resolveOfferKindFilter,
  filtersFromQuery,
} from './offers.service';

function offer(partial: Partial<Offer>): Offer {
  return {
    id: 'o1',
    kind: 'hotels',
    titleAr: 'فندق',
    titleEn: 'Hotel',
    bodyAr: '',
    bodyEn: '',
    priceLabelAr: null,
    priceLabelEn: null,
    locationLabel: 'Guangzhou',
    datesLabel: null,
    media: [],
    attributes: {},
    isPublished: true,
    isSoldOut: false,
    expiresAt: null,
    createdById: 'u1',
    createdAt: new Date(),
    updatedAt: new Date(),
    ...partial,
  } as Offer;
}

describe('OffersService public availability', () => {
  const svc = new OffersService(
    {} as never,
    {} as never,
  );

  it('hides unpublished, sold out, and expired offers from customers', () => {
    expect(svc.isCustomerAvailable(offer({}))).toBe(true);
    expect(svc.isCustomerAvailable(offer({ isPublished: false }))).toBe(false);
    expect(svc.isCustomerAvailable(offer({ isSoldOut: true }))).toBe(false);
    expect(
      svc.isCustomerAvailable(
        offer({ expiresAt: new Date(Date.now() - 60_000) }),
      ),
    ).toBe(false);
    expect(
      svc.isCustomerAvailable(
        offer({ expiresAt: new Date(Date.now() + 60_000) }),
      ),
    ).toBe(true);
  });
});

describe('offer list filters', () => {
  it('treats type as an alias of kind', () => {
    expect(resolveOfferKindFilter(undefined, 'flights')).toBe('flights');
    expect(filtersFromQuery({ type: 'hotels' }).kind).toBe('hotels');
    expect(resolveOfferKindFilter('not a type')).toBeUndefined();
  });

  it('records kind, q, and city on the query builder', () => {
    const clauses: string[] = [];
    const qb = {
      andWhere: (sql: string) => {
        clauses.push(sql);
        return qb;
      },
    };
    const svc = new OffersService({} as never, {} as never);
    svc.applyListFilters(qb as never, {
      kind: 'hotels',
      q: 'canton',
      city: 'Guangzhou',
    });
    expect(clauses.some((c) => c.includes('o.kind'))).toBe(true);
    expect(clauses.some((c) => c.includes('titleEn'))).toBe(true);
    expect(clauses.some((c) => c.includes('locationLabel'))).toBe(true);
    expect(clauses.some((c) => c.includes('attributes'))).toBe(true);
  });
});
