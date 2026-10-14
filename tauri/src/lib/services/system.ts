import { getVersion } from '@tauri-apps/api/app';
import { invoke } from '@tauri-apps/api/core';
import { Effect, getCurrentWindow, type Theme } from '@tauri-apps/api/window';
import { open } from '@tauri-apps/plugin-dialog';
import { openUrl } from '@tauri-apps/plugin-opener';

type ClientHints = { userAgentData?: { getHighEntropyValues: (hints: string[]) => Promise<{ platformVersion?: string }> } };

const appWindow = getCurrentWindow();

export const appVersion = () => getVersion();
export const relaunchAsAdmin = () => invoke<void>('relaunch_as_admin');
export const openFolder = (path: string) => invoke<void>('open_folder', { path });
export const openLink = (url: string) => openUrl(url);
export const chooseFolder = (title: string) => open({ directory: true, title }).then((folder) => (typeof folder === 'string' ? folder : null));
export const copyText = (text: string) => navigator.clipboard.writeText(text);

export const minimizeWindow = () => appWindow.minimize();
export const toggleMaximizeWindow = () => appWindow.toggleMaximize();
export const closeWindow = () => appWindow.close();
export const isMaximized = () => appWindow.isMaximized();
export const onWindowResized = (handler: () => void) => appWindow.onResized(handler);

/** Windows 11 reports a platform version of 13 or higher; Mica only exists there. */
export const supportsMica = async () => {
  const hints = await (navigator as Navigator & ClientHints).userAgentData?.getHighEntropyValues(['platformVersion']);
  return Number.parseInt(hints?.platformVersion ?? '0', 10) >= 13;
};

/** Null follows the system theme. */
export const setWindowTheme = (theme: Theme | null) => appWindow.setTheme(theme);
export const applyMica = () => appWindow.setEffects({ effects: [Effect.Mica] });
