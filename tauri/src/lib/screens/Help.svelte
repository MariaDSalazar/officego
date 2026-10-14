<script lang="ts">
  import { ExternalLink } from '@lucide/svelte';
  import { app } from '../app.svelte';
  import { AUTHORS, LINKS, githubProfile } from '../project';
  import Hero from '../ui/Hero.svelte';
  import SectionTitle from '../ui/SectionTitle.svelte';

  const QUESTIONS = ['noStart', 'downloadFails', 'antivirus', 'frozen', 'offlineInstall'] as const;
  const PLEDGES = ['openSource', 'noTelemetry', 'noAds'] as const;
  const HELP_LINKS = [
    { id: 'repository', url: LINKS.repository },
    { id: 'mas', url: LINKS.mas },
    { id: 'masTroubleshoot', url: LINKS.masTroubleshoot },
    { id: 'reportIssue', url: LINKS.reportIssue },
  ] as const;

  const t = $derived(app.t);
</script>

<Hero title={t('help:title', { version: app.version })} subtitle={t('help:subtitle')} />

<SectionTitle>{t('help:authors')}</SectionTitle>
<div class="authors">
  {#each AUTHORS as author (author.user)}
    <button class="card" onclick={() => app.openLink(githubProfile(author.user))}>
      <b>{author.name}</b>
      <span class="role">{t(`help:roles.${author.role}`)}</span>
      <span class="muted">@{author.user}</span>
    </button>
  {/each}
</div>

<SectionTitle>{t('help:links')}</SectionTitle>
{#each HELP_LINKS as link (link.id)}
  <button class="card link" onclick={() => app.openLink(link.url)}>
    <span class="grow">
      <b>{t(`help:linkNames.${link.id}`)}</b>
      <span class="muted">{link.url.replace('https://', '')}</span>
    </span>
    <ExternalLink size={16} />
  </button>
{/each}

<SectionTitle>{t('help:questions')}</SectionTitle>
{#each QUESTIONS as question, index (question)}
  <div class="card question">
    <b><span class="number">{index + 1}</span>{t(`help:faq.${question}.question`)}</b>
    <p class="muted">{t(`help:faq.${question}.answer`)}</p>
  </div>
{/each}

<SectionTitle>{t('help:license')}</SectionTitle>
<div class="pledges">
  {#each PLEDGES as pledge (pledge)}<span class="card">{t(`help:pledges.${pledge}`)}</span>{/each}
</div>

<style>
  .card {
    display: flex;
    flex-direction: column;
    gap: var(--space-1);
    margin-bottom: var(--space-2);
    padding: var(--space-3) var(--space-4);
    border: var(--border-regular) solid var(--color-line);
    border-radius: var(--radius-lg);
    background: var(--color-panel);
    font-size: var(--text-sm);
    text-align: left;
  }
  button.card:hover {
    border-color: var(--color-accentHover);
  }
  .authors {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: var(--space-3);
  }
  .role {
    color: var(--color-accent);
    font-weight: 700;
  }
  .link {
    flex-direction: row;
    align-items: center;
    width: 100%;
    color: var(--color-accent);
  }
  .grow {
    display: grid;
    flex: 1;
    color: var(--color-text);
  }
  .question b {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    font-size: var(--text-md);
  }
  .question p {
    padding-left: var(--space-8);
  }
  .number {
    display: grid;
    flex: none;
    place-items: center;
    width: var(--size-badgeSm);
    height: var(--size-badgeSm);
    border-radius: var(--radius-round);
    background: var(--color-dangerSoft);
    color: var(--color-danger);
    font-size: var(--text-sm);
  }
  .pledges {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-2);
  }
</style>
