import type { FibonacciScale } from "@common/domain/FibonacciScale";

export class InitiativePriority {
    userValue: FibonacciScale;
    timeCriticality: FibonacciScale;
    riskReductionOrOpportunityEnablement: FibonacciScale;
    effort: FibonacciScale;
    isCore: boolean;

    constructor(
        userValue: FibonacciScale,
        timeCriticality: FibonacciScale,
        riskReductionOrOpportunityEnablement: FibonacciScale,
        effort: FibonacciScale,
        isCore: boolean
    ) {
        this.userValue = userValue;
        this.timeCriticality = timeCriticality;
        this.riskReductionOrOpportunityEnablement = riskReductionOrOpportunityEnablement;
        this.effort = effort;
        this.isCore = isCore;
    }

    calculateWSJF(): number {
        const numerator =
            this.userValue.getValue() +
            this.timeCriticality.getValue() +
            this.riskReductionOrOpportunityEnablement.getValue()
        const denominator = this.effort.getValue() || 1; // Prevent division by zero
        return numerator / denominator;
    }

    static compare(a: InitiativePriority, b: InitiativePriority): number {
        if (a.isCore && !b.isCore) return -1;
        if (!a.isCore && b.isCore) return 1;

        const wsjfA = a.calculateWSJF();
        const wsjfB = b.calculateWSJF();

        return wsjfB - wsjfA;
    }


}