import { EitherAsync } from "purify-ts/EitherAsync";
import { SystemError } from "@utilities/SystemError";

export interface Command<C, R> {
    execute(command: C): EitherAsync<SystemError, R>;
}

export const executeCommand = <C, R>(
    useCase: Command<C, R>,
    command: C,
): EitherAsync<SystemError, R> => useCase.execute(command);

export const getTransaction = () => {
    throw new ReferenceError(
        "No transaction context available. getTransaction must be called within a use case chain that sets one.",
    );
};
