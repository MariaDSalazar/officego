import assert from 'node:assert/strict';
import { test } from 'node:test';
import { describeOffice, officeTitle } from './office.ts';
import type { Catalog, InstalledOffice } from './types.ts';

const CATALOG = {
  products: [{ key: '2024', name: 'Office 2024', abbreviation: '24', color: '', route: 'odt', channel: '', weightGb: 0, minimumBuild: 0, editions: [] }],
  editions: [{ key: 'ProPlus', name: 'Professional Plus', apps: [] }],
  apps: [
    { key: 'Word', name: 'Word', abbreviation: 'W', color: '' },
    { key: 'Excel', name: 'Excel', abbreviation: 'X', color: '' },
    { key: 'PowerPoint', name: 'PowerPoint', abbreviation: 'P', color: '' },
  ],
  addOns: [{ key: 'VisioPro', name: 'Visio Professional', abbreviation: 'V', color: '', products: [] }],
  addOnWeightGb: 0,
  languages: [],
  minimumFreeGb: 0,
  workFolder: '',
} as Catalog;

const office = (described: Partial<InstalledOffice>): InstalledOffice => ({
  products: '',
  version: '16.0.17932.21056',
  language: 'es-es',
  architecture: 'x64',
  product: null,
  edition: null,
  apps: [],
  addOns: [],
  ...described,
});
const title = (described: Partial<InstalledOffice>) => officeTitle(describeOffice(CATALOG, office(described)), (items) => items.join(', '), 'Office');

test('a suite is named by its version and edition, with its add-ons apart', () => {
  assert.equal(title({ product: '2024', edition: 'ProPlus' }), 'Office 2024 Professional Plus');
  assert.deepEqual(describeOffice(CATALOG, office({ product: '2024', edition: 'ProPlus', addOns: ['VisioPro'] })).addOns, ['Visio Professional']);
});

test('single apps are named in the catalog order', () => {
  assert.equal(title({ apps: ['PowerPoint', 'Word', 'Excel'] }), 'Word, Excel, PowerPoint');
});

test('an edition without a known version still says Office', () => {
  assert.equal(title({ edition: 'ProPlus' }), 'Office Professional Plus');
  assert.equal(title({}), 'Office');
});
