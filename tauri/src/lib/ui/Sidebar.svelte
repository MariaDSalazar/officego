<script lang="ts">
  import { CircleHelp, Download, House, KeyRound, Monitor, SlidersHorizontal, Sparkles, Wrench } from '@lucide/svelte';
  import type { Component } from 'svelte';
  import { SCREENS, app, type Screen } from '../app.svelte';

  const ICONS: Record<Screen, Component<{ size?: number }>> = {
    home: House,
    install: Download,
    activate: KeyRound,
    machine: Monitor,
    tools: Wrench,
    help: CircleHelp,
    settings: SlidersHorizontal,
  };
  const BOTTOM: Screen[] = ['help', 'settings'];

  const t = $derived(app.t);
  const machine = $derived(app.machine);
  const disk = $derived(app.systemDisk);
  const healthy = $derived(!!machine?.supported && !!machine.admin && (disk?.freeGb ?? 0) >= (app.catalog?.minimumFreeGb ?? 0));
</script>

{#snippet item(screen: Screen)}
  {@const Icon = ICONS[screen]}
  <button class="nav" class:active={app.screen === screen} aria-current={app.screen === screen ? 'page' : undefined} onclick={() => app.go(screen)}>
    <Icon size={18} />{t(`nav:${screen}`)}
  </button>
{/snippet}

<nav>
  {#each SCREENS.filter((screen) => !BOTTOM.includes(screen)) as screen (screen)}{@render item(screen)}{/each}

  {#if app.update}
    <button class="update" disabled={app.updateProgress !== null} onclick={app.offerUpdate}>
      <Sparkles size={16} />
      {app.updateProgress === null
        ? t('update:available', { version: app.update.version })
        : t('update:downloading', { percent: app.format.percent(app.updateProgress * 100) })}
    </button>
  {/if}

  {#if machine && disk}
    <button class="machine" title={t('status:seeMachine')} onclick={() => app.go('machine')}>
      <b><i class:healthy></i>{machine.os}</b>
      <span>{t('status:ram', { ram: app.format.gigabytes(machine.ramGb) })}</span>
      <span>{t('status:free', { free: app.format.gigabytes(disk.freeGb) })}</span>
      <span class:missing={!machine.admin}>{t(machine.admin ? 'status:admin' : 'status:noAdmin')}</span>
    </button>
  {/if}

  {#each BOTTOM as screen (screen)}{@render item(screen)}{/each}
</nav>

<style>
  nav {
    display: flex;
    flex: none;
    flex-direction: column;
    gap: var(--space-1);
    width: var(--size-sidebar);
    overflow-y: auto;
    padding: var(--space-1) var(--space-3) var(--space-3);
  }
  .nav,
  .update {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    min-height: var(--size-navItem);
    padding: 0 var(--space-3);
    border: none;
    border-radius: var(--radius-lg);
    background: none;
    color: var(--color-textMuted);
    font-size: var(--text-md);
    font-weight: 500;
    text-align: left;
  }
  .nav:hover {
    background: var(--color-hover);
    color: var(--color-text);
  }
  .active,
  .active:hover {
    background: var(--color-panel);
    color: var(--color-text);
    font-weight: 600;
    box-shadow: var(--shadow-card);
  }
  .active :global(svg) {
    color: var(--color-accent);
  }
  .update {
    margin-top: auto;
    background: var(--color-successSoft);
    color: var(--color-success);
    font-weight: 600;
  }
  .machine {
    display: grid;
    gap: var(--space-1);
    margin: auto 0 var(--space-2);
    padding: var(--space-3);
    border: var(--border-hairline) solid var(--color-line);
    border-radius: var(--radius-lg);
    background: none;
    color: var(--color-textMuted);
    font-size: var(--text-sm);
    text-align: left;
  }
  .update + .machine {
    margin-top: var(--space-2);
  }
  .machine:hover {
    border-color: var(--color-accentHover);
  }
  .machine b {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    color: var(--color-text);
    font-weight: 600;
  }
  .machine i {
    flex: none;
    width: var(--size-dot);
    height: var(--size-dot);
    border-radius: var(--radius-round);
    background: var(--color-warningStrong);
  }
  .machine i.healthy {
    background: var(--color-success);
  }
  .missing {
    color: var(--color-danger);
  }
</style>
