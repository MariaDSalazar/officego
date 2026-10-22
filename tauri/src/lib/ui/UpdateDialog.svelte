<script lang="ts">
  import { Download, ExternalLink, Sparkles } from '@lucide/svelte';
  import { app } from '../app.svelte';
  import Button from './Button.svelte';
  import Modal from './Modal.svelte';

  const t = $derived(app.t);
  const release = $derived(app.update);
  const downloading = $derived(app.updateProgress !== null);
  const onkeydown = (event: KeyboardEvent) => {
    if (event.key === 'Escape' && app.updateVisible) app.closeUpdate();
  };
  const done = $derived((app.updateProgress ?? 0) * 100);
</script>

<svelte:window {onkeydown} />

{#if app.updateVisible && release}
  <Modal title={t('update:title', { version: release.version })} icon={Sparkles}>
    <p class="versions">{t(release.installable ? 'update:versions' : 'update:portable', { current: app.version, version: release.version })}</p>

    {#if release.highlights.length}
      <ul>
        {#each release.highlights as highlight (highlight)}<li>{highlight}</li>{/each}
      </ul>
    {/if}

    {#if downloading}
      <p class="status">{t('update:downloading', { percent: app.format.percent(done) })}</p>
      <div class="bar"><i style:width="{done}%"></i></div>
      <p class="hint">{t('update:installHint')}</p>
    {:else if app.updateError}
      <p class="error">{app.updateError}</p>
    {/if}

    {#snippet actions()}
      {#if !downloading}
        <Button variant="ghost" icon={ExternalLink} onclick={() => app.openLink(release.notesUrl)}>{t('update:notes')}</Button>
        <Button variant="ghost" onclick={app.skipUpdate}>{t('update:later')}</Button>
        <Button icon={Download} onclick={app.installUpdate}>{t(release.installable ? 'update:now' : 'update:download')}</Button>
      {/if}
    {/snippet}
  </Modal>
{/if}

<style>
  .versions {
    color: var(--color-textBody);
    font-size: var(--text-md);
  }
  ul {
    display: grid;
    gap: var(--space-2);
    margin: 0;
    padding: var(--space-3) var(--space-3) var(--space-3) var(--space-8);
    border-radius: var(--radius-md);
    background: var(--color-background);
    color: var(--color-textBody);
  }
  li::marker {
    color: var(--color-accent);
  }
  .status {
    font-weight: 600;
  }
  .bar {
    height: var(--size-bar);
    overflow: hidden;
    border-radius: var(--radius-pill);
    background: var(--color-lineSoft);
  }
  .bar i {
    display: block;
    height: 100%;
    border-radius: inherit;
    background: var(--color-accent);
    transition: width var(--motion-fast);
  }
  .hint {
    color: var(--color-textMuted);
    font-size: var(--text-sm);
  }
  .error {
    color: var(--color-danger);
    font-size: var(--text-sm);
  }
</style>
