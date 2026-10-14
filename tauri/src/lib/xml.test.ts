import assert from 'node:assert/strict';
import { test } from 'node:test';
import { highlightXml } from './xml.ts';

const CONFIGURATION = `<Configuration>
  <Add OfficeClientEdition="64" Channel="PerpetualVL2024">
    <Language ID="es-es" />
  </Add>
</Configuration>`;

test('the pieces join back into the same text', () => {
  assert.equal(
    highlightXml(CONFIGURATION)
      .map((token) => token.text)
      .join(''),
    CONFIGURATION,
  );
});

test('tags, attributes, values and punctuation get their own kind', () => {
  const kinds = highlightXml('<Add OfficeClientEdition="64"><Language ID="es-es" /></Add>').map((token) => [token.kind, token.text]);
  assert.deepEqual(kinds, [
    ['punct', '<'],
    ['tag', 'Add'],
    ['text', ' '],
    ['attr', 'OfficeClientEdition'],
    ['text', '='],
    ['value', '"64"'],
    ['punct', '>'],
    ['punct', '<'],
    ['tag', 'Language'],
    ['text', ' '],
    ['attr', 'ID'],
    ['text', '='],
    ['value', '"es-es"'],
    ['text', ' '],
    ['punct', '/>'],
    ['punct', '</'],
    ['tag', 'Add'],
    ['punct', '>'],
  ]);
});
