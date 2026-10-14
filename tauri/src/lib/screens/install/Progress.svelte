<script lang="ts">
  import { Check } from '@lucide/svelte';
  import { onMount } from 'svelte';
  import { DOWNLOAD_STEPS, app } from '../../app.svelte';
  import { chosenNames, editionName, productOf } from '../../selection';
  import PageTitle from '../../ui/PageTitle.svelte';
  import ProgressRing, { type RingPhase } from '../../ui/ProgressRing.svelte';

  type StepStatus = 'done' | 'now' | 'failed' | 'stopped' | 'pending';

  const TICK_MS = 1000;
  const MS_PER_SECOND = 1000;
  const SECONDS_PER_MINUTE = 60;
  const MB_PER_GB = 1024;

  const t = $derived(app.t);
  const format = $derived(app.format);
  const catalog = $derived(app.catalog!);
  const job = $derived(app.installJob!);
  const task = $derived(job.task.action === 'download' ? job.task : job.task.action === 'install' ? job.task : null);
  const selection = $derived(task?.selection ?? app.selection);
  const product = $derived(productOf(catalog, selection.product));
  const phase = $derived<RingPhase>(job.endedAt === null ? 'running' : job.outcome?.ok ? 'done' : job.outcome?.reason === 'stopped' ? 'stopped' : 'failed');
  const current = $derived(job.step ? job.steps.indexOf(job.step) : -1);
  let now = $state(Date.now());

  onMount(() => {
    const timer = setInterval(() => (now = Date.now()), TICK_MS);
    return () => clearInterval(timer);
  });

  const size = (mb: number) => (mb >= MB_PER_GB ? format.gigabytes(mb / MB_PER_GB) : format.megabytes(mb));

  const statusOf = (index: number): StepStatus => {
    if (index < current || phase === 'done') return 'done';
    if (index > current) return 'pending';
    return phase === 'running' ? 'now' : phase === 'stopped' ? 'stopped' : 'failed';
  };

  /** Seconds a step took, or has taken so far; nothing for a step not reached. */
  const secondsOf = (index: number) => {
    const began = job.began[job.steps[index]];
    if (began === undefined) return null;
    const next = job.steps.slice(index + 1).map((step) => job.began[step]);
    const ended = next.find((value) => value !== undefined) ?? (job.endedAt ?? now) - job.startedAt;
    return Math.max(0, Math.floor((ended - began) / MS_PER_SECOND));
  };

  const choice = $derived(
    product.route === 'c2r'
      ? t('progress:choiceSuite', { edition: editionName(catalog, selection.edition) })
      : t('progress:choice', { edition: editionName(catalog, selection.edition), apps: format.list(chosenNames(catalog, selection)) }),
  );
  const lead = $derived.by(() => {
    if (phase === 'running') return t(`progress:leads.${job.task.action}.running`, { choice });
    if (phase === 'done') return t(`progress:leads.${job.task.action}.done`, { folder: job.task.action === 'download' ? job.task.folder : '' });
    if (phase === 'stopped') return t('progress:leads.stopped');
    return job.error || (job.outcome ? app.reasonText(job.outcome) : '');
  });
  const detail = $derived.by(() => {
    const download = job.download;
    if (!download) return '';
    const done = size(download.doneMb);
    const total = size(download.totalMb);
    if (!job.speed || job.speed <= 0) return t('progress:downloaded', { done, total });
    const seconds = (download.totalMb - download.doneMb) / job.speed;
    const remaining = seconds < SECONDS_PER_MINUTE ? t('progress:remainingSoon') : t('progress:remaining', { count: Math.ceil(seconds / SECONDS_PER_MINUTE) });
    return t('progress:detail', { done, total, speed: format.speed(job.speed), remaining });
  });
  const hintOf = (index: number) => {
    const step = job.steps[index];
    if (statusOf(index) === 'now' && detail && DOWNLOAD_STEPS.includes(step)) return detail;
    if (step === 'install' && product.route === 'c2r') return t('progress:steps.install.hintSuite');
    return t(`progress:steps.${step}.hint`);
  };
  const ringValue = $derived(job.download ? format.percent(job.download.percent) : format.clock(secondsOf(Math.max(current, 0)) ?? 0));
</script>

<PageTitle title={t(`progress:titles.${job.task.action}.${phase}`, { product: product.name })} {lead} />

<div class="stage">
  <ProgressRing
    {phase}
    percent={job.download?.percent ?? null}
    value={ringValue}
    caption={t(`progress:ring.${phase === 'running' ? (job.step ?? 'starting') : phase}`)}
  />
  <ol>
    {#each job.steps as step, index (step)}
      {@const status = statusOf(index)}
      {@const seconds = secondsOf(index)}
      <li class={status}>
        <i
          >{#if status === 'done'}<Check size={12} strokeWidth={3} />{/if}</i
        >
        <div class="text">
          <b>{t(`progress:steps.${step}.title`)}</b>
          <span>{hintOf(index)}</span>
          {#if status === 'now' && job.download}
            <div class="bar"><i style:width="{job.download.percent}%"></i></div>
          {/if}
        </div>
        <em>{seconds === null ? '' : format.clock(seconds)}</em>
      </li>
    {/each}
  </ol>
</div>

<style>
  .stage {
    display: grid;
    grid-template-columns: var(--size-ring) 1fr;
    align-items: center;
    gap: var(--space-8);
    margin-top: var(--space-4);
  }
  ol {
    display: grid;
    gap: var(--space-1);
    margin: 0;
    padding: 0;
    list-style: none;
  }
  li {
    display: flex;
    align-items: center;
    gap: var(--space-4);
    padding: var(--space-3) var(--space-4);
    border: var(--border-hairline) solid transparent;
    border-radius: var(--radius-lg);
    color: var(--color-textFaint);
  }
  li > i {
    display: grid;
    flex: none;
    place-items: center;
    width: var(--size-badgeSm);
    height: var(--size-badgeSm);
    border: var(--border-strong) solid var(--color-line);
    border-radius: var(--radius-round);
  }
  .text {
    display: grid;
    flex: 1;
    gap: var(--space-1);
    min-width: 0;
  }
  b {
    font-weight: 600;
  }
  .text span {
    font-size: var(--text-sm);
  }
  em {
    font-size: var(--text-sm);
    font-style: normal;
    font-variant-numeric: tabular-nums;
  }
  .done {
    color: var(--color-textMuted);
  }
  .done b {
    color: var(--color-text);
  }
  .done > i {
    border-color: var(--color-success);
    background: var(--color-success);
    color: var(--color-panel);
  }
  .now,
  .failed,
  .stopped {
    border-color: var(--color-line);
    background: var(--color-raised);
    color: var(--color-textMuted);
  }
  .now b,
  .failed b,
  .stopped b {
    color: var(--color-text);
  }
  .now > i {
    border-color: var(--color-accent);
    border-right-color: transparent;
    animation: spin 0.9s linear infinite;
  }
  .failed > i {
    border-color: var(--color-danger);
  }
  .stopped > i {
    border-color: var(--color-warningStrong);
  }
  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }
  .bar {
    height: var(--size-bar);
    margin-top: var(--space-1);
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
</style>
