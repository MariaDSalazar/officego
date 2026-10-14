<script lang="ts">
  import type { Snippet } from 'svelte';

  let { children }: { children: Snippet } = $props();
</script>

<h3>{@render children()}</h3>

<style>
  h3 {
    margin: var(--space-6) 0 var(--space-3);
    color: var(--color-textMuted);
    font-size: var(--text-md);
    font-weight: 600;
  }
  h3:first-child {
    margin-top: 0;
  }
</style>
