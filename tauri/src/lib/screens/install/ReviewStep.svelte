<script lang="ts">
  import { app } from '../../app.svelte';
  import { downloadSizeGb } from '../../selection';
  import Notice from '../../ui/Notice.svelte';
  import PageTitle from '../../ui/PageTitle.svelte';
  import XmlView from '../../ui/XmlView.svelte';

  const t = $derived(app.t);
  const format = $derived(app.format);
  const catalog = $derived(app.catalog!);
  const product = $derived(app.product!);
  const selection = $derived(app.selection);
  const suite = $derived(product.route === 'c2r');
  const nameOf = (key: string, list: { key: string; name: string }[]) => list.find((item) => item.key === key)?.name ?? key;
  const sentence = $derived(
    t(suite ? 'install:sentenceSuite' : 'install:sentence', {
      product: product.name,
      edition: nameOf(selection.edition, catalog.editions),
      apps: format.list([...selection.apps.map((key) => nameOf(key, catalog.apps)), ...selection.addOns.map((key) => nameOf(key, catalog.addOns))]),
      language: format.officeLanguage(selection.language),
      bits: selection.bits,
    }),
  );

  let xml = $state<string | null>(null);
  let failure = $state('');

  $effect(() => {
    if (suite) return;
    xml = null;
    failure = '';
    app
      .previewConfiguration()
      .then((configuration) => (xml = configuration))
      .catch((error: unknown) => (failure = app.errorText(error)));
  });
</script>

<PageTitle title={t('install:reviewTitle')} />
<div class="columns">
  <div>
    <p class="sentence">{sentence}</p>
    <dl>
      <dt>{t('install:download')}</dt>
      <dd>{t('install:downloadValue', { size: format.gigabytes(downloadSizeGb(catalog, selection)) })}</dd>
      <dt>{t('install:afterwards')}</dt>
      <dd>{t('install:afterwardsValue')}</dd>
    </dl>
    {#if app.report?.office}<Notice tone="warn">{t('install:closeApps')}</Notice>{/if}
  </div>
  {#if suite}
    <div class="classic">
      <b>{t('install:classicTitle')}</b>
      <p>{t('install:classicText', { version: product.key })}</p>
    </div>
  {:else}
    <XmlView {xml} {failure} />
  {/if}
</div>

<style>
  .columns {
    display: grid;
    grid-template-columns: 1fr 1.3fr;
    align-items: start;
    gap: var(--space-6);
  }
  .sentence {
    font: 600 var(--text-2xl) / 1.3 var(--font-display);
  }
  dl {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: var(--space-2) var(--space-4);
    margin: var(--space-5) 0 var(--space-3);
    font-size: var(--text-md);
  }
  dt {
    color: var(--color-textFaint);
  }
  dd {
    margin: 0;
    font-weight: 600;
  }
  .classic {
    display: grid;
    gap: var(--space-2);
    padding: var(--space-4) var(--space-5);
    border: var(--border-hairline) solid var(--color-line);
    border-radius: var(--radius-xl);
    background: var(--color-raised);
  }
  .classic p {
    color: var(--color-textMuted);
    font-size: var(--text-base);
  }
</style>
