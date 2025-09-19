/* TypeScript file generated from TaskDomain.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as TaskDomainJS from './TaskDomain.bs.js';

export type taskId = string;

export type task = {
  readonly id: taskId; 
  readonly title: string; 
  readonly isComplete: boolean
};

export const make: (id:taskId, title:string, isComplete:(undefined | boolean), _4:void) => 
    { TAG: "Ok"; _0: task }
  | { TAG: "Error"; _0: string } = TaskDomainJS.make as any;

export const markComplete: (task:task) => task = TaskDomainJS.markComplete as any;
