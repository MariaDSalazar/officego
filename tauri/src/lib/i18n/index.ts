import i18next, { type TFunction } from 'i18next';

type Namespace = Record<string, unknown>;

export const BASE_LANGUAGE = 'es';

const files = import.meta.glob<Namespace>('../../../locales/*/*.json', { eager: true, import: 'default' });

const resources: Record<string, Record<string, Namespace>> = {};
for (const [path, content] of Object.entries(files)) {
  const [, language, namespace] = path.match(/locales\/([^/]+)\/([^/]+)\.json$/) ?? [];
  if (language && namespace) (resources[language] ??= {})[namespace] = content;
}

export const LANGUAGES = Object.keys(resources);

i18next.init({
  resources,
  lng: BASE_LANGUAGE,
  fallbackLng: BASE_LANGUAGE,
  defaultNS: 'common',
  ns: Object.keys(resources[BASE_LANGUAGE] ?? {}),
  interpolation: { escapeValue: false },
  initAsync: false,
});

/** The first of the system's preferred languages OfficeGo speaks, or the base one. */
export const systemLanguage = () =>
  navigator.languages.map((tag) => tag.split('-')[0].toLowerCase()).find((language) => LANGUAGES.includes(language)) ?? BASE_LANGUAGE;

export const translator = (language: string): TFunction => i18next.getFixedT(language);

export { formatter, type Formatter } from './format';
