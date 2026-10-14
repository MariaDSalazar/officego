<script lang="ts">
  import { Check } from '@lucide/svelte';
  import Badge from './Badge.svelte';

  let {
    label,
    color,
    name,
    selected,
    available = true,
    disabled = false,
    onclick,
  }: { label: string; color: string; name: string; selected: boolean; available?: boolean; disabled?: boolean; onclick: () => void } = $props();
</script>

<button class="choice" class:selected class:unavailable={!available} disabled={!available || disabled} aria-pressed={selected} {onclick}>
  <Badge {label} {color} size="sm" unavailable={!available} />
  {name}
  {#if selected}<Check size={14} />{/if}
</button>

<style>
  .choice {
    display: inline-flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-1) var(--space-3) var(--space-1) var(--space-1);
    border: var(--border-regular) solid var(--color-line);
    border-radius: var(--radius-pill);
    background: var(--color-panel);
    color: var(--color-textBody);
    font-size: var(--text-base);
    transition: border-color var(--motion-fast);
  }
  .choice:hover:not(:disabled) {
    border-color: var(--color-accentHover);
  }
  .selected {
    border-color: var(--color-accent);
    background: var(--color-accentTint);
    color: var(--color-accent);
    font-weight: 700;
  }
  .choice:disabled {
    cursor: not-allowed;
  }
  .unavailable {
    opacity: 0.45;
  }
</style>
