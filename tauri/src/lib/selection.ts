import type { Catalog, Product, Selection } from './types';

export const DEFAULT_APPS = ['Word', 'Excel', 'PowerPoint'];

export const productOf = (catalog: Catalog, key: string): Product => catalog.products.find((product) => product.key === key) ?? catalog.products[0];

/** The apps the user may pick: the edition's, or none when Microsoft installs the whole suite. */
export function pickableApps(catalog: Catalog, selection: Selection): string[] {
  if (productOf(catalog, selection.product).route === 'c2r') return [];
  return catalog.editions.find((edition) => edition.key === selection.edition)?.apps ?? [];
}

export const addOnAvailable = (catalog: Catalog, addOn: string, product: string) =>
  catalog.addOns.some((candidate) => candidate.key === addOn && candidate.products.includes(product));

/** Keeps only what the chosen product and edition really include; a whole-suite product leaves the app choice for later. */
export function adjust(catalog: Catalog, selection: Selection): Selection {
  const product = productOf(catalog, selection.product);
  const edition = product.editions.includes(selection.edition) ? selection.edition : product.editions[0];
  const fitted = { ...selection, product: product.key, edition };
  const pickable = pickableApps(catalog, fitted);
  const apps = selection.apps.filter((app) => pickable.includes(app));
  return {
    ...fitted,
    apps: !pickable.length ? selection.apps : apps.length ? apps : pickable.slice(0, DEFAULT_APPS.length),
    addOns: selection.addOns.filter((addOn) => addOnAvailable(catalog, addOn, product.key)),
  };
}

/** Whether a version runs on the Windows build the engine reported, like 26100.4351. */
export const fitsMachine = (product: Product, build: string) => Number.parseInt(build, 10) >= product.minimumBuild;

export const toggle = (list: string[], item: string) => (list.includes(item) ? list.filter((entry) => entry !== item) : [...list, item]);

export const downloadSizeGb = (catalog: Catalog, selection: Selection) =>
  productOf(catalog, selection.product).weightGb + selection.addOns.length * catalog.addOnWeightGb;

/** The Office language matching the system, or the catalog's first. */
export const officeLanguageFor = (catalog: Catalog, systemTags: readonly string[]) =>
  systemTags.map((tag) => tag.toLowerCase()).find((tag) => catalog.languages.includes(tag)) ?? catalog.languages[0];
