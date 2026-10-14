<script lang="ts">
  import { app } from '../app.svelte';
  import type { Product } from '../types';
  import Badge from './Badge.svelte';

  let { product, selected, onclick }: { product: Product; selected: boolean; onclick: () => void } = $props();

  const t = $derived(app.t);
</script>

<button class="tile" class:selected aria-pressed={selected} disabled={app.busy} {onclick}>
  <Badge label={product.abbreviation} color={product.color} />
  <b>{product.name}</b>
  <span class="tagline">{t(`catalog:taglines.${product.key}`)}</span>
  <span class="kind {product.kind}">{t(`catalog:kinds.${product.kind}`)}</span>
</button>

<style>
  .tile {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: var(--space-1);
    padding: var(--space-3) var(--space-2);
    border: var(--border-regular) solid var(--color-line);
    border-radius: var(--radius-lg);
    background: var(--color-panel);
    transition: border-color var(--motion-fast);
  }
  .tile:hover:not(:disabled) {
    border-color: var(--color-accentHover);
  }
  .tile:disabled {
    cursor: default;
  }
  .selected {
    border-color: var(--color-accent);
    background: var(--color-accentTint);
    box-shadow: var(--shadow-selected);
  }
  b {
    margin-top: var(--space-1);
    font-size: var(--text-base);
  }
  .tagline {
    color: var(--color-textFaint);
    font-size: var(--text-xs);
  }
  .kind {
    margin-top: var(--space-1);
    padding: 0 var(--space-2);
    border-radius: var(--radius-pill);
    font-size: var(--text-xs);
    font-weight: 700;
  }
  .volume {
    background: var(--color-successSoft);
    color: var(--color-success);
  }
  .retail {
    background: var(--color-warningSoft);
    color: var(--color-retail);
  }
  .subscription {
    background: var(--color-accentSoft);
    color: var(--color-accent);
  }
</style>
