<script lang="ts">
  import { ChevronLeft, Download } from '@lucide/svelte';
  import type { Component } from 'svelte';
  import { DOWNLOAD_STEPS, SCREENS, app, type InstallStep, type Screen } from './lib/app.svelte';
  import { applyTokens } from './lib/design/theme';
  import { LINKS } from './lib/project';
  import Activate from './lib/screens/Activate.svelte';
  import Help from './lib/screens/Help.svelte';
  import Home from './lib/screens/Home.svelte';
  import Install from './lib/screens/Install.svelte';
  import Machine from './lib/screens/Machine.svelte';
  import Settings from './lib/screens/Settings.svelte';
  import Tools from './lib/screens/Tools.svelte';
  import { applyMica, setTaskbarProgress, setWindowTheme, supportsMica } from './lib/services/system';
  import { shortcutFor } from './lib/shortcuts';
  import Button from './lib/ui/Button.svelte';
  import Dialog from './lib/ui/Dialog.svelte';
  import Flash from './lib/ui/Flash.svelte';
  import Notice from './lib/ui/Notice.svelte';
  import Sidebar from './lib/ui/Sidebar.svelte';
  import Skeleton from './lib/ui/Skeleton.svelte';
  import TitleBar from './lib/ui/TitleBar.svelte';
  import UpdateDialog from './lib/ui/UpdateDialog.svelte';

  type Action = {
    key: string;
    variant?: 'primary' | 'danger';
    back?: boolean;
    icon?: Component<{ size?: number }>;
    /** Stays usable while a task runs. */
    whileBusy?: boolean;
    shown?: () => boolean;
    run: () => void;
  };

  const VIEWS: Record<Screen, Component> = { home: Home, install: Install, activate: Activate, machine: Machine, tools: Tools, help: Help, settings: Settings };
  const ACTIONS: Record<Screen, Action[]> = {
    home: [{ key: 'seeMachine', run: () => app.go('machine') }],
    install: [],
    activate: [{ key: 'checkLicense', run: app.refreshLicense }],
    machine: [
      { key: 'refresh', run: app.refreshMachine },
      { key: 'copyReport', run: app.copyReport },
    ],
    tools: [],
    help: [{ key: 'viewCode', run: () => app.openLink(LINKS.repository) }],
    settings: [],
  };
  const INSTALL_ACTIONS: Record<InstallStep, Action[]> = {
    version: [{ key: 'chooseApps', variant: 'primary', run: () => (app.installStep = 'apps') }],
    apps: [
      { key: 'backToVersion', back: true, run: () => (app.installStep = 'version') },
      { key: 'review', variant: 'primary', run: () => (app.installStep = 'review') },
    ],
    review: [
      { key: 'backToApps', back: true, run: () => (app.installStep = 'apps') },
      { key: 'downloadOnly', shown: () => app.product?.route === 'odt', run: app.downloadOffline },
      { key: 'installNow', variant: 'primary', icon: Download, run: app.install },
    ],
  };
  const JOB_ACTIONS = {
    running: [
      { key: 'openFolder', whileBusy: true, run: app.openJobFolder },
      { key: 'stop', variant: 'danger', whileBusy: true, shown: () => DOWNLOAD_STEPS.includes(app.job?.step ?? 'install'), run: app.stopJob },
    ],
    installed: [
      { key: 'installAnother', back: true, run: app.closeJob },
      { key: 'goActivate', variant: 'primary', run: app.activateAfterInstall },
    ],
    downloaded: [
      { key: 'backToReview', back: true, run: app.closeJob },
      { key: 'openFolder', variant: 'primary', run: app.openJobFolder },
    ],
    stopped: [
      { key: 'backToReview', back: true, run: app.closeJob },
      { key: 'resume', variant: 'primary', run: app.retryJob },
    ],
    failed: [
      { key: 'backToReview', back: true, run: app.closeJob },
      { key: 'retry', variant: 'primary', run: app.retryJob },
    ],
  } satisfies Record<string, Action[]>;

  const t = $derived(app.t);
  const View = $derived(VIEWS[app.screen]);
  const job = $derived(app.screen === 'install' ? app.installJob : null);
  const jobActions = $derived.by((): Action[] => {
    if (!job) return [];
    if (job.endedAt === null) return JOB_ACTIONS.running;
    if (job.outcome?.ok) return job.task.action === 'install' ? JOB_ACTIONS.installed : JOB_ACTIONS.downloaded;
    return job.outcome?.reason === 'stopped' ? JOB_ACTIONS.stopped : JOB_ACTIONS.failed;
  });
  const actions = $derived(
    (job ? jobActions : app.screen === 'install' ? INSTALL_ACTIONS[app.installStep] : ACTIONS[app.screen]).filter((action) => action.shown?.() ?? true),
  );
  const note = $derived.by(() => {
    if (job) return job.endedAt === null ? app.t(`progress:tips.${DOWNLOAD_STEPS.includes(job.step ?? 'downloadSetup') ? 'download' : 'install'}`) : '';
    return app.screen === 'install' && !app.busy && app.installNote ? app.installNote : app.status;
  });
  let main = $state<HTMLElement>();

  const typing = (target: EventTarget | null) => target instanceof HTMLElement && !!target.closest('input, textarea, select');
  const onkeydown = (event: KeyboardEvent) => {
    if (app.dialog || app.updateVisible || typing(event.target)) return;
    const shortcut = shortcutFor(event, SCREENS, 'settings');
    if (!shortcut) return;
    event.preventDefault();
    if ('go' in shortcut) app.go(shortcut.go);
    else if (app.ready) void app.refreshAll();
  };

  $effect(() => {
    void [app.screen, app.installStep];
    main?.scrollTo({ top: 0 });
  });

  $effect(() => void setTaskbarProgress(app.busy ? app.progress : undefined));
  $effect.pre(() => applyTokens(app.dark));
  $effect(() => void setWindowTheme(app.theme === 'system' ? null : app.theme));

  void supportsMica().then(async (supported) => {
    if (!supported) return;
    await applyMica();
    document.documentElement.dataset.backdrop = 'mica';
  });

  void app.load();
</script>

<svelte:window {onkeydown} />

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
          <Skeleton />
        {/if}
      </main>

      <footer>
        {#if app.ready}
          {#each actions.filter((action) => action.back) as action (action.key)}
            <Button variant="ghost" icon={ChevronLeft} disabled={app.busy && !action.whileBusy} onclick={action.run}>{t(`actions:${action.key}`)}</Button>
          {/each}
        {/if}
        <div class="progress">
          {#if app.busy && !job}
            <div class="bar" class:unknown={app.progress === null}><i style:width="{app.progress ?? 100}%"></i></div>
          {/if}
          <p aria-live="polite">{note}</p>
        </div>
        {#if app.ready}
          {#each actions.filter((action) => !action.back) as action (action.key)}
            <Button variant={action.variant ?? 'ghost'} icon={action.icon} disabled={app.busy && !action.whileBusy} onclick={action.run}>
              {t(`actions:${action.key}`)}
            </Button>
          {/each}
        {/if}
      </footer>
      <Flash />
    </section>
  </div>
</div>

<Dialog />
<UpdateDialog />

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
    position: relative;
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
