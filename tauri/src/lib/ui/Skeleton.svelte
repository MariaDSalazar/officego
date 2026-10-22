<script lang="ts">
  import { app } from '../app.svelte';

  const CARDS = 2;
  const TILES = 3;
</script>

<div class="skeleton" aria-busy="true">
  <p>{app.t('common:checking')}</p>
  <i class="line title"></i>
  <i class="line"></i>
  <div class="cards">
    {#each { length: CARDS }, index (index)}<i class="block card"></i>{/each}
  </div>
  <div class="tiles">
    {#each { length: TILES }, index (index)}<i class="block tile"></i>{/each}
  </div>
</div>

<style>
  .skeleton {
    display: grid;
    gap: var(--space-3);
  }
  p {
    color: var(--color-textFaint);
    font-size: var(--text-sm);
  }
  i {
    display: block;
    border-radius: var(--radius-lg);
    background: linear-gradient(90deg, var(--color-raised) 30%, var(--color-lineSoft) 50%, var(--color-raised) 70%) 0 0 / 300% 100%;
    animation: shimmer var(--motion-shimmer) ease-in-out infinite;
  }
  .line {
    width: 60%;
    height: var(--space-4);
  }
  .title {
    width: 40%;
    height: var(--space-8);
  }
  .cards,
  .tiles {
    display: grid;
    gap: var(--space-3);
    margin-top: var(--space-3);
  }
  .cards {
    grid-template-columns: repeat(2, 1fr);
  }
  .tiles {
    grid-template-columns: repeat(3, 1fr);
  }
  .card {
    height: var(--size-skeletonCard);
    border-radius: var(--radius-xl);
  }
  .tile {
    height: var(--size-skeletonTile);
    border-radius: var(--radius-xl);
  }
  @keyframes shimmer {
    from {
      background-position: 100% 0;
    }
    to {
      background-position: 0 0;
    }
  }
  @media (prefers-reduced-motion: reduce) {
    i {
      animation: none;
    }
  }
</style>
