import tokens from '../../../design/tokens.json';

type TokenTree = { [key: string]: string | TokenTree };

const REFERENCE = /\{([^}]+)\}/g;

const { dark, ...base } = tokens as unknown as TokenTree & { dark: TokenTree };

const property = (path: string) => `--${path.replaceAll('.', '-')}`;

/** Publishes every design token as a CSS variable, with the dark palette on top when asked; `{group.name}` inside a value points to another token. */
export function applyTokens(darkTheme: boolean, root: HTMLElement = document.documentElement) {
  const walk = (node: TokenTree, prefix: string) => {
    for (const [key, value] of Object.entries(node)) {
      if (typeof value !== 'string') walk(value, `${prefix}${key}.`);
      else root.style.setProperty(property(`${prefix}${key}`), value.replace(REFERENCE, (_, reference) => `var(${property(reference)})`));
    }
  };
  walk(base, '');
  if (darkTheme) walk(dark, '');
  root.style.colorScheme = darkTheme ? 'dark' : 'light';
}
