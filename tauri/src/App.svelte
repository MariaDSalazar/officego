<script lang="ts">
  import { CircleHelp, Download, House, KeyRound, Monitor, RefreshCw, Sparkles, Wrench } from '@lucide/svelte';
  import type { Component } from 'svelte';
  import { SCREENS, app, type Screen } from './lib/app.svelte';
  import { LINKS } from './lib/project';
  import Activate from './lib/screens/Activate.svelte';
  import Help from './lib/screens/Help.svelte';
  import Home from './lib/screens/Home.svelte';
  import Install from './lib/screens/Install.svelte';
  import Machine from './lib/screens/Machine.svelte';
  import Tools from './lib/screens/Tools.svelte';
  import Button from './lib/ui/Button.svelte';
  import Dialog from './lib/ui/Dialog.svelte';
  import Logo from './lib/ui/Logo.svelte';
  import Notice from './lib/ui/Notice.svelte';

  type Action = { key: string; primary?: boolean; run: () => void };

  const ICONS: Record<Screen, Component<{ size?: number }>> = {
    home: House,
    install: Download,
    activate: KeyRound,
    machine: Monitor,
    tools: Wrench,
    help: CircleHelp,
  };
  const VIEWS: Record<Screen, Component> = { home: Home, install: Install, activate: Activate, machine: Machine, tools: Tools, help: Help };
  const ACTIONS: Record<Screen, Action[]> = {
    home: [
      { key: 'start', primary: true, run: () => app.go('install') },
      { key: 'seeMachine', run: () => app.go('machine') },
    ],
    install: [
      { key: 'installOffice', primary: true, run: app.install },
      { key: 'downloadOnly', run: app.downloadOffline },
    ],
    activate: [{ key: 'checkLicense', run: app.refreshLicense }],
    machine: [
      { key: 'copyReport', run: app.copyReport },
      { key: 'refresh', run: app.refreshMachine },
    ],
    tools: [],
    help: [{ key: 'viewCode', run: () => app.openLink(LINKS.repository) }],
  };

  const t = $derived(app.t);
  const View = $derived(VIEWS[app.screen]);
  const machine = $derived(app.machine);
  const disk = $derived(app.systemDisk);

  void app.load();
</script>

<div class="window">
  <div class="body">
    <nav>
      <div class="brand"><Logo /><b>OfficeGo</b></div>
      {#each SCREENS as screen (screen)}
        {@const Icon = ICONS[screen]}
        <button class="nav" class:active={app.screen === screen} aria-current={app.screen === screen ? 'page' : undefined} onclick={() => app.go(screen)}>
          <Icon size={18} />{t(`nav:${screen}`)}
        </button>
      {/each}
      {#if app.update}
        <button class="update" disabled={app.updateProgress !== null} onclick={app.offerUpdate}>
          <Sparkles size={16} />
          {app.updateProgress === null
            ? t('update:available', { version: app.update.version })
            : t('update:downloading', { percent: app.format.percent(app.updateProgress * 100) })}
        </button>
      {/if}
    </nav>

    <main>
      {#if app.loadError}
        <Notice tone="error"><b>{t('errors:loadTitle')}</b> {app.loadError}</Notice>
      {:else if app.ready}
        <View />
      {:else}
        <div class="loading"><RefreshCw size={28} class="spin" />{t('common:checking')}</div>
      {/if}
    </main>
  </div>

  <footer>
    {#if app.ready}
      {#each ACTIONS[app.screen] as action (action.key)}
        <Button variant={action.primary ? 'primary' : 'ghost'} disabled={app.busy} onclick={action.run}>{t(`actions:${action.key}`)}</Button>
      {/each}
    {/if}
    <div class="progress">
      <div class="bar" class:unknown={app.progress === null}><i style:width="{app.progress ?? 100}%"></i></div>
      <p aria-live="polite">{app.status}</p>
    </div>
  </footer>

  <div class="status">
    {#if machine && disk}
      <span><i class:good={machine.supported}></i>{machine.os} · {machine.build.split('.')[0]}</span>
      <span><i class:good={machine.admin}></i>{t(machine.admin ? 'status:admin' : 'status:noAdmin')}</span>
      <span><i class:good={disk.freeGb >= (app.catalog?.minimumFreeGb ?? 0)}></i>{t('status:free', { free: app.format.gigabytes(disk.freeGb) })}</span>
      <span
        ><i class="neutral"></i>{t(machine.defender === null ? 'status:defenderUnknown' : machine.defender ? 'status:defenderOn' : 'status:defenderOff')}</span
      >
      <span><i class="neutral"></i>{t(app.report?.office ? 'status:officeInstalled' : 'status:officeMissing')}</span>
    {/if}
    <span class="version">OfficeGo {app.version}</span>
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
  nav {
    display: flex;
    flex-direction: column;
    flex: none;
    width: var(--size-sidebar);
    overflow-y: auto;
    padding: var(--space-3) var(--space-2);
    border-right: var(--border-hairline) solid var(--color-lineSoft);
    background: var(--color-panel);
  }
  .brand {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-2) var(--space-3) var(--space-4);
    font-size: var(--text-lg);
  }
  .nav,
  .update {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    margin-bottom: var(--space-1);
    padding: var(--space-2) var(--space-3);
    border: none;
    border-radius: var(--radius-md);
    background: none;
    color: var(--color-textBody);
    font-size: var(--text-md);
    text-align: left;
  }
  .nav:hover {
    background: var(--color-lineFaint);
  }
  .active,
  .active:hover {
    background: var(--color-accentSoft);
    color: var(--color-accent);
    font-weight: 700;
  }
  .update {
    margin-top: auto;
    background: var(--color-successSoft);
    color: var(--color-success);
    font-weight: 700;
  }
  main {
    flex: 1;
    overflow-y: auto;
    padding: var(--space-4) var(--space-5);
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
    padding: var(--space-3) var(--space-5);
    border-top: var(--border-hairline) solid var(--color-lineSoft);
    background: var(--color-panel);
  }
  .progress {
    flex: 1;
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
    margin-top: var(--space-1);
    overflow: hidden;
    color: var(--color-textMuted);
    font-size: var(--text-sm);
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .status {
    display: flex;
    align-items: center;
    gap: var(--space-4);
    padding: var(--space-2) var(--space-5);
    border-top: var(--border-hairline) solid var(--color-statusLine);
    background: var(--color-statusBar);
    color: var(--color-textBody);
    font-size: var(--text-sm);
  }
  .status span {
    display: flex;
    align-items: center;
    gap: var(--space-2);
  }
  .status i {
    width: var(--size-dot);
    height: var(--size-dot);
    border-radius: var(--radius-round);
    background: var(--color-danger);
  }
  .status i.good {
    background: var(--color-success);
  }
  .status i.neutral {
    background: var(--color-warningStrong);
  }
  .version {
    margin-left: auto;
    color: var(--color-textFaint);
  }
</style>
