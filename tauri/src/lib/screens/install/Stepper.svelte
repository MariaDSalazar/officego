<script lang="ts">
  import { Check } from '@lucide/svelte';
  import { INSTALL_STEPS, app } from '../../app.svelte';

  const t = $derived(app.t);
  const current = $derived(INSTALL_STEPS.indexOf(app.installStep));
</script>

<ol>
  {#each INSTALL_STEPS as step, index (step)}
    <li>
      <button
        class:done={index < current}
        class:now={index === current}
        aria-current={index === current ? 'step' : undefined}
        disabled={app.busy}
        onclick={() => (app.installStep = step)}
      >
        <i
          >{#if index < current}<Check size={12} strokeWidth={3} />{:else}{index + 1}{/if}</i
        >{t(`install:steps.${step}`)}
      </button>
    </li>
  {/each}
</ol>

<style>
  ol {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    margin: 0 0 var(--space-5);
    padding: 0;
    list-style: none;
  }
  li {
    display: flex;
    align-items: center;
    gap: var(--space-3);
  }
  li + li::before {
    width: var(--space-6);
    height: var(--border-regular);
    background: var(--color-line);
    content: '';
  }
  button {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: 0;
    border: none;
    background: none;
    color: var(--color-textFaint);
    font-size: var(--text-base);
  }
  button:hover:not(:disabled) {
    color: var(--color-text);
  }
  button:disabled {
    cursor: default;
  }
  i {
    display: grid;
    place-items: center;
    width: var(--size-badgeSm);
    height: var(--size-badgeSm);
    border: var(--border-regular) solid var(--color-line);
    border-radius: var(--radius-round);
    font-size: var(--text-xs);
    font-style: normal;
    font-weight: 700;
  }
  .done {
    color: var(--color-textMuted);
  }
  .done i {
    border-color: var(--color-success);
    background: var(--color-success);
    color: var(--color-panel);
  }
  .now {
    color: var(--color-text);
    font-weight: 600;
  }
  .now i {
    border-color: var(--color-accent);
    background: var(--color-accent);
    color: var(--color-textOnAccent);
  }
</style>
