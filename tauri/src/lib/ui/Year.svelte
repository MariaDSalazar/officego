<script lang="ts">
  import type { Product } from '../types';

  let { product }: { product: Product } = $props();
</script>

<span class="year"><i style:background={product.color}></i>{product.key}</span>

<style>
  .year {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    font: 600 var(--text-display) / 0.9 var(--font-display);
    letter-spacing: var(--tracking-tight);
  }
  i {
    width: var(--size-yearBar);
    height: 0.8em;
    border-radius: var(--radius-pill);
  }
</style>
