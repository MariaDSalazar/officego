<script lang="ts">
  import { Check, CircleAlert, Download, KeyRound, LoaderCircle, ShieldAlert, Wrench } from '@lucide/svelte';
  import type { Component } from 'svelte';
  import { app } from '../app.svelte';
  import { describeOffice, officeTitle } from '../office';
  import { productOf } from '../selection';
  import Badge from '../ui/Badge.svelte';
  import Button from '../ui/Button.svelte';
  import Notice from '../ui/Notice.svelte';
  import Warnings from '../ui/Warnings.svelte';
  import Year from '../ui/Year.svelte';

  type Quick = { key: string; icon: Component<{ size?: number }>; needsOffice: boolean; run: () => void };

  const QUICK: Quick[] = [
    { key: 'repair', icon: Wrench, needsOffice: true, run: app.repair },
    { key: 'key', icon: KeyRound, needsOffice: true, run: app.applyKey },
    { key: 'offline', icon: Download, needsOffice: false, run: app.downloadOffline },
  ];
  const LICENSE_ICONS = { checking: LoaderCircle, activated: Check, notActivated: CircleAlert, unreadable: CircleAlert };
  const BITS = { x64: '64', x86: '32' } as Record<string, string>;

  const t = $derived(app.t);
  const catalog = $derived(app.catalog!);
  const machine = $derived(app.machine!);
  const office = $derived(app.report!.office);
  const installed = $derived(office ? describeOffice(catalog, office) : null);
  const title = $derived(installed ? officeTitle(installed, app.format.list, t('home:officeFallback')) : '');
  const license = $derived(app.license);
  const licenseState = $derived(license === undefined ? 'checking' : license?.activated ? 'activated' : license ? 'notActivated' : 'unreadable');
  const state = $derived(!office ? 'empty' : licenseState === 'activated' ? 'ready' : licenseState === 'checking' ? 'checking' : 'inactive');
  const recommendation = $derived(app.report!.recommendation);
  const product = $derived(productOf(catalog, recommendation.product));
  const LicenseIcon = $derived(LICENSE_ICONS[licenseState]);
</script>

<header class="intro">
  <h1>{t(`home:titles.${state}`)}</h1>
  <p>{t('home:subtitle')}</p>
</header>

<div class="cards">
  <section class="card">
    <h2>{t('home:yourOffice')}</h2>
    {#if office && installed}
      {#if installed.apps.length}
        <div class="apps">
          {#each installed.apps as item (item.key)}<Badge label={item.abbreviation} color={item.color} size="xl" />{/each}
        </div>
      {/if}
      <div class="office">
        {#if !installed.apps.length}
          <Badge label={installed.product?.abbreviation ?? t('home:officeBadge')} color={installed.product?.color ?? 'var(--color-accent)'} size="xl" />
        {/if}
        <div class="text">
          <b>{title}</b>
          <span>
            {t('home:officeDetails', {
              version: office.version,
              bits: t('home:bits', { bits: BITS[office.architecture] ?? office.architecture }),
              language: app.format.officeLanguage(office.language),
            })}
          </span>
          {#if installed.addOns.length}<span>{t('home:addOns', { list: app.format.list(installed.addOns) })}</span>{/if}
        </div>
      </div>
      <div class="license {licenseState}">
        <span><LicenseIcon size={16} />{t(`home:license.${licenseState}`)}</span>
        {#if licenseState === 'notActivated' || licenseState === 'unreadable'}
          <Button variant="ghost" onclick={() => app.go('activate')}>{t('home:activateNow')}</Button>
        {/if}
      </div>
    {:else}
      <div class="empty">
        <b>{t('home:noOffice')}</b>
        <p>{t('home:noOfficeHint')}</p>
      </div>
    {/if}
  </section>

  <section class="card fit" class:classic={product.route === 'c2r'}>
    <h2>{t('home:fits')}</h2>
    <div class="pick">
      <Year {product} />
      <div class="text">
        <b>{product.name}</b>
        <p>{t(`recommendation:reasons.${recommendation.reason}`)}</p>
      </div>
    </div>
    <div class="buttons">
      <Button variant={product.route === 'c2r' ? 'caution' : 'primary'} disabled={app.busy} onclick={app.chooseRecommended}>
        {t('home:installProduct', { product: product.name })}
      </Button>
      <Button variant="ghost" onclick={app.startInstall}>{t('home:seeAll')}</Button>
    </div>
  </section>
</div>

<div class="quick">
  {#each QUICK as item (item.key)}
    {@const Icon = item.icon}
    <button class="tile" disabled={app.busy || (item.needsOffice && !office)} onclick={item.run}>
      <Badge icon={Icon} color="var(--color-accent)" size="lg" soft />
      <span class="text">
        <b>{t(`home:quick.${item.key}.title`)}</b>
        <span>{t(`home:quick.${item.key}.text`)}</span>
      </span>
    </button>
  {/each}
</div>

<div class="notices">
  <Warnings />
  {#if !machine.admin}
    <div class="admin">
      <div class="grow"><Notice tone="error">{t('home:noAdmin')}</Notice></div>
      <Button variant="danger" icon={ShieldAlert} onclick={app.relaunchAsAdmin}>{t('admin:relaunch')}</Button>
    </div>
  {/if}
</div>

<style>
  .intro {
    margin-bottom: var(--space-5);
  }
  h1 {
    margin-bottom: var(--space-1);
    font-size: var(--text-3xl);
  }
  .intro p {
    color: var(--color-textMuted);
    font-size: var(--text-lg);
  }
  .cards {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: var(--space-4);
  }
  .card {
    display: grid;
    align-content: start;
    gap: var(--space-4);
    padding: var(--space-5);
    border: var(--border-hairline) solid var(--color-line);
    border-radius: var(--radius-xl);
    background: var(--color-raised);
  }
  h2 {
    color: var(--color-textMuted);
    font-size: var(--text-md);
    font-weight: 500;
  }
  .apps {
    display: flex;
    gap: var(--space-2);
  }
  .office,
  .pick {
    display: flex;
    align-items: center;
    gap: var(--space-4);
  }
  .text {
    display: grid;
    gap: var(--space-1);
    min-width: 0;
  }
  .text b {
    font-size: var(--text-xl);
    font-weight: 600;
  }
  .text span,
  .text p,
  .empty p {
    color: var(--color-textMuted);
    font-size: var(--text-sm);
  }
  .license {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: var(--space-3);
    font-weight: 600;
  }
  .license span {
    display: flex;
    align-items: center;
    gap: var(--space-2);
  }
  .activated {
    color: var(--color-success);
  }
  .checking {
    color: var(--color-textFaint);
  }
  .notActivated,
  .unreadable {
    color: var(--color-warning);
  }
  .empty b {
    display: block;
    margin-bottom: var(--space-1);
    font-size: var(--text-xl);
    font-weight: 600;
  }
  .fit {
    border-color: var(--color-accentLine);
    background: var(--color-accentTint);
  }
  .fit.classic {
    border-color: var(--color-warningStrong);
    background: var(--color-warningSoft);
  }
  .buttons {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-2);
  }
  .quick {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: var(--space-3);
    margin-top: var(--space-4);
  }
  .tile {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    padding: var(--space-4);
    border: var(--border-hairline) solid var(--color-line);
    border-radius: var(--radius-xl);
    background: var(--color-panel);
    text-align: left;
    transition:
      border-color var(--motion-fast),
      transform var(--motion-fast);
  }
  .tile .text b {
    font-size: var(--text-md);
  }
  .tile:hover:not(:disabled) {
    border-color: var(--color-accentHover);
  }
  .tile:active:not(:disabled) {
    transform: translateY(var(--border-hairline));
  }
  .tile:disabled {
    opacity: 0.45;
    cursor: default;
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
