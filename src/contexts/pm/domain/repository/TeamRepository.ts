import type { Either } from "purify-ts/Either";
import type { SystemError } from "@utilities/SystemError";
import type { Team, TeamId } from "../model/Team";

export interface TeamRepository {
    findById(teamId: TeamId): Promise<Either<SystemError, Team>>;
}

