<script lang="ts">
  import { app } from '../../app.svelte';
  import { fitsMachine } from '../../selection';
  import PageTitle from '../../ui/PageTitle.svelte';
  import VersionTile from '../../ui/VersionTile.svelte';

  const t = $derived(app.t);
  const build = $derived(app.machine!.build);
  const recommended = $derived(app.report!.recommendation.product);
</script>

<PageTitle title={t('install:versionTitle')} lead={t('install:versionLead')} />
<div class="grid">
  {#each app.catalog!.products as product (product.key)}
    <VersionTile
      {product}
      selected={product.key === app.selection.product}
      recommended={product.key === recommended}
      fits={fitsMachine(product, build)}
      onclick={() => app.choose({ product: product.key })}
    />
  {/each}
</div>

<style>
  .grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: var(--space-3);
  }
</style>
