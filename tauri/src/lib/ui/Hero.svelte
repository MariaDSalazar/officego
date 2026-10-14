<script lang="ts">
  import Logo from './Logo.svelte';

  let { title, subtitle }: { title: string; subtitle: string } = $props();
</script>

<header class="hero">
  <Logo size="var(--size-heroLogo)" />
  <div>
    <h1>{title}</h1>
    <p>{subtitle}</p>
  </div>
</header>

<style>
  .hero {
    display: flex;
    align-items: center;
    gap: var(--space-5);
    margin-bottom: var(--space-2);
  }
  h1 {
    margin-bottom: var(--space-1);
    font-size: var(--text-3xl);
  }
  p {
    color: var(--color-textMuted);
    font-size: var(--text-lg);
  }
</style>
