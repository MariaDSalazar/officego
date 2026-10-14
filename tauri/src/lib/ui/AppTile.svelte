<script lang="ts">
  import { Check } from '@lucide/svelte';
  import { app } from '../app.svelte';
  import Badge from './Badge.svelte';

  let {
    label,
    color,
    name,
    detail,
    selected,
    available = true,
    readonly = false,
    onclick,
  }: {
    label: string;
    color: string;
    name: string;
    detail: string;
    selected: boolean;
    available?: boolean;
    readonly?: boolean;
    onclick?: () => void;
  } = $props();
</script>

<button class="tile" class:selected class:unavailable={!available} aria-pressed={selected} disabled={readonly || !available || app.busy} {onclick}>
  <Badge {label} {color} unavailable={!available} />
  <span class="text"><b>{name}</b><span>{detail}</span></span>
  {#if selected}<span class="tick"><Check size={12} strokeWidth={3} /></span>{/if}
</button>

<style>
  .tile {
    position: relative;
    display: flex;
    align-items: center;
    gap: var(--space-3);
    min-width: 0;
    padding: var(--space-3);
    border: var(--border-regular) solid var(--color-line);
    border-radius: var(--radius-lg);
    background: var(--color-panel);
    text-align: left;
    transition: border-color var(--motion-fast);
  }
  .tile:hover:not(:disabled) {
    border-color: var(--color-accentHover);
  }
  .selected,
  .selected:hover:not(:disabled) {
    border-color: var(--color-accent);
    background: var(--color-accentSoft);
  }
  .tile:disabled {
    cursor: default;
  }
  .unavailable {
    opacity: 0.55;
  }
  .text {
    display: grid;
    min-width: 0;
  }
  b {
    font-size: var(--text-base);
    font-weight: 600;
  }
  .text span {
    overflow: hidden;
    color: var(--color-textFaint);
    font-size: var(--text-xs);
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .tick {
    position: absolute;
    top: var(--space-2);
    right: var(--space-2);
    display: grid;
    place-items: center;
    width: var(--size-tick);
    height: var(--size-tick);
    border-radius: var(--radius-round);
    background: var(--color-accent);
    color: var(--color-textOnAccent);
  }
</style>
