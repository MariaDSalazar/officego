<script lang="ts">
  import { ChevronLeft, Download, RefreshCw } from '@lucide/svelte';
  import type { Component } from 'svelte';
  import { app, type InstallStep, type Screen } from './lib/app.svelte';
  import { applyTokens } from './lib/design/theme';
  import { LINKS } from './lib/project';
  import Activate from './lib/screens/Activate.svelte';
  import Help from './lib/screens/Help.svelte';
  import Home from './lib/screens/Home.svelte';
  import Install from './lib/screens/Install.svelte';
  import Machine from './lib/screens/Machine.svelte';
  import Tools from './lib/screens/Tools.svelte';
  import { applyMica, setWindowTheme, supportsMica } from './lib/services/system';
  import Button from './lib/ui/Button.svelte';
  import Dialog from './lib/ui/Dialog.svelte';
  import Notice from './lib/ui/Notice.svelte';
  import Sidebar from './lib/ui/Sidebar.svelte';
  import TitleBar from './lib/ui/TitleBar.svelte';

  type Action = { key: string; primary?: boolean; back?: boolean; icon?: Component<{ size?: number }>; shown?: () => boolean; run: () => void };

  const VIEWS: Record<Screen, Component> = { home: Home, install: Install, activate: Activate, machine: Machine, tools: Tools, help: Help };
  const ACTIONS: Record<Screen, Action[]> = {
    home: [
      { key: 'seeMachine', run: () => app.go('machine') },
      { key: 'start', primary: true, run: app.startInstall },
    ],
    install: [],
    activate: [{ key: 'checkLicense', run: app.refreshLicense }],
    machine: [
      { key: 'refresh', run: app.refreshMachine },
      { key: 'copyReport', run: app.copyReport },
    ],
    tools: [],
    help: [{ key: 'viewCode', run: () => app.openLink(LINKS.repository) }],
  };
  const INSTALL_ACTIONS: Record<InstallStep, Action[]> = {
    version: [{ key: 'chooseApps', primary: true, run: () => (app.installStep = 'apps') }],
    apps: [
      { key: 'backToVersion', back: true, run: () => (app.installStep = 'version') },
      { key: 'review', primary: true, run: () => (app.installStep = 'review') },
    ],
    review: [
      { key: 'backToApps', back: true, run: () => (app.installStep = 'apps') },
      { key: 'downloadOnly', shown: () => app.product?.route === 'odt', run: app.downloadOffline },
      { key: 'installNow', primary: true, icon: Download, run: app.install },
    ],
  };

  const t = $derived(app.t);
  const View = $derived(VIEWS[app.screen]);
  const actions = $derived((app.screen === 'install' ? INSTALL_ACTIONS[app.installStep] : ACTIONS[app.screen]).filter((action) => action.shown?.() ?? true));
  const note = $derived(app.screen === 'install' && !app.busy && app.installNote ? app.installNote : app.status);
  let main = $state<HTMLElement>();

  $effect(() => {
    void [app.screen, app.installStep];
    main?.scrollTo({ top: 0 });
  });

  $effect.pre(() => applyTokens(app.dark));
  $effect(() => void setWindowTheme(app.theme === 'system' ? null : app.theme));

  void supportsMica().then(async (supported) => {
    if (!supported) return;
    await applyMica();
    document.documentElement.dataset.backdrop = 'mica';
  });

  void app.load();
</script>

<div class="window">
  <TitleBar />
  <div class="body">
    <Sidebar />
    <section class="card">
      <main bind:this={main}>
        {#if app.loadError}
          <Notice tone="error"><b>{t('errors:loadTitle')}</b> {app.loadError}</Notice>
        {:else if app.ready}
          <View />
        {:else}
          <div class="loading"><RefreshCw size={28} class="spin" />{t('common:checking')}</div>
        {/if}
      </main>

      <footer>
        {#if app.ready}
          {#each actions.filter((action) => action.back) as action (action.key)}
            <Button variant="ghost" icon={ChevronLeft} disabled={app.busy} onclick={action.run}>{t(`actions:${action.key}`)}</Button>
          {/each}
        {/if}
        <div class="progress">
          {#if app.busy}
            <div class="bar" class:unknown={app.progress === null}><i style:width="{app.progress ?? 100}%"></i></div>
          {/if}
          <p aria-live="polite">{note}</p>
        </div>
        {#if app.ready}
          {#each actions.filter((action) => !action.back) as action (action.key)}
            <Button variant={action.primary ? 'primary' : 'ghost'} icon={action.icon} disabled={app.busy} onclick={action.run}>
              {t(`actions:${action.key}`)}
            </Button>
          {/each}
        {/if}
      </footer>
    </section>
  </div>
</div>

<Dialog />

<style>
  .window {
    display: flex;
    flex-direction: column;
    height: 100%;
  }
  .body {
    display: flex;
    flex: 1;
    min-height: 0;
  }
  .card {
    display: flex;
    flex: 1;
    flex-direction: column;
    min-width: 0;
    margin: 0 var(--space-3) var(--space-3) 0;
    overflow: hidden;
    border: var(--border-hairline) solid var(--color-line);
    border-radius: var(--radius-xl);
    background: var(--color-panel);
    box-shadow: var(--shadow-card);
  }
  main {
    flex: 1;
    overflow-y: auto;
    padding: var(--space-6) var(--space-8);
  }
  .loading {
    display: grid;
    justify-items: center;
    gap: var(--space-3);
    padding: var(--space-10);
    color: var(--color-textFaint);
    font-size: var(--text-md);
  }
  .loading :global(.spin) {
    color: var(--color-accent);
    animation: spin 0.8s linear infinite;
  }
  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }
  footer {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    min-height: var(--size-footer);
    padding: var(--space-3) var(--space-8);
    border-top: var(--border-hairline) solid var(--color-lineSoft);
  }
  .progress {
    display: grid;
    flex: 1;
    gap: var(--space-2);
    min-width: 0;
  }
  .bar {
    height: var(--size-bar);
    overflow: hidden;
    border-radius: var(--radius-pill);
    background: var(--color-lineSoft);
  }
  .bar i {
    display: block;
    height: 100%;
    border-radius: inherit;
    background: linear-gradient(90deg, var(--color-accent), var(--color-accentBright));
    transition: width var(--motion-fast);
  }
  .unknown i {
    opacity: 0.5;
  }
  .progress p {
    overflow: hidden;
    color: var(--color-textFaint);
    font-size: var(--text-sm);
    text-overflow: ellipsis;
    white-space: nowrap;
  }
</style>
