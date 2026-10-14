<script lang="ts">
  import type { Component } from 'svelte';
  import Badge from './Badge.svelte';
  import Button from './Button.svelte';

  let {
    label,
    icon,
    color,
    title,
    description,
    action,
    danger = false,
    disabled = false,
    onclick,
  }: {
    label?: string;
    icon?: Component<{ size?: number }>;
    color: string;
    title: string;
    description: string;
    action: string;
    danger?: boolean;
    disabled?: boolean;
    onclick: () => void;
  } = $props();
</script>

<div class="row" class:danger>
  <Badge {label} {icon} {color} size="lg" soft />
  <div class="text">
    <h4>{title}</h4>
    <p>{description}</p>
  </div>
  <Button variant={danger ? 'danger' : 'ghost'} {disabled} {onclick}>{action}</Button>
</div>

<style>
  .row {
    display: flex;
    align-items: center;
    gap: var(--space-4);
    margin-bottom: var(--space-3);
    padding: var(--space-4);
    border: var(--border-hairline) solid var(--color-line);
    border-radius: var(--radius-xl);
    background: var(--color-raised);
  }
  .danger {
    border-color: var(--color-dangerLine);
  }
  .text {
    flex: 1;
    min-width: 0;
  }
  h4 {
    margin-bottom: var(--space-1);
    font-size: var(--text-lg);
    font-weight: 600;
  }
  p {
    color: var(--color-textMuted);
    font-size: var(--text-sm);
  }
</style>
