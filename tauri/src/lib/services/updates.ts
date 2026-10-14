import { Channel, invoke } from '@tauri-apps/api/core';
import type { Release } from '../types';

export const checkUpdate = () => invoke<Release | null>('check_update');

export function installUpdate(onProgress: (done: number) => void) {
  return invoke<void>('install_update', { progress: new Channel<number>(onProgress) });
}
