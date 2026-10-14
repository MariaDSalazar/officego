<script lang="ts">
  import type { Snippet } from 'svelte';

  let { tone = 'info', children }: { tone?: 'info' | 'warn' | 'error' | 'ok'; children: Snippet } = $props();
</script>

<div class="notice {tone}" role={tone === 'error' ? 'alert' : 'status'}>{@render children()}</div>

<style>
  .notice {
    margin-top: var(--space-2);
    padding: var(--space-2) var(--space-3);
    border-radius: var(--radius-md);
    font-size: var(--text-sm);
  }
  .info {
    background: var(--color-accentSoft);
    color: var(--color-accent);
  }
  .warn {
    background: var(--color-warningSoft);
    color: var(--color-warning);
  }
  .error {
    background: var(--color-dangerSoft);
    color: var(--color-danger);
  }
  .ok {
    background: var(--color-successSoft);
    color: var(--color-success);
  }
</style>
