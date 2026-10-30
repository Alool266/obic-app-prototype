// Made by Dr Ali
// Customer-facing catalog snapshot for OBIC AI. No staff roster, no admin modules.

export type AiCatalogItem = {
  id?: string;
  nameAr: string;
  nameEn: string;
  nameZh: string;
  descAr: string;
  descEn: string;
  descZh: string;
  priceAr: string;
  priceEn: string;
  priceZh: string;
};

export type AiCatalogParent = AiCatalogItem & {
  slug: string;
  subs: AiCatalogItem[];
};
