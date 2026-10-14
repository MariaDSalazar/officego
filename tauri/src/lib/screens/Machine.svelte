<script lang="ts">
  import { app } from '../app.svelte';
  import HardwareCard from '../ui/HardwareCard.svelte';
  import Notice from '../ui/Notice.svelte';
  import RecommendationCard from '../ui/RecommendationCard.svelte';
  import SectionTitle from '../ui/SectionTitle.svelte';
  import Warnings from '../ui/Warnings.svelte';

  const t = $derived(app.t);
  const format = $derived(app.format);
  const report = $derived(app.report!);
  const machine = $derived(report.machine);
  const graphics = $derived(report.graphics);
  const recommendation = $derived(report.recommendation);
  const minimumFree = $derived(app.catalog!.minimumFreeGb);
</script>

<SectionTitle>{t('home:recommended')}</SectionTitle>
<RecommendationCard />

<SectionTitle>{t('machine:features')}</SectionTitle>
<div class="grid">
  <HardwareCard
    title={t('machine:os')}
    subtitle={machine.os}
    label="OS"
    color="var(--color-accent)"
    rows={[
      [t('machine:build'), machine.build],
      [t('machine:architecture'), machine.architecture],
      [t('machine:powershell'), machine.powershell],
    ]}
  />
  <HardwareCard
    title={t('machine:cpu')}
    subtitle={machine.cpu}
    label="CPU"
    color="var(--color-danger)"
    rows={[
      [t('machine:frequency'), format.gigahertz(machine.cpuGhz)],
      [t('machine:coresThreads'), `${machine.cores} / ${machine.threads}`],
    ]}
    usage={{ percent: machine.cpuLoad, color: 'var(--color-danger)', caption: t('machine:cpuLoad', { load: format.percent(machine.cpuLoad) }) }}
  />
  <HardwareCard
    title={t('machine:ram')}
    subtitle={`${format.gigabytes(machine.ramGb)} ${machine.ramSpeed}`}
    label="RAM"
    color="var(--color-success)"
    rows={[
      [t('machine:modules'), format.number(machine.ramModules)],
      [t('machine:available'), format.gigabytes(machine.ramFreeGb)],
    ]}
    usage={{
      percent: machine.ramLoad,
      color: 'var(--color-success)',
      caption: t('machine:ramUsed', { used: format.gigabytes(machine.ramGb - machine.ramFreeGb) }),
    }}
  />
  <HardwareCard
    title={t('machine:graphics')}
    subtitle={machine.gpu || t('machine:unknownGpu')}
    label={graphics.abbreviation}
    color={graphics.color}
    rows={[
      [t('machine:brand'), t(`machine:brands.${graphics.brand}`)],
      [t('machine:resolution'), machine.resolution],
      [t('machine:acceleration'), t(graphics.old ? 'machine:accelerationOff' : 'machine:accelerationOn')],
    ]}
  />
  {#each machine.disks as disk (disk.letter)}
    <HardwareCard
      title={t('machine:disk', { letter: disk.letter })}
      subtitle={t(disk.system ? 'machine:systemDisk' : 'machine:dataDisk')}
      label={disk.letter}
      color="var(--color-textMuted)"
      rows={[[t('machine:capacity'), format.gigabytes(disk.totalGb)]]}
      usage={{
        percent: disk.usedPercent,
        color: disk.freeGb < minimumFree ? 'var(--color-danger)' : 'var(--color-accent)',
        caption: t('machine:free', { free: format.gigabytes(disk.freeGb) }),
      }}
    />
  {/each}
</div>

<SectionTitle>{t('machine:keepInMind')}</SectionTitle>
<Warnings />
{#if recommendation.supported && !recommendation.warnings.length}
  <Notice tone="ok">{t('machine:allGood')}</Notice>
{/if}

<style>
  .grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: var(--space-3);
  }
</style>
