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
    margin-bottom: var(--space-4);
    padding: var(--space-6);
    border-radius: var(--radius-xl);
    background: linear-gradient(135deg, var(--color-accent), var(--color-accentBright));
    color: var(--color-textOnAccent);
  }
  .hero :global(img) {
    padding: var(--space-1);
    border-radius: var(--radius-xl);
    background: var(--color-glass);
  }
  h1 {
    margin-bottom: var(--space-1);
    font-size: var(--text-3xl);
  }
  p {
    font-size: var(--text-md);
    opacity: 0.9;
  }
</style>
