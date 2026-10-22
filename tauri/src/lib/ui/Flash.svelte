<script lang="ts">
  import { CircleCheck, TriangleAlert } from '@lucide/svelte';
  import { app } from '../app.svelte';

  const ICONS = { ok: CircleCheck, warn: TriangleAlert };

  const flash = $derived(app.flash);
</script>

<div class="zone" aria-live="polite">
  {#if flash}
    {@const Icon = ICONS[flash.tone]}
    {#key flash.id}
      <p class="flash {flash.tone}"><Icon size={16} />{flash.text}</p>
    {/key}
  {/if}
</div>

<style>
  .zone {
    position: absolute;
    right: 0;
    bottom: calc(var(--size-footer) + var(--space-3));
    left: 0;
    display: grid;
    justify-items: center;
    pointer-events: none;
  }
  .flash {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    max-width: var(--size-dialog);
    padding: var(--space-3) var(--space-4);
    border: var(--border-hairline) solid var(--color-line);
    border-radius: var(--radius-pill);
    background: var(--color-panel);
    color: var(--color-text);
    font-size: var(--text-base);
    box-shadow: var(--shadow-raised);
    animation: rise var(--motion-flash) ease-out;
  }
  .ok :global(svg) {
    flex: none;
    color: var(--color-success);
  }
  .warn :global(svg) {
    flex: none;
    color: var(--color-warningStrong);
  }
  @keyframes rise {
    from {
      opacity: 0;
      transform: translateY(var(--space-2));
    }
  }
  @media (prefers-reduced-motion: reduce) {
    @keyframes rise {
      from {
        opacity: 0;
      }
    }
  }
</style>
