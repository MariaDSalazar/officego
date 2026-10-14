<script lang="ts">
  import { Trash2 } from '@lucide/svelte';
  import { app } from '../app.svelte';
  import ActionRow from '../ui/ActionRow.svelte';
  import Notice from '../ui/Notice.svelte';
  import SectionTitle from '../ui/SectionTitle.svelte';

  const t = $derived(app.t);
  const hasOffice = $derived(!!app.report?.office);
</script>

<SectionTitle>{t('tools:maintenance')}</SectionTitle>
<ActionRow
  label="R"
  color="var(--color-accent)"
  title={t('tools:repairTitle')}
  description={t('tools:repairDescription')}
  action={t('tools:run')}
  disabled={app.busy || !hasOffice}
  onclick={app.repair}
/>
<ActionRow
  label="D"
  color="var(--color-success)"
  title={t('tools:offlineTitle')}
  description={t('tools:offlineDescription')}
  action={t('tools:run')}
  disabled={app.busy}
  onclick={app.downloadOffline}
/>
<ActionRow
  label="X"
  color="var(--color-accent)"
  title={t('tools:configurationTitle')}
  description={t('tools:configurationDescription')}
  action={t('tools:view')}
  onclick={app.showConfiguration}
/>
<ActionRow
  label="L"
  color="var(--color-textMuted)"
  title={t('tools:workFolderTitle')}
  description={t('tools:workFolderDescription')}
  action={t('tools:open')}
  onclick={app.openWorkFolder}
/>

<SectionTitle>{t('tools:uninstallSection')}</SectionTitle>
<ActionRow
  icon={Trash2}
  color="var(--color-danger)"
  title={t('tools:uninstallTitle')}
  description={t('tools:uninstallDescription')}
  action={t('tools:uninstallStart')}
  danger
  disabled={app.busy || !hasOffice}
  onclick={app.uninstall}
/>
<Notice tone="error">{t('tools:uninstallNote', { word: t('tools:uninstallWord') })}</Notice>
