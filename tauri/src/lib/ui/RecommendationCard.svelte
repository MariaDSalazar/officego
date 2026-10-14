<script lang="ts">
  import { app } from '../app.svelte';
  import { productOf } from '../selection';
  import Badge from './Badge.svelte';
  import Button from './Button.svelte';

  const t = $derived(app.t);
  const recommendation = $derived(app.report!.recommendation);
  const product = $derived(productOf(app.catalog!, recommendation.product));
  const edition = $derived(app.catalog!.editions.find((candidate) => candidate.key === product.editions[0])?.name ?? '');
  const classic = $derived(product.route === 'c2r');
</script>

<div class="card" class:classic>
  <Badge label={product.abbreviation} color={product.color} size="xl" />
  <div class="text">
    <h4>{product.name} <span>{edition}</span></h4>
    <p>{t(`recommendation:reasons.${recommendation.reason}`)}</p>
  </div>
  <Button variant={classic ? 'caution' : 'primary'} disabled={app.busy} onclick={app.chooseRecommended}>{t('home:installThis')}</Button>
</div>

<style>
  .card {
    display: flex;
    align-items: center;
    gap: var(--space-4);
    padding: var(--space-4) var(--space-5);
    border: var(--border-regular) solid var(--color-accent);
    border-radius: var(--radius-xl);
    background: var(--color-accentTint);
    box-shadow: var(--shadow-selected);
  }
  .classic {
    border-color: var(--color-warningStrong);
    background: var(--color-warningSoft);
    box-shadow: none;
  }
  .text {
    flex: 1;
  }
  h4 {
    margin-bottom: var(--space-1);
    font-size: var(--text-xl);
    font-weight: 600;
  }
  h4 span {
    color: var(--color-textMuted);
    font-weight: 400;
  }
  p {
    color: var(--color-textMuted);
    font-size: var(--text-sm);
  }
</style>
