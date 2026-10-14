<script lang="ts">
  let { size = 'var(--size-logo)' }: { size?: string } = $props();
</script>

<img src="/logo.svg" alt="" style:width={size} style:height={size} />
