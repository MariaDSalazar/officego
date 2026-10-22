<script lang="ts">
  import type { Component, Snippet } from 'svelte';

  let {
    title,
    icon: Icon,
    tone = 'info',
    children,
    actions,
  }: { title: string; icon: Component<{ size?: number }>; tone?: 'info' | 'warn' | 'danger'; children: Snippet; actions?: Snippet } = $props();

  const id = $props.id();
</script>

<div class="backdrop">
  <div class="dialog {tone}" role="dialog" aria-modal="true" aria-labelledby="{id}-title">
    <header>
      <span class="icon"><Icon size={20} /></span>
      <h2 id="{id}-title">{title}</h2>
    </header>
    {@render children()}
    {#if actions}<footer>{@render actions()}</footer>{/if}
  </div>
</div>

<style>
  .backdrop {
    position: fixed;
    inset: 0;
    z-index: 10;
    display: grid;
    place-items: center;
    padding: var(--space-6);
    background: var(--color-backdrop);
  }
  .dialog {
    display: grid;
    gap: var(--space-3);
    width: min(100%, var(--size-dialog));
    max-height: 100%;
    overflow-y: auto;
    padding: var(--space-6);
    border-radius: var(--radius-xl);
    background: var(--color-panel);
    box-shadow: var(--shadow-raised);
    user-select: text;
  }
  header {
    display: flex;
    align-items: center;
    gap: var(--space-3);
  }
  .icon {
    display: grid;
    place-items: center;
    color: var(--color-accent);
  }
  .warn .icon {
    color: var(--color-warningStrong);
  }
  .danger .icon {
    color: var(--color-danger);
  }
  h2 {
    font-size: var(--text-xl);
  }
  footer {
    display: flex;
    flex-wrap: wrap;
    justify-content: flex-end;
    gap: var(--space-2);
    margin-top: var(--space-2);
  }
</style>
