import tokens from '../../../design/tokens.json';

type TokenTree = { [key: string]: string | TokenTree };

const REFERENCE = /\{([^}]+)\}/g;

const property = (path: string) => `--${path.replaceAll('.', '-')}`;

/** Publishes every design token as a CSS variable; `{group.name}` inside a value points to another token. */
export function applyTokens(root: HTMLElement = document.documentElement) {
  const walk = (node: TokenTree, prefix: string) => {
    for (const [key, value] of Object.entries(node)) {
      if (typeof value !== 'string') walk(value, `${prefix}${key}.`);
      else root.style.setProperty(property(`${prefix}${key}`), value.replace(REFERENCE, (_, reference) => `var(${property(reference)})`));
    }
  };
  walk(tokens as TokenTree, '');
}
