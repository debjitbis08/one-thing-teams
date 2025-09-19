/* TypeScript file generated from InitiativePriority.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as InitiativePriorityJS from './InitiativePriority.bs.js';

import type {t as FibonacciScale_t} from '../../../../../src/contexts/common/domain/FibonacciScale.gen';

export type t = {
  readonly userValue: FibonacciScale_t; 
  readonly timeCriticality: FibonacciScale_t; 
  readonly riskReductionOrOpportunityEnablement: FibonacciScale_t; 
  readonly effort: FibonacciScale_t; 
  readonly isCore: boolean
};

export const make: (userValue:FibonacciScale_t, timeCriticality:FibonacciScale_t, riskReductionOrOpportunityEnablement:FibonacciScale_t, effort:FibonacciScale_t, isCore:boolean, param:void) => t = InitiativePriorityJS.make as any;

export const calculateWSJF: (priority:t) => number = InitiativePriorityJS.calculateWSJF as any;

export const compare: (a:t, b:t) => number = InitiativePriorityJS.compare as any;
