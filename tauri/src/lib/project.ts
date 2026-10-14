export const REPOSITORY = 'https://github.com/MariaDSalazar/officego';

export const LINKS = {
  repository: REPOSITORY,
  releases: `${REPOSITORY}/releases/latest`,
  reportIssue: `${REPOSITORY}/issues/new`,
  mas: 'https://github.com/massgravel/Microsoft-Activation-Scripts',
  masTroubleshoot: 'https://massgrave.dev/troubleshoot',
};

export const AUTHORS = [
  { name: 'Diego Fernando Loján Tenesaca', user: 'DiegoFernandoLojanTenesaca', role: 'development' },
  { name: 'María del Carmen Salazar Torres', user: 'MariaDSalazar', role: 'engine' },
] as const;

export const githubProfile = (user: string) => `https://github.com/${user}`;
