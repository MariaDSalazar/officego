const SECONDS_PER_MINUTE = 60;

export function formatter(language: string) {
  const numbers = (options: Intl.NumberFormatOptions) => new Intl.NumberFormat(language, options);
  const languageNames = new Intl.DisplayNames([language], { type: 'language' });
  const lists = new Intl.ListFormat(language, { type: 'conjunction' });
  return {
    number: (value: number, digits = 0) => numbers({ minimumFractionDigits: digits, maximumFractionDigits: digits }).format(value),
    percent: (value: number) => numbers({ style: 'percent', maximumFractionDigits: 0 }).format(value / 100),
    gigabytes: (value: number) => numbers({ style: 'unit', unit: 'gigabyte', maximumFractionDigits: 1 }).format(value),
    megabytes: (value: number) => numbers({ style: 'unit', unit: 'megabyte', maximumFractionDigits: 1 }).format(value),
    gigahertz: (value: number) => `${numbers({ maximumFractionDigits: 2 }).format(value)} GHz`,
    /** A length of time as minutes and seconds, like 18:43. */
    clock: (seconds: number) => `${Math.floor(seconds / SECONDS_PER_MINUTE)}:${String(seconds % SECONDS_PER_MINUTE).padStart(2, '0')}`,
    /** Items joined the way the language does, like «Word, Excel y PowerPoint». */
    list: (items: string[]) => lists.format(items),
    /** An Office language code in words, like «español (México)» for es-mx. */
    officeLanguage: (code: string) => languageNames.of(code) ?? code,
  };
}

export type Formatter = ReturnType<typeof formatter>;
