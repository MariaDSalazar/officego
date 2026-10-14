import type { AppError } from '../generated/AppError';
import type { GraphicsBrand } from '../generated/GraphicsBrand';
import type { RecommendationReason } from '../generated/RecommendationReason';
import type { TaskReason } from '../generated/TaskReason';
import type { TaskStep } from '../generated/TaskStep';
import type { WarningCode } from '../generated/WarningCode';
import errors from '../../../locales/es/errors.json';
import machine from '../../../locales/es/machine.json';
import recommendation from '../../../locales/es/recommendation.json';
import task from '../../../locales/es/task.json';

type Texts<Code extends string> = Record<Code, string>;

/** Fails the type check when the engine gains a code the base language has no text for. */
export const ENGINE_CODES_HAVE_TEXTS = [
  errors satisfies Texts<AppError['code']>,
  machine.brands satisfies Texts<GraphicsBrand>,
  recommendation.reasons satisfies Texts<RecommendationReason>,
  recommendation.warnings satisfies Texts<WarningCode>,
  task.reasons satisfies Texts<TaskReason>,
  task.steps satisfies Texts<TaskStep>,
];
