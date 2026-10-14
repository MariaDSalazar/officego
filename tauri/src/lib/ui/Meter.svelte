<script lang="ts">
  let { percent, color = 'var(--color-accent)' }: { percent: number; color?: string } = $props();
</script>

<div class="meter" role="meter" aria-valuenow={percent} aria-valuemin={0} aria-valuemax={100}>
  <i style:width="{Math.min(100, Math.max(0, percent))}%" style:background={color}></i>
</div>

<style>
  .meter {
    height: var(--size-meter);
    overflow: hidden;
    border-radius: var(--radius-pill);
    background: var(--color-lineSoft);
  }
  i {
    display: block;
    height: 100%;
    border-radius: inherit;
  }
</style>
