import type { Either } from "purify-ts/Either";
import type { SystemError } from "@utilities/SystemError";
import type { Initiative, InitiativeId } from "../model/Initiative";

export interface InitiativeRepository {
    findById(initiativeId: InitiativeId): Promise<Either<SystemError, Initiative>>;
}

