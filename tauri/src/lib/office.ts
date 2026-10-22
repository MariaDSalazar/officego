import type { Catalog, InstalledOffice, OfficeApp, Product } from './types';

export interface OfficeSummary {
  product: Product | null;
  suite: string;
  apps: OfficeApp[];
  addOns: string[];
}

export const describeOffice = (catalog: Catalog, office: InstalledOffice): OfficeSummary => ({
  product: catalog.products.find((product) => product.key === office.product) ?? null,
  suite: catalog.editions.find((edition) => edition.key === office.edition)?.name ?? '',
  apps: catalog.apps.filter((app) => office.apps.includes(app.key)),
  addOns: catalog.addOns.filter((addOn) => office.addOns.includes(addOn.key)).map((addOn) => addOn.name),
});

export function officeTitle(summary: OfficeSummary, list: (items: string[]) => string, fallback: string) {
  if (summary.suite) return `${summary.product?.name ?? fallback} ${summary.suite}`;
  if (summary.apps.length) return list(summary.apps.map((app) => app.name));
  return summary.product?.name ?? fallback;
}
