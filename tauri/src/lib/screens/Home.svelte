<script lang="ts">
  import { ShieldAlert } from '@lucide/svelte';
  import { app } from '../app.svelte';
  import Button from '../ui/Button.svelte';
  import Hero from '../ui/Hero.svelte';
  import Notice from '../ui/Notice.svelte';
  import RecommendationCard from '../ui/RecommendationCard.svelte';
  import SectionTitle from '../ui/SectionTitle.svelte';
  import Warnings from '../ui/Warnings.svelte';

  const STEPS = ['choose', 'pick', 'activate'] as const;

  const t = $derived(app.t);
  const machine = $derived(app.machine!);
  const recommendation = $derived(app.report!.recommendation);
  const clean = $derived(recommendation.supported && !recommendation.warnings.length);
</script>

<Hero title={t('home:title')} subtitle={t('home:subtitle')} />

<SectionTitle>{t('home:recommended')}</SectionTitle>
<RecommendationCard />

<SectionTitle>{t('home:howItWorks')}</SectionTitle>
<div class="steps">
  {#each STEPS as step, index (step)}
    <div class="step">
      <span class="number">{index + 1}</span>
      <b>{t(`home:steps.${step}.title`)}</b>
      <p>{t(`home:steps.${step}.text`)}</p>
    </div>
  {/each}
</div>

<div class="notices">
  <Warnings />
  {#if !machine.admin}
    <div class="admin">
      <div class="grow"><Notice tone="error">{t('home:noAdmin')}</Notice></div>
      <Button variant="danger" icon={ShieldAlert} onclick={app.relaunchAsAdmin}>{t('admin:relaunch')}</Button>
    </div>
  {:else if clean}
    <Notice tone="ok">
      {t('home:ready', { os: machine.os, ram: app.format.gigabytes(machine.ramGb), free: app.format.gigabytes(app.systemDisk?.freeGb ?? 0) })}
    </Notice>
  {/if}
</div>

<style>
  .steps {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: var(--space-3);
  }
  .step {
    padding: var(--space-4);
    border: var(--border-regular) solid var(--color-line);
    border-radius: var(--radius-lg);
    background: var(--color-panel);
    text-align: center;
  }
  .number {
    display: grid;
    place-items: center;
    width: var(--size-badgeMd);
    height: var(--size-badgeMd);
    margin: 0 auto var(--space-2);
    border-radius: var(--radius-round);
    background: var(--color-accentSoft);
    color: var(--color-accent);
    font-size: var(--text-lg);
    font-weight: 700;
  }
  b {
    display: block;
    margin-bottom: var(--space-1);
    font-size: var(--text-md);
  }
  p {
    color: var(--color-textFaint);
    font-size: var(--text-sm);
  }
  .notices {
    margin-top: var(--space-4);
  }
  .admin {
    display: flex;
    align-items: center;
    gap: var(--space-3);
  }
  .grow {
    flex: 1;
  }
</style>
