<script lang="ts">
  import { Check, CircleAlert } from '@lucide/svelte';
  import { app } from '../app.svelte';
  import ActionRow from '../ui/ActionRow.svelte';
  import Badge from '../ui/Badge.svelte';
  import Button from '../ui/Button.svelte';
  import Notice from '../ui/Notice.svelte';
  import SectionTitle from '../ui/SectionTitle.svelte';

  const t = $derived(app.t);
  const license = $derived(app.license);
  const activated = $derived(!!license?.activated);
  const state = $derived(
    license === undefined ? 'checking' : activated ? 'activated' : license ? 'notActivated' : app.report?.office ? 'unreadable' : 'noOffice',
  );
</script>

<SectionTitle>{t('activate:status')}</SectionTitle>
<div class="status">
  <Badge icon={activated ? Check : CircleAlert} color={activated ? 'var(--color-success)' : 'var(--color-danger)'} size="lg" soft />
  <div class="text">
    <h4>{t(`activate:states.${state}`)}</h4>
    <p>{license?.name || t(`activate:stateHints.${state}`)}</p>
  </div>
  <Button variant="ghost" disabled={license === undefined} onclick={app.refreshLicense}>{t('activate:check')}</Button>
</div>

<SectionTitle>{t('activate:how')}</SectionTitle>
<ActionRow
  label="K"
  color="var(--color-accent)"
  title={t('activate:keyTitle')}
  description={t('activate:keyDescription')}
  action={t('activate:use')}
  disabled={app.busy}
  onclick={app.applyKey}
/>
<ActionRow
  label="M"
  color="var(--color-mas)"
  title={t('activate:masTitle')}
  description={t('activate:masDescription')}
  action={t('activate:use')}
  disabled={app.busy}
  onclick={app.activateWithMas}
/>

{#if app.machine?.defender}
  <Notice tone="warn">{t('activate:defender')}</Notice>
{:else if app.machine?.defender === null}
  <Notice tone="warn">{t('activate:defenderUnknown')}</Notice>
{/if}
<Notice>{t('activate:legal')}</Notice>

<style>
  .status {
    display: flex;
    align-items: center;
    gap: var(--space-4);
    padding: var(--space-4);
    border: var(--border-hairline) solid var(--color-line);
    border-radius: var(--radius-xl);
    background: var(--color-raised);
  }
  .text {
    flex: 1;
  }
  h4 {
    margin-bottom: var(--space-1);
    font-size: var(--text-lg);
  }
  p {
    color: var(--color-textMuted);
    font-size: var(--text-sm);
  }
</style>
