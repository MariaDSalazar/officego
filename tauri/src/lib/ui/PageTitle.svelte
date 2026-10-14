<script lang="ts">
  let { title, lead }: { title: string; lead?: string } = $props();
</script>

<header>
  <h1>{title}</h1>
  {#if lead}<p>{lead}</p>{/if}
</header>

<style>
  header {
    margin-bottom: var(--space-5);
  }
  h1 {
    font-size: var(--text-3xl);
    line-height: 1.2;
  }
  p {
    margin-top: var(--space-1);
    color: var(--color-textMuted);
    font-size: var(--text-lg);
  }
</style>
