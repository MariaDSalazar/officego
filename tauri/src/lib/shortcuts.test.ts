import assert from 'node:assert/strict';
import { test } from 'node:test';
import { shortcutFor } from './shortcuts.ts';

const SCREENS = ['home', 'install', 'settings'] as const;
const press = (key: string, modifiers: { ctrlKey?: boolean; altKey?: boolean; shiftKey?: boolean } = {}) =>
  shortcutFor({ key, ctrlKey: false, altKey: false, shiftKey: false, metaKey: false, ...modifiers }, SCREENS, 'settings');

test('Ctrl and a digit go to that screen of the menu, and only to the ones that exist', () => {
  assert.deepEqual(press('2', { ctrlKey: true }), { go: 'install' });
  assert.equal(press('4', { ctrlKey: true }), null);
  assert.equal(press('0', { ctrlKey: true }), null);
  assert.equal(press('2'), null);
});

test('Ctrl and comma open the settings, F5 reads the computer again', () => {
  assert.deepEqual(press(',', { ctrlKey: true }), { go: 'settings' });
  assert.deepEqual(press('F5'), { refresh: true });
  assert.equal(press('F5', { ctrlKey: true }), null);
});

test('other modifiers leave the keys to the system', () => {
  assert.equal(press('1', { ctrlKey: true, shiftKey: true }), null);
  assert.equal(press('1', { ctrlKey: true, altKey: true }), null);
});
