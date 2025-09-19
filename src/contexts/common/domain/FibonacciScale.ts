// Value Object representing a Fibonacci scale for prioritization
import { createValueObject } from "@foundation/domain/ValueObject";

const fibonacciNumbers = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89];

const FibonacciScaleCtor = createValueObject<number>({
  validate: (n) => fibonacciNumbers.includes(n),
});

export const FibonacciScale = FibonacciScaleCtor;
export type FibonacciScale = ReturnType<typeof FibonacciScale.of>;