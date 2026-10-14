<script lang="ts">
  import Badge from './Badge.svelte';
  import Meter from './Meter.svelte';

  let {
    title,
    subtitle,
    label,
    color,
    rows,
    usage,
  }: {
    title: string;
    subtitle: string;
    label: string;
    color: string;
    rows: [string, string][];
    usage?: { percent: number; color: string; caption: string };
  } = $props();
</script>

<article class="card">
  <header>
    <Badge {label} {color} />
    <div>
      <h4>{title}</h4>
      <p class="subtitle">{subtitle}</p>
    </div>
  </header>
  {#each rows as [name, value] (name)}
    <p class="row">{name} <b>{value}</b></p>
  {/each}
  {#if usage}
    <div class="usage"><Meter percent={usage.percent} color={usage.color} /></div>
    <p class="caption">{usage.caption}</p>
  {/if}
</article>

<style>
  .card {
    padding: var(--space-3);
    border: var(--border-regular) solid var(--color-line);
    border-radius: var(--radius-lg);
    background: var(--color-panel);
  }
  header {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    margin-bottom: var(--space-2);
  }
  h4 {
    font-size: var(--text-md);
  }
  .subtitle,
  .caption {
    color: var(--color-textFaint);
    font-size: var(--text-xs);
  }
  .row {
    display: flex;
    gap: var(--space-2);
    padding: var(--space-1) 0;
    color: var(--color-textBody);
    font-size: var(--text-sm);
  }
  .row b {
    margin-left: auto;
    color: var(--color-text);
    text-align: right;
  }
  .usage {
    margin: var(--space-2) 0 var(--space-1);
  }
</style>
