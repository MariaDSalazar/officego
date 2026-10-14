<script lang="ts">
  import { app } from '../app.svelte';
  import AppsStep from './install/AppsStep.svelte';
  import ReviewStep from './install/ReviewStep.svelte';
  import Stepper from './install/Stepper.svelte';
  import VersionStep from './install/VersionStep.svelte';

  const STEPS = { version: VersionStep, apps: AppsStep, review: ReviewStep };

  const Step = $derived(STEPS[app.installStep]);
</script>

<Stepper />
<Step />
