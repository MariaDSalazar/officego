<script lang="ts" module>
  export type RingPhase = 'running' | 'done' | 'failed' | 'stopped';
</script>

<script lang="ts">
  import { Check, Pause, X } from '@lucide/svelte';

  const RADIUS = 52;
  const CIRCUMFERENCE = 2 * Math.PI * RADIUS;
  const UNKNOWN_SHARE = 25;
  const ICON_SIZE = 48;

  let { percent, value, caption, phase }: { percent: number | null; value: string; caption: string; phase: RingPhase } = $props();

  const share = $derived(phase === 'done' || phase === 'failed' ? 100 : (percent ?? (phase === 'running' ? UNKNOWN_SHARE : 0)));
</script>

<div class="ring {phase}" role="progressbar" aria-label={caption} aria-valuemin={0} aria-valuemax={100} aria-valuenow={percent ?? undefined}>
  <svg viewBox="0 0 120 120" class:spin={phase === 'running' && percent === null}>
    <circle class="track" cx="60" cy="60" r={RADIUS} />
    <circle class="fill" cx="60" cy="60" r={RADIUS} stroke-dasharray={CIRCUMFERENCE} stroke-dashoffset={CIRCUMFERENCE * (1 - share / 100)} />
  </svg>
  <div class="center">
    {#if phase === 'done'}
      <Check size={ICON_SIZE} />
    {:else if phase === 'failed'}
      <X size={ICON_SIZE} />
    {:else if phase === 'stopped'}
      <Pause size={ICON_SIZE} />
    {:else}
      <b>{value}</b>
    {/if}
    <span>{caption}</span>
  </div>
</div>

<style>
  .ring {
    position: relative;
    width: var(--size-ring);
    height: var(--size-ring);
    --stroke: var(--color-accent);
  }
  .done {
    --stroke: var(--color-success);
  }
  .failed {
    --stroke: var(--color-danger);
  }
  .stopped {
    --stroke: var(--color-warningStrong);
  }
  svg {
    width: 100%;
    height: 100%;
    transform: rotate(-90deg);
  }
  .spin {
    animation: spin 1.4s linear infinite;
  }
  @keyframes spin {
    from {
      transform: rotate(-90deg);
    }
    to {
      transform: rotate(270deg);
    }
  }
  circle {
    fill: none;
    stroke-width: 9;
  }
  .track {
    stroke: var(--color-lineSoft);
  }
  .fill {
    stroke: var(--stroke);
    stroke-linecap: round;
    transition: stroke-dashoffset var(--motion-fast);
  }
  .center {
    position: absolute;
    inset: 0;
    display: grid;
    place-content: center;
    justify-items: center;
    gap: var(--space-1);
    color: var(--stroke);
  }
  b {
    color: var(--color-text);
    font: 600 var(--text-display) / 1 var(--font-display);
    letter-spacing: var(--tracking-tight);
    font-variant-numeric: tabular-nums;
  }
  span {
    color: var(--color-textMuted);
    font-size: var(--text-base);
  }
</style>
