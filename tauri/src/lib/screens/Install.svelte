<script lang="ts">
  import { app } from '../app.svelte';
  import { addOnAvailable, downloadSizeGb } from '../selection';
  import Choice from '../ui/Choice.svelte';
  import Notice from '../ui/Notice.svelte';
  import ProductTile from '../ui/ProductTile.svelte';
  import SectionTitle from '../ui/SectionTitle.svelte';

  const BITS = ['64', '32'];

  const t = $derived(app.t);
  const format = $derived(app.format);
  const catalog = $derived(app.catalog!);
  const product = $derived(app.product!);
  const selection = $derived(app.selection);
  const wholeSuite = $derived(product.route === 'c2r');
  const editionName = (key: string) => catalog.editions.find((edition) => edition.key === key)?.name ?? key;
  const summary = $derived<[string, string][]>([
    [t('install:product'), product.name],
    [t('install:edition'), editionName(selection.edition)],
    [t('install:apps'), wholeSuite ? t('install:allApps') : t('install:appsCount', { count: selection.apps.length, total: app.pickableApps.length })],
    [t('install:channel'), product.channel || t('install:clickToRun')],
    [t('install:source'), t('install:microsoftCdn')],
  ]);
</script>

<div class="columns">
  <div class="choices">
    <SectionTitle>{t('install:chooseVersion')}</SectionTitle>
    <div class="products">
      {#each catalog.products as candidate (candidate.key)}
        <ProductTile product={candidate} selected={candidate.key === selection.product} onclick={() => app.choose({ product: candidate.key })} />
      {/each}
    </div>

    <SectionTitle>{t('install:editionLanguageBits')}</SectionTitle>
    <div class="fields">
      <select
        aria-label={t('install:edition')}
        value={selection.edition}
        disabled={app.busy}
        onchange={(event) => app.choose({ edition: event.currentTarget.value })}
      >
        {#each product.editions as edition (edition)}<option value={edition}>{editionName(edition)}</option>{/each}
      </select>
      <select
        aria-label={t('install:language')}
        value={selection.language}
        disabled={app.busy}
        onchange={(event) => app.choose({ language: event.currentTarget.value })}
      >
        {#each catalog.languages as language (language)}<option value={language}>{format.officeLanguage(language)}</option>{/each}
      </select>
      <select aria-label={t('install:bits')} value={selection.bits} disabled={app.busy} onchange={(event) => app.choose({ bits: event.currentTarget.value })}>
        {#each BITS as bits (bits)}<option value={bits}>{t('install:bitsOption', { bits })}</option>{/each}
      </select>
    </div>

    <SectionTitle>{t('install:apps')}</SectionTitle>
    {#if wholeSuite}
      <Notice tone="warn">{t('install:wholeSuiteNote', { version: product.key })}</Notice>
    {:else}
      <div class="chips">
        {#each catalog.apps as officeApp (officeApp.key)}
          {@const available = app.pickableApps.includes(officeApp.key)}
          <Choice
            label={officeApp.abbreviation}
            color={officeApp.color}
            name={officeApp.name}
            {available}
            disabled={app.busy}
            selected={available && selection.apps.includes(officeApp.key)}
            onclick={() => app.toggleApp(officeApp.key)}
          />
        {/each}
      </div>
    {/if}

    <SectionTitle>{t('install:addOns')}</SectionTitle>
    <div class="chips">
      {#each catalog.addOns as addOn (addOn.key)}
        {@const available = addOnAvailable(catalog, addOn.key, product.key)}
        <Choice
          label={addOn.abbreviation}
          color={addOn.color}
          name={addOn.name}
          {available}
          disabled={app.busy}
          selected={available && selection.addOns.includes(addOn.key)}
          onclick={() => app.toggleAddOn(addOn.key)}
        />
      {/each}
    </div>
  </div>

  <aside>
    <SectionTitle>{t('install:summary')}</SectionTitle>
    <div class="summary">
      <p class="size"><b>{format.gigabytes(downloadSizeGb(catalog, selection))}</b>{t('install:downloadSize')}</p>
      <table>
        <tbody>
          {#each summary as [name, value] (name)}
            <tr><td>{name}</td><td>{value}</td></tr>
          {/each}
        </tbody>
      </table>
    </div>
    <Notice>{t('install:editionNote')}</Notice>
  </aside>
</div>

<style>
  .columns {
    display: flex;
    gap: var(--space-4);
  }
  .choices {
    flex: 1.35;
    min-width: 0;
  }
  aside {
    flex: 1;
  }
  .products {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: var(--space-2);
  }
  .fields {
    display: grid;
    grid-template-columns: 1fr 1fr 0.7fr;
    gap: var(--space-2);
  }
  .chips {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-2);
  }
  .summary {
    padding: var(--space-3);
    border: var(--border-regular) solid var(--color-line);
    border-radius: var(--radius-lg);
    background: var(--color-panel);
  }
  .size {
    display: grid;
    padding: var(--space-2) 0 var(--space-1);
    color: var(--color-textFaint);
    font-size: var(--text-sm);
    text-align: center;
  }
  .size b {
    color: var(--color-accent);
    font-size: var(--text-3xl);
  }
  table {
    width: 100%;
    border-collapse: collapse;
    font-size: var(--text-sm);
  }
  td {
    padding: var(--space-2) 0;
    border-bottom: var(--border-hairline) solid var(--color-lineFaint);
    color: var(--color-textBody);
  }
  td:last-child {
    color: var(--color-text);
    font-weight: 700;
    text-align: right;
  }
  tr:last-child td {
    border: none;
  }
</style>
