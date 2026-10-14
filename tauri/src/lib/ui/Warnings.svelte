<script lang="ts">
  import { app } from '../app.svelte';
  import type { WarningLevel } from '../types';
  import Notice from './Notice.svelte';

  const TONES: Record<WarningLevel, 'info' | 'warn' | 'error'> = { info: 'info', warn: 'warn', error: 'error' };

  const t = $derived(app.t);
  const format = $derived(app.format);
  const recommendation = $derived(app.report!.recommendation);
</script>

{#if !recommendation.supported}
  <Notice tone="error">{t('recommendation:unsupported')}</Notice>
{/if}
{#each recommendation.warnings as warning (warning.code)}
  <Notice tone={TONES[warning.level]}>
    {t(`recommendation:warnings.${warning.code}`, {
      ram: format.gigabytes(warning.values.ramGb ?? 0),
      free: format.gigabytes(warning.values.freeGb ?? 0),
      minimum: format.gigabytes(warning.values.minimumGb ?? 0),
      drive: warning.values.drive ?? '',
    })}
  </Notice>
{/each}
