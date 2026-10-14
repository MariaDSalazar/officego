<script lang="ts">
  import { CircleAlert, Info, TriangleAlert } from '@lucide/svelte';
  import { app } from '../app.svelte';
  import Button from './Button.svelte';

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
  <div class="backdrop">
    <div class="dialog {dialog.tone ?? 'info'}" role="dialog" aria-modal="true" aria-labelledby="dialog-title">
      <header>
        <span class="icon"><Icon size={20} /></span>
        <h2 id="dialog-title">{dialog.title}</h2>
      </header>

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

      <footer>
        {#if dialog.extra}
          {@const extra = dialog.extra}
          <Button variant="ghost" onclick={() => app.answer(extra.id)}>{extra.label}</Button>
        {/if}
        {#if dialog.cancel}<Button variant="ghost" onclick={cancel}>{dialog.cancel}</Button>{/if}
        <Button variant={dialog.tone === 'danger' && dialog.cancel ? 'danger' : 'primary'} disabled={!ready} onclick={confirm}>{dialog.confirm}</Button>
      </footer>
    </div>
  </div>
{/if}

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
  footer {
    display: flex;
    flex-wrap: wrap;
    justify-content: flex-end;
    gap: var(--space-2);
    margin-top: var(--space-2);
  }
</style>
