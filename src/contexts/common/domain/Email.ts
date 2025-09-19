import { createValueObject } from "@foundation/domain/ValueObject";

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const EmailCtor = createValueObject<string>({
  normalize: (s) => s.trim().toLowerCase(),
  validate: (s) => emailRegex.test(s),
});
export const Email = EmailCtor;
export type Email = ReturnType<typeof Email.of>; // ergonomic static type
