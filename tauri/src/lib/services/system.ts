import { getVersion } from '@tauri-apps/api/app';
import { invoke } from '@tauri-apps/api/core';
import { open } from '@tauri-apps/plugin-dialog';
import { openUrl } from '@tauri-apps/plugin-opener';

export const appVersion = () => getVersion();
export const relaunchAsAdmin = () => invoke<void>('relaunch_as_admin');
export const openFolder = (path: string) => invoke<void>('open_folder', { path });
export const openLink = (url: string) => openUrl(url);
export const chooseFolder = (title: string) => open({ directory: true, title }).then((folder) => (typeof folder === 'string' ? folder : null));
export const copyText = (text: string) => navigator.clipboard.writeText(text);
