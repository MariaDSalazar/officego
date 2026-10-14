import { MediaQuery } from 'svelte/reactivity';
import { getCatalog, getConfiguration, getLicense, getMachine, runTask, stopTask } from './services/engine';
import { toAppError } from './services/errors';
import { appVersion, chooseFolder, copyText, isWindowFocused, notify, openFolder, openLink, relaunchAsAdmin } from './services/system';
import { checkUpdate, installUpdate } from './services/updates';
import { BASE_LANGUAGE, formatter, systemLanguage, translator } from './i18n';
import { DEFAULT_APPS, adjust, downloadSizeGb, officeLanguageFor, pickableApps, productOf, toggle } from './selection';
import type { Catalog, License, MachineReport, Release, Route, Selection, Task, TaskEvent, TaskOutcome, TaskStep } from './types';

export const SCREENS = ['home', 'install', 'activate', 'machine', 'tools', 'help'] as const;
export type Screen = (typeof SCREENS)[number];

export const INSTALL_STEPS = ['version', 'apps', 'review'] as const;
export type InstallStep = (typeof INSTALL_STEPS)[number];

export const THEMES = ['system', 'light', 'dark'] as const;
export type Theme = (typeof THEMES)[number];

export type DialogTone = 'info' | 'warn' | 'danger';

export interface DialogRequest {
  title: string;
  message?: string;
  lines?: string[];
  code?: string;
  tone?: DialogTone;
  confirm?: string;
  /** Without it the dialog only informs, with a single button. */
  cancel?: string;
  /** Asks for a text; with `expected`, the confirm button waits until it is typed exactly. */
  input?: { label: string; placeholder?: string; expected?: string };
  /** An extra button that closes the dialog with this action's id. */
  extra?: { id: string; label: string };
}

type OpenDialog = DialogRequest & { resolve: (answer: string | null) => void };

/** A task followed step by step on the screen. */
export interface Job {
  task: Task;
  steps: TaskStep[];
  step: TaskStep | null;
  /** When each step began, in milliseconds since the job started. */
  began: Partial<Record<TaskStep, number>>;
  startedAt: number;
  endedAt: number | null;
  download: { percent: number; doneMb: number; totalMb: number } | null;
  /** Megabytes per second over the last seconds, once there is enough to tell. */
  speed: number | null;
  outcome: TaskOutcome | null;
  error: string;
}

export const DOWNLOAD_STEPS: TaskStep[] = ['downloadSetup', 'downloadOffice'];
const SPEED_WINDOW_MS = 15_000;
const SPEED_MINIMUM_MS = 8_000;
const MS_PER_SECOND = 1000;

/** The steps the engine goes through for a task, as the bridge reports them. */
const stepsFor = (task: Task, route?: Route): TaskStep[] => {
  if (task.action === 'download') return DOWNLOAD_STEPS;
  if (task.action !== 'install') return [];
  return route === 'c2r' ? ['downloadSetup', 'install', 'verify'] : [...DOWNLOAD_STEPS, 'install', 'verify'];
};

/** Answer of a dialog closed with its confirm button and no text to give. */
const CONFIRMED = '';
const THEME_KEY = 'officego.theme';
const systemDark = new MediaQuery('(prefers-color-scheme: dark)');
const storedTheme = (): Theme => THEMES.find((theme) => theme === localStorage.getItem(THEME_KEY)) ?? 'system';
const SELECTION_FALLBACK: Selection = { product: '', edition: '', language: '', bits: '64', apps: DEFAULT_APPS, addOns: [] };

class App {
  language = $state(BASE_LANGUAGE);
  t = $derived(translator(this.language));
  format = $derived(formatter(this.language));
  version = $state('');
  theme = $state<Theme>(storedTheme());
  dark = $derived(this.theme === 'dark' || (this.theme === 'system' && systemDark.current));

  catalog = $state<Catalog | null>(null);
  report = $state<MachineReport | null>(null);
  /** Undefined while it is being read; null when there is no Office to read it from. */
  license = $state<License | null | undefined>(undefined);
  loadError = $state('');
  ready = $derived(!!this.catalog && !!this.report);

  screen = $state<Screen>('home');
  installStep = $state<InstallStep>('version');
  selection = $state<Selection>(SELECTION_FALLBACK);

  busy = $state(false);
  /** Share done, 0 to 100, or null while there is no way to know. */
  progress = $state<number | null>(0);
  status = $state('');

  dialog = $state<OpenDialog | null>(null);

  job = $state<Job | null>(null);
  /** The install or download followed on the Install screen. */
  installJob = $derived(this.job && this.job.steps.length ? this.job : null);
  private samples: { at: number; mb: number }[] = [];

  update = $state<Release | null>(null);
  updateProgress = $state<number | null>(null);

  machine = $derived(this.report?.machine ?? null);
  systemDisk = $derived(this.machine?.disks.find((disk) => disk.system) ?? null);
  product = $derived(this.catalog ? productOf(this.catalog, this.selection.product) : null);
  pickableApps = $derived(this.catalog ? pickableApps(this.catalog, this.selection) : []);
  /** What the footer says about the choice while nothing is running. */
  installNote = $derived.by(() => {
    if (!this.catalog || !this.product || this.installStep === 'review') return '';
    const size = this.format.gigabytes(downloadSizeGb(this.catalog, this.selection));
    if (this.installStep === 'version' || this.product.route === 'c2r') return this.t('install:sizeNote', { size });
    return this.t('install:appsNote', { count: this.selection.apps.length + this.selection.addOns.length, size });
  });

  load = async () => {
    this.language = systemLanguage();
    this.status = this.t('task:idle');
    const license = this.refreshLicense();
    void this.checkForUpdate();
    void appVersion().then((version) => (this.version = version));
    let report: MachineReport;
    try {
      const [catalog, machine] = await Promise.all([getCatalog(), getMachine()]);
      report = machine;
      this.catalog = catalog;
      this.report = report;
      this.selection = adjust(catalog, {
        ...SELECTION_FALLBACK,
        product: report.recommendation.product,
        language: officeLanguageFor(catalog, navigator.languages),
        bits: report.machine.bits,
      });
    } catch (error) {
      this.loadError = this.errorText(error);
      return;
    }
    await license;
    if (!report.machine.admin) await this.offerAdmin('admin:startup');
  };

  errorText = (error: unknown) => {
    const failure = toAppError(error);
    return this.t(`errors:${failure.code}`, { detail: 'detail' in failure ? failure.detail : '' });
  };

  go = (screen: Screen) => (this.screen = screen);

  cycleTheme = () => {
    this.theme = THEMES[(THEMES.indexOf(this.theme) + 1) % THEMES.length];
    localStorage.setItem(THEME_KEY, this.theme);
  };

  ask = (request: DialogRequest) => new Promise<string | null>((resolve) => (this.dialog = { ...request, resolve }));

  answer = (value: string | null) => {
    const dialog = this.dialog;
    this.dialog = null;
    dialog?.resolve(value);
  };

  inform = (title: string, message: string, tone: DialogTone = 'info') => this.ask({ title, message, tone, confirm: this.t('common:ok') });

  choose = (change: Partial<Selection>) => {
    if (this.catalog) this.selection = adjust(this.catalog, { ...this.selection, ...change });
  };

  startInstall = () => {
    this.installStep = 'version';
    this.go('install');
  };

  chooseRecommended = () => {
    if (!this.report) return;
    this.choose({ product: this.report.recommendation.product, edition: '' });
    this.installStep = 'apps';
    this.go('install');
  };

  previewConfiguration = () => getConfiguration(this.selection);

  /** The last app cannot be unticked: an installation with no apps installs nothing. */
  toggleApp = (app: string) => {
    const apps = toggle(this.selection.apps, app);
    if (apps.length) this.choose({ apps });
  };

  toggleAddOn = (addOn: string) => this.choose({ addOns: toggle(this.selection.addOns, addOn) });

  refreshMachine = async () => {
    try {
      this.report = await getMachine();
    } catch (error) {
      await this.inform(this.t('errors:title'), this.errorText(error), 'danger');
    }
  };

  refreshLicense = async () => {
    this.license = undefined;
    try {
      this.license = await getLicense();
    } catch {
      this.license = null;
    }
  };

  private describe = (event: TaskEvent, step: TaskStep | null) => {
    const doing = step ? this.t(`task:steps.${step}`) : this.t('task:starting');
    if (event.event === 'step') return doing;
    if (event.event === 'progress')
      return this.t('task:downloading', {
        percent: this.format.percent(event.percent),
        done: this.format.megabytes(event.doneMb),
        total: this.format.megabytes(event.totalMb),
      });
    return this.t('task:elapsed', { doing, time: this.format.clock(event.seconds) });
  };

  private track = (job: Job, event: TaskEvent) => {
    if (event.event === 'step') {
      job.step = event.step;
      job.began[event.step] = Date.now() - job.startedAt;
      job.download = null;
      job.speed = null;
      this.samples = [];
    }
    if (event.event !== 'progress') return;
    job.download = { percent: event.percent, doneMb: event.doneMb, totalMb: event.totalMb };
    const now = Date.now();
    this.samples = [...this.samples.filter((sample) => now - sample.at <= SPEED_WINDOW_MS), { at: now, mb: event.doneMb }];
    const [first] = this.samples;
    const span = now - first.at;
    if (span >= SPEED_MINIMUM_MS) job.speed = ((event.doneMb - first.mb) / span) * MS_PER_SECOND;
  };

  private perform = async (task: Task): Promise<TaskOutcome | null> => {
    if (this.busy) return null;
    this.busy = true;
    this.progress = 0;
    this.status = this.t('task:starting');
    this.job = {
      task,
      steps: stepsFor(task, this.product?.route),
      step: null,
      began: {},
      startedAt: Date.now(),
      endedAt: null,
      download: null,
      speed: null,
      outcome: null,
      error: '',
    };
    const job = this.job;
    let step: TaskStep | null = null;
    try {
      const outcome = await runTask(task, (event) => {
        if (event.event === 'step') step = event.step;
        if (event.event !== 'waiting') this.progress = event.event === 'progress' ? event.percent : null;
        this.status = this.describe(event, step);
        this.track(job, event);
      });
      this.progress = outcome.ok ? 100 : 0;
      this.status = this.t(outcome.ok ? 'task:done' : 'task:failed');
      job.outcome = outcome;
      return outcome;
    } catch (error) {
      this.progress = 0;
      this.status = this.t('task:failed');
      job.error = this.errorText(error);
      if (!job.steps.length) await this.inform(this.t('errors:title'), job.error, 'danger');
      return null;
    } finally {
      job.endedAt = Date.now();
      this.busy = false;
    }
  };

  /** Why a task did not do its job, in words. */
  reasonText = (outcome: TaskOutcome) =>
    this.t(`task:reasons.${outcome.reason ?? 'installerFailed'}`, {
      code: outcome.exitCode ?? '—',
      minimum: this.format.gigabytes(this.catalog?.minimumFreeGb ?? 0),
      workFolder: this.catalog?.workFolder ?? '',
    });

  /** Explains why a task did not do its job; without permissions it offers to reopen with them. */
  private explain = async (outcome: TaskOutcome) => {
    if (outcome.reason === 'notAdmin') return this.offerAdmin('admin:needed');
    await this.ask({
      title: this.t('task:failedTitle'),
      message: this.reasonText(outcome),
      code: outcome.detail || undefined,
      tone: 'warn',
      confirm: this.t('common:ok'),
    });
  };

  /** Tells Windows how the job ended when OfficeGo is not in front, so it can be minimized while it works. */
  private announce = async (job: Job) => {
    if (await isWindowFocused()) return;
    const key = job.outcome?.ok ? 'done' : job.outcome?.reason === 'stopped' ? 'stopped' : 'failed';
    notify(this.t(`progress:notify.${job.task.action}.${key}`, { product: this.product?.name ?? '' }), this.t('progress:notify.open'));
  };

  /** Offers to reopen with administrator rights when they are missing, before asking anything else. */
  private lacksAdmin = async () => {
    if (this.machine?.admin) return false;
    await this.offerAdmin('admin:needed');
    return true;
  };

  private offerAdmin = async (messageKey: 'admin:startup' | 'admin:needed') => {
    const answer = await this.ask({
      title: this.t('admin:title'),
      message: this.t(messageKey),
      tone: 'warn',
      confirm: this.t('admin:relaunch'),
      cancel: this.t('common:notNow'),
    });
    if (answer === CONFIRMED) await this.relaunchAsAdmin();
  };

  relaunchAsAdmin = async () => {
    try {
      await relaunchAsAdmin();
    } catch (error) {
      await this.inform(this.t('admin:title'), this.errorText(error), 'warn');
    }
  };

  install = async () => {
    if (!this.product || (await this.lacksAdmin())) return;
    const outcome = await this.perform({ action: 'install', selection: this.selection });
    const job = this.job;
    if (job) await this.announce(job);
    if (!outcome) return;
    if (outcome.reason === 'notAdmin') return this.offerAdmin('admin:needed');
    await this.refreshMachine();
    if (outcome.ok) void this.refreshLicense();
  };

  downloadOffline = async () => {
    const { product } = this;
    if (!product) return;
    if (product.route === 'c2r') return this.explain({ ok: false, reason: 'onlineOnly', exitCode: null, folder: null, detail: null });
    const folder = await chooseFolder(this.t('tools:chooseFolder'));
    if (!folder) return;
    this.go('install');
    await this.perform({ action: 'download', selection: this.selection, folder });
    const job = this.job;
    if (job) await this.announce(job);
  };

  stopJob = () => void stopTask();

  /** Runs the followed job again; a stopped download picks up where it was left. */
  retryJob = async () => {
    const task = this.job?.task;
    if (task?.action === 'install') return this.install();
    if (task?.action !== 'download') return;
    await this.perform(task);
    const job = this.job;
    if (job) await this.announce(job);
  };

  closeJob = () => {
    this.job = null;
    this.installStep = 'review';
  };

  activateAfterInstall = () => {
    this.job = null;
    this.installStep = 'version';
    this.go('activate');
  };

  /** The download's folder, or the work folder where an installation keeps Office and its logs. */
  openJobFolder = async () => {
    const task = this.job?.task;
    if (task?.action === 'download') return openFolder(task.folder);
    await this.openWorkFolder();
  };

  applyKey = async () => {
    if (await this.lacksAdmin()) return;
    const key = await this.ask({
      title: this.t('activate:keyTitle'),
      message: this.t('activate:keyMessage'),
      input: { label: this.t('activate:keyLabel'), placeholder: 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX' },
      confirm: this.t('activate:keyApply'),
      cancel: this.t('common:cancel'),
    });
    if (!key) return;
    const outcome = await this.perform({ action: 'apply-key', key });
    if (!outcome) return;
    await this.refreshLicense();
    if (!outcome.ok) return this.explain(outcome);
    await this.inform(this.t('activate:keyDoneTitle'), this.t(this.license?.activated ? 'activate:keyDone' : 'activate:keyDonePending'));
  };

  activateWithMas = async () => {
    if (await this.lacksAdmin()) return;
    const answer = await this.ask({
      title: this.t('activate:masConfirmTitle'),
      message: this.t('activate:masConfirm'),
      tone: 'warn',
      confirm: this.t('common:continue'),
      cancel: this.t('common:cancel'),
    });
    if (answer !== CONFIRMED) return;
    const outcome = await this.perform({ action: 'activate' });
    if (!outcome) return;
    await this.refreshLicense();
    if (!outcome.ok) return this.explain(outcome);
    await this.inform(this.t('activate:doneTitle'), this.t('activate:done'));
  };

  repair = async () => {
    if (await this.lacksAdmin()) return;
    const answer = await this.ask({
      title: this.t('tools:repairTitle'),
      message: this.t('tools:repairConfirm'),
      confirm: this.t('tools:repairStart'),
      cancel: this.t('common:cancel'),
    });
    if (answer !== CONFIRMED) return;
    const outcome = await this.perform({ action: 'repair' });
    if (!outcome) return;
    if (!outcome.ok) return this.explain(outcome);
    await this.inform(this.t('tools:repairDoneTitle'), this.t('tools:repairDone'));
  };

  uninstall = async () => {
    if (await this.lacksAdmin()) return;
    const word = this.t('tools:uninstallWord');
    const answer = await this.ask({
      title: this.t('tools:uninstallTitle'),
      message: this.t('tools:uninstallConfirm', { word }),
      tone: 'danger',
      input: { label: this.t('tools:uninstallLabel', { word }), expected: word },
      confirm: this.t('tools:uninstallStart'),
      cancel: this.t('common:cancel'),
    });
    if (answer !== word) return;
    const outcome = await this.perform({ action: 'uninstall' });
    if (!outcome) return;
    await Promise.all([this.refreshMachine(), this.refreshLicense()]);
    if (!outcome.ok) return this.explain(outcome);
    await this.inform(this.t('tools:uninstallDoneTitle'), this.t('tools:uninstallDone'));
  };

  showConfiguration = async () => {
    try {
      const code = await getConfiguration(this.selection);
      await this.ask({ title: this.t('tools:configurationTitle'), message: this.t('tools:configurationMessage'), code, confirm: this.t('common:close') });
    } catch (error) {
      await this.inform(this.t('errors:title'), this.errorText(error), 'danger');
    }
  };

  openWorkFolder = async () => {
    if (!this.catalog) return;
    try {
      await openFolder(this.catalog.workFolder);
    } catch (error) {
      await this.inform(this.t('errors:title'), this.errorText(error), 'danger');
    }
  };

  copyReport = async () => {
    const { report, catalog } = this;
    if (!report || !catalog) return;
    const { machine, office, recommendation } = report;
    const disks = machine.disks.map((disk) =>
      this.t('machine:reportDisk', { letter: disk.letter, total: this.format.gigabytes(disk.totalGb), free: this.format.gigabytes(disk.freeGb) }),
    );
    const text = this.t('machine:report', {
      os: machine.os,
      build: machine.build,
      architecture: machine.architecture,
      powershell: machine.powershell,
      cpu: machine.cpu,
      cores: machine.cores,
      threads: machine.threads,
      ghz: this.format.gigahertz(machine.cpuGhz),
      ram: this.format.gigabytes(machine.ramGb),
      modules: machine.ramModules,
      ramFree: this.format.gigabytes(machine.ramFreeGb),
      gpu: machine.gpu,
      resolution: machine.resolution,
      disks: disks.join('\n'),
      admin: this.t(machine.admin ? 'common:yes' : 'common:no'),
      defender: this.t(machine.defender === null ? 'common:unknown' : machine.defender ? 'common:yes' : 'common:no'),
      office: office ? `${office.products} ${office.version} ${office.language} ${office.architecture}` : this.t('machine:noOffice'),
      recommended: productOf(catalog, recommendation.product).name,
      reason: this.t(`recommendation:reasons.${recommendation.reason}`),
    });
    await copyText(text);
    await this.inform(this.t('machine:copiedTitle'), this.t('machine:copied'));
  };

  openLink = (url: string) => void openLink(url);

  copy = (text: string) => copyText(text);

  checkForUpdate = async () => {
    try {
      this.update = await checkUpdate();
    } catch {
      this.update = null;
    }
  };

  offerUpdate = async () => {
    const release = this.update;
    if (!release) return;
    const answer = await this.ask({
      title: this.t('update:title', { version: release.version }),
      message: this.t(release.installable ? 'update:installable' : 'update:portable', { current: this.version, version: release.version }),
      confirm: this.t(release.installable ? 'update:now' : 'update:download'),
      cancel: this.t('common:notNow'),
    });
    if (answer !== CONFIRMED) return;
    if (!release.installable) return this.openLink(release.notesUrl);
    this.updateProgress = 0;
    try {
      await installUpdate((done) => (this.updateProgress = done));
    } catch (error) {
      this.updateProgress = null;
      await this.inform(this.t('errors:title'), this.errorText(error), 'danger');
    }
  };
}

export const app = new App();
