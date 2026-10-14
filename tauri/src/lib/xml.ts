export type XmlToken = { kind: 'punct' | 'tag' | 'attr' | 'value' | 'text'; text: string };

const TOKENS = /(<\/?|\/?>)|("[^"]*")|([\w.-]+)(?==)|((?<=<\/?)[\w.-]+)/g;

/** Splits an XML text into the pieces a viewer colors; joined back, they give the same text. */
export function highlightXml(xml: string): XmlToken[] {
  const tokens: XmlToken[] = [];
  let last = 0;
  for (const match of xml.matchAll(TOKENS)) {
    const [text, punct, value, attr] = match;
    if (match.index > last) tokens.push({ kind: 'text', text: xml.slice(last, match.index) });
    tokens.push({ kind: punct ? 'punct' : value ? 'value' : attr ? 'attr' : 'tag', text });
    last = match.index + text.length;
  }
  if (last < xml.length) tokens.push({ kind: 'text', text: xml.slice(last) });
  return tokens;
}
