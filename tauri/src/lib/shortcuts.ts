export type ShortcutAction<Screen extends string> = { go: Screen } | { refresh: true };

type Keys = Pick<KeyboardEvent, 'key' | 'ctrlKey' | 'altKey' | 'shiftKey' | 'metaKey'>;

const SETTINGS_KEY = ',';
const REFRESH_KEY = 'F5';
const CLOSE_KEY = 'Esc';
const CONTROL = 'Ctrl';
const DIGIT = /^[1-9]$/;

export function shortcutFor<Screen extends string>(event: Keys, screens: readonly Screen[], settings: Screen): ShortcutAction<Screen> | null {
  if (event.altKey || event.metaKey || event.shiftKey) return null;
  if (event.key === REFRESH_KEY) return event.ctrlKey ? null : { refresh: true };
  if (!event.ctrlKey) return null;
  if (event.key === SETTINGS_KEY) return { go: settings };
  return DIGIT.test(event.key) && screens[Number(event.key) - 1] ? { go: screens[Number(event.key) - 1] } : null;
}

export const shortcutList = (count: number) => [
  { keys: [CONTROL, `1–${count}`], label: 'sections' },
  { keys: [CONTROL, SETTINGS_KEY], label: 'settings' },
  { keys: [REFRESH_KEY], label: 'refresh' },
  { keys: [CLOSE_KEY], label: 'close' },
];
