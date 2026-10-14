<script lang="ts">
  let {
    label,
    options,
    value,
    disabled = false,
    onchange,
  }: { label: string; options: { value: string; label: string }[]; value: string; disabled?: boolean; onchange: (value: string) => void } = $props();
</script>

<div class="segmented" role="radiogroup" aria-label={label}>
  {#each options as option (option.value)}
    <button role="radio" aria-checked={option.value === value} class:on={option.value === value} {disabled} onclick={() => onchange(option.value)}>
      {option.label}
    </button>
  {/each}
</div>

<style>
  .segmented {
    display: flex;
    gap: var(--space-1);
    padding: var(--space-1);
    border: var(--border-hairline) solid var(--color-line);
    border-radius: var(--radius-lg);
    background: var(--color-raised);
  }
  button {
    flex: 1;
    padding: var(--space-2) var(--space-1);
    border: none;
    border-radius: var(--radius-md);
    background: none;
    color: var(--color-textMuted);
    font-size: var(--text-base);
    white-space: nowrap;
  }
  button:hover:not(:disabled, .on) {
    color: var(--color-text);
  }
  .on {
    background: var(--color-panel);
    color: var(--color-text);
    font-weight: 600;
    box-shadow: var(--shadow-card);
  }
  button:disabled {
    cursor: default;
  }
</style>
