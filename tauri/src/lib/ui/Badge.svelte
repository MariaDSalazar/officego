<script lang="ts">
  import type { Component } from 'svelte';

  const ICON_SIZES = { sm: 12, md: 16, lg: 22, xl: 24 };

  let {
    label = '',
    icon: Icon,
    color,
    size = 'md',
    round = false,
    unavailable = false,
  }: {
    label?: string;
    icon?: Component<{ size?: number }>;
    color: string;
    size?: 'sm' | 'md' | 'lg' | 'xl';
    round?: boolean;
    unavailable?: boolean;
  } = $props();
</script>

<span class="badge {size}" class:round style:background={unavailable ? 'var(--color-unavailable)' : color}>
  {#if Icon}<Icon size={ICON_SIZES[size]} />{:else}{label}{/if}
</span>

<style>
  .badge {
    display: inline-flex;
    flex: none;
    align-items: center;
    justify-content: center;
    color: var(--color-textOnAccent);
    font-weight: 700;
  }
  .sm {
    width: var(--size-badgeSm);
    height: var(--size-badgeSm);
    border-radius: var(--radius-sm);
    font-size: var(--text-sm);
  }
  .md {
    width: var(--size-badgeMd);
    height: var(--size-badgeMd);
    border-radius: var(--radius-md);
    font-size: var(--text-md);
  }
  .lg {
    width: var(--size-badgeLg);
    height: var(--size-badgeLg);
    border-radius: var(--radius-lg);
    font-size: var(--text-xl);
  }
  .xl {
    width: var(--size-badgeXl);
    height: var(--size-badgeXl);
    border-radius: var(--radius-xl);
    font-size: var(--text-xl);
  }
  .round {
    border-radius: var(--radius-round);
  }
</style>
