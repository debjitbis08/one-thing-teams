import { Either } from "purify-ts/Either";

type RescriptOk<T> = { TAG: "Ok"; _0: T };
type RescriptError<E> = { TAG: "Error"; _0: E };

export type RescriptResult<T, E> = RescriptOk<T> | RescriptError<E>;

export const resultToEither = <T, E>(result: RescriptResult<T, E>): Either<E, T> =>
    result.TAG === "Ok" ? Either.right(result._0) : Either.left(result._0);
