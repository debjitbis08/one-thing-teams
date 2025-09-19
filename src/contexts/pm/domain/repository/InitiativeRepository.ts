import type { Either } from "purify-ts/Either";
import type { SystemError } from "@utilities/SystemError";
import type { initiative as Initiative, initiativeId as InitiativeId } from "../model/Initiative.gen";

export interface InitiativeRepository {
    findById(initiativeId: InitiativeId): Promise<Either<SystemError, Initiative>>;
}

