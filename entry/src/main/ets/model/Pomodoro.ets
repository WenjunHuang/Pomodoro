export interface PreRun {
  type: "prerun";
  elapsedTimeMS: number;
  totalTimeMS: number;
}

export interface Running {
  type: 'running';
  elapsedTimeMS: number;
  totalTimeMS: number;
}

export interface Paused {
  type: 'paused';
  elapsedTimeMS: number;
  totalTimeMS: number;
}

export interface PreStop {
  type: "prestop"
}

export interface Stopped {
  type: 'stopped';
}

export interface Finished {
  type: 'finished'
}

export interface Transition {
  type: 'transition';
  from: TimerState;
  to: TimerState;
}

export type TimerState = PreRun | Running | Paused | PreStop | Stopped | Finished | Transition

export enum Phrase {
  POMODORO,
  SHORT_BREAK,
  LONG_BREAK
}

export const FPS: number = 90

export const TICK_MS: number = 1000 / FPS // fps: 90

export const CIRCLE_STEPS: number = Math.floor(FPS / 2) // 因为每秒90帧，所以45帧等于半秒
