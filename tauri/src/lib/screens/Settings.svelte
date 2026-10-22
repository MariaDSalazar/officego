<script lang="ts">
  import { RefreshCw } from '@lucide/svelte';
  import { SCREENS, THEMES, app, type Theme } from '../app.svelte';
  import { BASE_LANGUAGE, LANGUAGES } from '../i18n';
  import { shortcutList } from '../shortcuts';
  import Button from '../ui/Button.svelte';
  import SectionTitle from '../ui/SectionTitle.svelte';
  import Segmented from '../ui/Segmented.svelte';

  const ON_START = 'start';
  const BY_HAND = 'hand';

  const t = $derived(app.t);
  const themes = $derived(THEMES.map((theme) => ({ value: theme, label: t(`window:themes.${theme}`) })));
  const ordered = [BASE_LANGUAGE, ...LANGUAGES.filter((language) => language !== BASE_LANGUAGE)];
  const languages = $derived(ordered.map((language) => ({ value: language, label: t(`settings:languages.${language}`) })));
  const checks = $derived([ON_START, BY_HAND].map((value) => ({ value, label: t(`settings:checks.${value}`) })));
  const shortcuts = shortcutList(SCREENS.length);
</script>

<SectionTitle>{t('settings:look')}</SectionTitle>
<div class="row">
  <div class="text">
    <b>{t('settings:theme')}</b>
    <p>{t('settings:themeHint')}</p>
  </div>
  <Segmented label={t('settings:theme')} options={themes} value={app.theme} onchange={(theme) => app.setTheme(theme as Theme)} />
</div>
<div class="row">
  <div class="text">
    <b>{t('settings:language')}</b>
    <p>{t('settings:languageHint')}</p>
  </div>
  <Segmented label={t('settings:language')} options={languages} value={app.language} onchange={app.setLanguage} />
</div>

<SectionTitle>{t('settings:updates')}</SectionTitle>
<div class="row">
  <div class="text">
    <b>{t('settings:version', { version: app.version })}</b>
    <p>{app.update ? t('update:available', { version: app.update.version }) : t('settings:updatesHint')}</p>
  </div>
  <Button variant="ghost" icon={RefreshCw} disabled={app.checkingUpdate || app.updateProgress !== null} onclick={app.checkUpdateNow}>
    {t(app.checkingUpdate ? 'settings:checking' : 'settings:checkNow')}
  </Button>
</div>
<div class="row">
  <div class="text">
    <b>{t('settings:checkWhen')}</b>
    <p>{t('settings:checkWhenHint')}</p>
  </div>
  <Segmented
    label={t('settings:checkWhen')}
    options={checks}
    value={app.checkUpdatesOnStart ? ON_START : BY_HAND}
    onchange={(value) => app.setCheckUpdatesOnStart(value === ON_START)}
  />
</div>

<SectionTitle>{t('settings:shortcuts')}</SectionTitle>
<dl class="keys">
  {#each shortcuts as shortcut (shortcut.label)}
    <div>
      <dt>
        {#each shortcut.keys as key, index (key)}{#if index}<span>+</span>{/if}<kbd>{key}</kbd>{/each}
      </dt>
      <dd>{t(`settings:keys.${shortcut.label}`)}</dd>
    </div>
  {/each}
</dl>

<style>
  .row {
    display: flex;
    align-items: center;
    gap: var(--space-4);
    margin-bottom: var(--space-3);
    padding: var(--space-4);
    border: var(--border-hairline) solid var(--color-line);
    border-radius: var(--radius-xl);
    background: var(--color-raised);
  }
  .text {
    flex: 1;
    min-width: 0;
  }
  b {
    display: block;
    margin-bottom: var(--space-1);
    font-size: var(--text-lg);
    font-weight: 600;
  }
  p {
    color: var(--color-textMuted);
    font-size: var(--text-sm);
  }
  .keys {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: var(--space-3);
    margin: 0;
  }
  .keys div {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    padding: var(--space-3) var(--space-4);
    border: var(--border-hairline) solid var(--color-line);
    border-radius: var(--radius-lg);
  }
  dt {
    display: flex;
    flex: none;
    align-items: center;
    gap: var(--space-1);
    color: var(--color-textFaint);
  }
  kbd {
    padding: var(--space-1) var(--space-2);
    border: var(--border-hairline) solid var(--color-line);
    border-radius: var(--radius-sm);
    background: var(--color-panel);
    color: var(--color-text);
    font: 600 var(--text-sm) var(--font-family);
  }
  dd {
    margin: 0;
    color: var(--color-textMuted);
    font-size: var(--text-sm);
  }
</style>
