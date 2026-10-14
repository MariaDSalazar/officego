<script lang="ts">
  import { Check, Code, Copy } from '@lucide/svelte';
  import { app } from '../app.svelte';
  import { highlightXml } from '../xml';

  const COPIED_FOR_MS = 2000;

  let { xml, failure }: { xml: string | null; failure: string } = $props();

  const t = $derived(app.t);
  const tokens = $derived(xml ? highlightXml(xml.trim()) : []);
  let copied = $state(false);

  const copy = async () => {
    if (!xml) return;
    await app.copy(xml);
    copied = true;
    setTimeout(() => (copied = false), COPIED_FOR_MS);
  };
</script>

<section class="xml">
  <header>
    <Code size={16} />
    <b>configuration.xml</b>
    <span>{t('install:xmlHint')}</span>
    <button disabled={!xml} onclick={copy}>
      {#if copied}<Check size={14} />{t('install:copied')}{:else}<Copy size={14} />{t('install:copy')}{/if}
    </button>
  </header>
  {#if failure}
    <p class="failure">{t('install:xmlFailed', { detail: failure })}</p>
  {:else if xml}
    <pre>{#each tokens as token, index (index)}<span class={token.kind}>{token.text}</span>{/each}</pre>
  {:else}
    <div class="loading">
      {#each { length: 6 }, line (line)}<i></i>{/each}
    </div>
  {/if}
</section>

<style>
  .xml {
    display: flex;
    flex-direction: column;
    min-width: 0;
    overflow: hidden;
    border: var(--border-hairline) solid var(--color-line);
    border-radius: var(--radius-xl);
    background: var(--color-raised);
  }
  header {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-2) var(--space-3) var(--space-2) var(--space-4);
    border-bottom: var(--border-hairline) solid var(--color-line);
    color: var(--color-textMuted);
    font-size: var(--text-sm);
  }
  header b {
    color: var(--color-text);
  }
  header span {
    flex: 1;
    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  button {
    display: flex;
    align-items: center;
    gap: var(--space-1);
    padding: var(--space-1) var(--space-3);
    border: var(--border-hairline) solid var(--color-line);
    border-radius: var(--radius-md);
    background: var(--color-panel);
    color: var(--color-text);
    font-size: var(--text-sm);
  }
  button:disabled {
    opacity: 0.45;
    cursor: default;
  }
  pre {
    max-height: var(--size-code);
    margin: 0;
    overflow: auto;
    padding: var(--space-3) var(--space-4);
    color: var(--color-text);
    font: var(--text-xs) / 1.65 var(--font-mono);
    user-select: text;
  }
  .tag {
    color: var(--color-accent);
  }
  .attr {
    color: var(--color-warning);
  }
  .value {
    color: var(--color-success);
  }
  .punct {
    color: var(--color-textFaint);
  }
  .failure {
    padding: var(--space-4);
    color: var(--color-danger);
    font-size: var(--text-sm);
  }
  .loading {
    display: grid;
    gap: var(--space-3);
    padding: var(--space-4);
  }
  .loading i {
    height: var(--space-2);
    border-radius: var(--radius-pill);
    background: var(--color-line);
    animation: pulse 1.2s ease-in-out infinite alternate;
  }
  .loading i:nth-child(even) {
    width: 70%;
  }
  @keyframes pulse {
    to {
      opacity: 0.4;
    }
  }
</style>
