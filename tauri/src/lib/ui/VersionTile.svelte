<script lang="ts">
  import { app } from '../app.svelte';
  import type { Product } from '../types';

  let { product, selected, recommended, fits, onclick }: { product: Product; selected: boolean; recommended: boolean; fits: boolean; onclick: () => void } =
    $props();

  const t = $derived(app.t);
</script>

<button class="tile" class:selected class:unfit={!fits} aria-pressed={selected} disabled={!fits || app.busy} {onclick}>
  <span class="year"><i style:background={product.color}></i>{product.key}</span>
  <b>{product.name}</b>
  <span class="what">{t(`catalog:descriptions.${product.key}`)}</span>
  {#if !fits}
    <span class="flag">{t(`catalog:requirements.${product.key}`)}</span>
  {:else if recommended}
    <span class="flag">{t('install:forThisPc')}</span>
  {/if}
</button>

<style>
  .tile {
    display: grid;
    align-content: start;
    justify-items: start;
    gap: var(--space-1);
    padding: var(--space-4) var(--space-5);
    border: var(--border-regular) solid var(--color-line);
    border-radius: var(--radius-xl);
    background: var(--color-panel);
    text-align: left;
    transition:
      border-color var(--motion-fast),
      box-shadow var(--motion-fast);
  }
  .tile:hover:not(:disabled) {
    border-color: var(--color-accentHover);
  }
  .selected,
  .selected:hover:not(:disabled) {
    border-color: var(--color-accent);
    box-shadow: var(--shadow-selected);
  }
  .tile:disabled {
    cursor: default;
  }
  .unfit {
    opacity: 0.5;
  }
  .year {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    margin-bottom: var(--space-2);
    font: 600 var(--text-display) / 0.9 var(--font-display);
    letter-spacing: var(--tracking-tight);
  }
  .year i {
    width: var(--size-yearBar);
    height: 0.8em;
    border-radius: var(--radius-pill);
  }
  b {
    font-size: var(--text-md);
    font-weight: 600;
  }
  .what {
    color: var(--color-textMuted);
    font-size: var(--text-sm);
  }
  .flag {
    margin-top: var(--space-2);
    padding: var(--space-1) var(--space-3);
    border-radius: var(--radius-pill);
    background: var(--color-accentSoft);
    color: var(--color-accent);
    font-size: var(--text-sm);
    font-weight: 600;
  }
  .unfit .flag {
    background: var(--color-raised);
    color: var(--color-textMuted);
  }
</style>
