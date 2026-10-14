<script lang="ts">
  import type { Component, Snippet } from 'svelte';

  let {
    variant = 'primary',
    icon: Icon,
    disabled = false,
    onclick,
    children,
  }: {
    variant?: 'primary' | 'caution' | 'ghost' | 'danger';
    icon?: Component<{ size?: number }>;
    disabled?: boolean;
    onclick?: () => void;
    children: Snippet;
  } = $props();
</script>

<button class="button {variant}" {disabled} {onclick}>
  {#if Icon}<Icon size={16} />{/if}
  {@render children()}
</button>

<style>
  .button {
    display: inline-flex;
    flex: none;
    align-items: center;
    justify-content: center;
    gap: var(--space-2);
    padding: var(--space-3) var(--space-5);
    border: var(--border-hairline) solid transparent;
    border-radius: var(--radius-lg);
    font-size: var(--text-md);
    font-weight: 600;
    white-space: nowrap;
    transition:
      filter var(--motion-fast),
      transform var(--motion-fast);
  }
  .primary {
    background: var(--color-accent);
    color: var(--color-textOnAccent);
  }
  .caution {
    background: var(--color-caution);
    color: var(--color-textOnAccent);
  }
  .ghost {
    border-color: var(--color-line);
    background: var(--color-panel);
    color: var(--color-text);
  }
  .ghost:hover:not(:disabled) {
    border-color: var(--color-accentHover);
  }
  .danger {
    border-color: var(--color-dangerLine);
    background: var(--color-dangerSoft);
    color: var(--color-danger);
  }
  .button:hover:not(:disabled) {
    filter: brightness(1.06);
  }
  .button:active:not(:disabled) {
    transform: translateY(var(--border-hairline));
  }
  .button:disabled {
    opacity: 0.45;
    cursor: default;
  }
</style>
