import { Channel, invoke } from '@tauri-apps/api/core';
import type { Catalog, License, MachineReport, Selection, Task, TaskEvent, TaskOutcome } from '../types';

export const getCatalog = () => invoke<Catalog>('catalog');
export const getMachine = () => invoke<MachineReport>('machine');
export const getLicense = () => invoke<License | null>('license');
export const getConfiguration = (selection: Selection) => invoke<string>('configuration', { selection });

export function runTask(task: Task, onEvent: (event: TaskEvent) => void) {
  const events = new Channel<TaskEvent>(onEvent);
  return invoke<TaskOutcome>('run_task', { task, events });
}
