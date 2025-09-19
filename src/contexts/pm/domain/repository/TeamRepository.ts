import type { Either } from "purify-ts/Either";
import type { SystemError } from "@utilities/SystemError";
import type { team as Team, teamId as TeamId } from "../model/Team.gen";

export interface TeamRepository {
    findById(teamId: TeamId): Promise<Either<SystemError, Team>>;
}

