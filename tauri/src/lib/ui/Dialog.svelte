<script lang="ts">
  import { CircleAlert, Info, TriangleAlert } from '@lucide/svelte';
  import { app } from '../app.svelte';
  import Button from './Button.svelte';
  import Modal from './Modal.svelte';

  const ICONS = { info: Info, warn: TriangleAlert, danger: CircleAlert };

  const dialog = $derived(app.dialog);
  let text = $state('');
  const Icon = $derived(ICONS[dialog?.tone ?? 'info']);
  const ready = $derived(!dialog?.input || (dialog.input.expected ? text === dialog.input.expected : text.trim().length > 0));

  $effect(() => {
    if (dialog) text = '';
  });

  const confirm = () => ready && app.answer(dialog?.input ? text.trim() : '');
  const cancel = () => app.answer(null);
  const onkeydown = (event: KeyboardEvent) => {
    if (event.key === 'Escape' && dialog?.cancel) cancel();
  };
</script>

<svelte:window {onkeydown} />

{#if dialog}
  <Modal title={dialog.title} icon={Icon} tone={dialog.tone}>
    {#if dialog.lines}
      <ul>
        {#each dialog.lines as line (line)}<li>{line}</li>{/each}
      </ul>
    {/if}
    {#if dialog.message}<p class="message">{dialog.message}</p>{/if}
    {#if dialog.code}<pre>{dialog.code}</pre>{/if}

    {#if dialog.input}
      <form
        onsubmit={(event) => {
          event.preventDefault();
          confirm();
        }}
      >
        <label>
          {dialog.input.label}
          <input type="text" bind:value={text} placeholder={dialog.input.placeholder} spellcheck="false" {@attach (input) => input.focus()} />
        </label>
      </form>
    {/if}

    {#snippet actions()}
      {#if dialog.extra}
        {@const extra = dialog.extra}
        <Button variant="ghost" onclick={() => app.answer(extra.id)}>{extra.label}</Button>
      {/if}
      {#if dialog.cancel}<Button variant="ghost" onclick={cancel}>{dialog.cancel}</Button>{/if}
      <Button variant={dialog.tone === 'danger' && dialog.cancel ? 'danger' : 'primary'} disabled={!ready} onclick={confirm}>{dialog.confirm}</Button>
    {/snippet}
  </Modal>
{/if}

<style>
  ul {
    margin: 0;
    padding: var(--space-3) var(--space-3) var(--space-3) var(--space-8);
    border-radius: var(--radius-md);
    background: var(--color-background);
    font-weight: 700;
  }
  .message {
    color: var(--color-textBody);
    font-size: var(--text-md);
    white-space: pre-line;
  }
  pre {
    max-height: var(--size-code);
    margin: 0;
    overflow: auto;
    padding: var(--space-3);
    border-radius: var(--radius-md);
    background: var(--color-console);
    color: var(--color-consoleText);
    font: var(--text-sm) / 1.5 var(--font-mono);
  }
  label {
    display: grid;
    gap: var(--space-1);
    color: var(--color-textMuted);
    font-size: var(--text-sm);
  }
</style>
