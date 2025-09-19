import { ErrorTypes } from "@utilities/ErrorTypes.js";
import { SystemError } from "@utilities/SystemError.js";

export interface IValueObject<T> {
    getValue(): T;
    equals(other: IValueObject<T>): boolean;
    toString(): string;
}

export interface IValueObjectConstructor<T> {
    of(value: T): IValueObject<T>;
}

export class ValueObject<T> implements IValueObject<T> {
  private static readonly __brand = Symbol('VO');
  private readonly value: T;

  protected constructor(value: T) {
    this.value = value;
    Object.freeze(this); // enforce immutability
  }

  public getValue(): T { return this.value; }

  public equals(other: IValueObject<T>): boolean {
    // same constructor? (runtime brand check)
    if (!(other instanceof ValueObject)) return false;
    if ((other as any).constructor !== (this as any).constructor) return false;
    return Object.is(this.value, other.getValue());
  }

  public toString(): string { return String(this.value); }
  public toJSON(): T { return this.value as T; } // handy for JSON.stringify
}


export function createValueObject<T>(options?: {
  validate?: (value: T) => boolean;
  normalize?: (value: T) => T;
}): IValueObjectConstructor<T> {
  return class extends ValueObject<T> {
    private constructor(value: T) { super(value); }
    public static of(value: T): IValueObject<T> {
      const v = options?.normalize ? options.normalize(value) : value;
      if (options?.validate && !options.validate(v)) {
        throw new SystemError("Invalid value for value object", ErrorTypes.ValidationError);
      }
      return new this(v);
    }
    static is(u: unknown): u is IValueObject<T> {
      return u instanceof this;
    }
    static tryOf(value: T): { ok: true; value: IValueObject<T> } | { ok: false; error: Error } {
      try { return { ok: true, value: this.of(value) }; }
      catch (e) { return { ok: false, error: e as Error }; }
    }
  };
}
