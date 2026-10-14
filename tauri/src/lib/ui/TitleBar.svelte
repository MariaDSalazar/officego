<script lang="ts">
  import { Copy, Minus, Monitor, Moon, Square, Sun, X } from '@lucide/svelte';
  import { onMount } from 'svelte';
  import { app } from '../app.svelte';
  import { closeWindow, isMaximized, minimizeWindow, onWindowResized, toggleMaximizeWindow } from '../services/system';
  import Logo from './Logo.svelte';

  const THEME_ICONS = { system: Monitor, light: Sun, dark: Moon };

  const t = $derived(app.t);
  const ThemeIcon = $derived(THEME_ICONS[app.theme]);
  let maximized = $state(false);

  onMount(() => {
    const sync = async () => (maximized = await isMaximized());
    void sync();
    const unlisten = onWindowResized(() => void sync());
    return () => void unlisten.then((stop) => stop());
  });
</script>

<header class="titlebar" data-tauri-drag-region>
  <Logo />
  <span>OfficeGo</span>
  <button class="theme" title={t('window:themeHint')} onclick={app.cycleTheme}>
    <ThemeIcon size={14} />{t(`window:themes.${app.theme}`)}
  </button>
  <button class="caption" aria-label={t('window:minimize')} onclick={minimizeWindow}><Minus size={16} strokeWidth={1.25} /></button>
  <button class="caption" aria-label={t(maximized ? 'window:restore' : 'window:maximize')} onclick={toggleMaximizeWindow}>
    {#if maximized}<Copy size={13} strokeWidth={1.25} />{:else}<Square size={13} strokeWidth={1.25} />{/if}
  </button>
  <button class="caption close" aria-label={t('window:close')} onclick={closeWindow}><X size={16} strokeWidth={1.25} /></button>
</header>

<style>
  .titlebar {
    display: flex;
    flex: none;
    align-items: center;
    gap: var(--space-2);
    height: var(--size-titlebar);
    padding-left: var(--space-4);
    color: var(--color-textMuted);
    font-size: var(--text-sm);
  }
  .titlebar > :not(button) {
    pointer-events: none;
  }
  .theme {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    margin: 0 var(--space-2) 0 auto;
    padding: var(--space-1) var(--space-3);
    border: var(--border-hairline) solid var(--color-line);
    border-radius: var(--radius-pill);
    background: var(--color-panel);
    color: var(--color-textMuted);
    font-size: var(--text-sm);
  }
  .theme:hover {
    color: var(--color-text);
  }
  .caption {
    display: grid;
    place-items: center;
    width: var(--size-caption);
    height: 100%;
    border: none;
    background: none;
    color: var(--color-textMuted);
  }
  .caption:hover {
    background: var(--color-hover);
    color: var(--color-text);
  }
  .close:hover {
    background: var(--color-captionClose);
    color: var(--color-onBrand);
  }
</style>
