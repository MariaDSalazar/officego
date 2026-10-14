<script lang="ts">
  import { app } from '../../app.svelte';
  import { addOnAvailable, editionName as nameOfEdition } from '../../selection';
  import AppTile from '../../ui/AppTile.svelte';
  import PageTitle from '../../ui/PageTitle.svelte';
  import SectionTitle from '../../ui/SectionTitle.svelte';
  import Segmented from '../../ui/Segmented.svelte';

  const BITS = ['64', '32'];
  const MOST_SEGMENTS = 2;

  const t = $derived(app.t);
  const format = $derived(app.format);
  const catalog = $derived(app.catalog!);
  const product = $derived(app.product!);
  const selection = $derived(app.selection);
  const suite = $derived(product.route === 'c2r');
  const addOns = $derived(catalog.addOns.filter((addOn) => addOnAvailable(catalog, addOn.key, product.key)));
  const editionApps = $derived(catalog.editions.find((edition) => edition.key === selection.edition)?.apps ?? []);
  const editionName = (key: string) => nameOfEdition(catalog, key);
</script>

<PageTitle
  title={t(suite ? 'install:suiteTitle' : 'install:appsTitle')}
  lead={suite ? t('install:suiteLead', { version: product.key }) : t('install:appsLead')}
/>

<div class="fields">
  <div class="field">
    <span>{t('install:edition')}</span>
    {#if product.editions.length <= MOST_SEGMENTS}
      <Segmented
        label={t('install:edition')}
        options={product.editions.map((edition) => ({ value: edition, label: editionName(edition) }))}
        value={selection.edition}
        disabled={app.busy}
        onchange={(edition) => app.choose({ edition })}
      />
    {:else}
      <select
        aria-label={t('install:edition')}
        value={selection.edition}
        disabled={app.busy}
        onchange={(event) => app.choose({ edition: event.currentTarget.value })}
      >
        {#each product.editions as edition (edition)}<option value={edition}>{editionName(edition)}</option>{/each}
      </select>
    {/if}
  </div>
  <div class="field">
    <span>{t('install:language')}</span>
    <select
      aria-label={t('install:language')}
      value={selection.language}
      disabled={app.busy}
      onchange={(event) => app.choose({ language: event.currentTarget.value })}
    >
      {#each catalog.languages as language (language)}<option value={language}>{format.officeLanguage(language)}</option>{/each}
    </select>
  </div>
  <div class="field">
    <span>{t('install:bits')}</span>
    <Segmented
      label={t('install:bits')}
      options={BITS.map((bits) => ({ value: bits, label: t('install:bitsOption', { bits }) }))}
      value={selection.bits}
      disabled={app.busy}
      onchange={(bits) => app.choose({ bits })}
    />
  </div>
</div>

{#if suite}
  <SectionTitle>{t('install:includes', { edition: editionName(selection.edition) })}</SectionTitle>
  <div class="grid">
    {#each catalog.apps.filter((officeApp) => editionApps.includes(officeApp.key)) as officeApp (officeApp.key)}
      <AppTile
        label={officeApp.abbreviation}
        color={officeApp.color}
        name={officeApp.name}
        detail={t(`install:appDescriptions.${officeApp.key}`)}
        selected
        readonly
      />
    {/each}
  </div>
{:else}
  <SectionTitle>{t('install:apps')}</SectionTitle>
  <div class="grid">
    {#each catalog.apps as officeApp (officeApp.key)}
      {@const available = app.pickableApps.includes(officeApp.key)}
      <AppTile
        label={officeApp.abbreviation}
        color={officeApp.color}
        name={officeApp.name}
        detail={available ? t(`install:appDescriptions.${officeApp.key}`) : t('install:notInEdition', { edition: editionName(selection.edition) })}
        {available}
        selected={available && selection.apps.includes(officeApp.key)}
        onclick={() => app.toggleApp(officeApp.key)}
      />
    {/each}
  </div>
{/if}

{#if addOns.length}
  <SectionTitle>{t('install:addOns')}</SectionTitle>
  <div class="grid">
    {#each addOns as addOn (addOn.key)}
      <AppTile
        label={addOn.abbreviation}
        color={addOn.color}
        name={addOn.name}
        detail={t('install:addOnWeight', { size: format.gigabytes(catalog.addOnWeightGb) })}
        selected={selection.addOns.includes(addOn.key)}
        onclick={() => app.toggleAddOn(addOn.key)}
      />
    {/each}
  </div>
{/if}

<style>
  .fields {
    display: grid;
    grid-template-columns: 1.3fr 1fr 0.9fr;
    gap: var(--space-3);
  }
  .field {
    display: grid;
    align-content: start;
    gap: var(--space-2);
  }
  .field > span {
    color: var(--color-textFaint);
    font-size: var(--text-sm);
  }
  .field select {
    height: 100%;
  }
  .grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: var(--space-2);
  }
</style>
