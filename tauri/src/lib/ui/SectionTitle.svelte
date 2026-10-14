<script lang="ts">
  import type { Snippet } from 'svelte';

  let { children }: { children: Snippet } = $props();
</script>

<h3>{@render children()}</h3>

<style>
  h3 {
    margin: var(--space-4) 0 var(--space-2);
    color: var(--color-textMuted);
    font-size: var(--text-base);
    font-weight: 700;
    letter-spacing: var(--tracking-wide);
    text-transform: uppercase;
  }
  h3:first-child {
    margin-top: 0;
  }
</style>
