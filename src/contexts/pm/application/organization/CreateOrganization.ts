import { EitherAsync } from "purify-ts/EitherAsync";
import { SystemError } from "@utilities/SystemError";
import { ErrorTypes } from "@utilities/ErrorTypes";
import {
    Organization_create,
    type Organization_error,
} from "../../domain/model/Organization.gen";
import {
    resultToEither,
    type RescriptResult,
} from "@foundation/application/rescriptResult";

export type CreateOrganizationCommand = {
    name: string;
};

export type CreateOrganizationResult = {
    id: string;
    name: string;
    shortCode: string;
};

const toSystemError = (error: Organization_error): SystemError => {
    switch (error.TAG) {
        case "InvalidName":
            return new SystemError(
                "Organization name must not be empty",
                ErrorTypes.ValidationError,
                false,
                error._0,
            );
        case "InvalidShortCode":
        default:
            return new SystemError(
                "Unable to derive shortcode from name",
                ErrorTypes.ValidationError,
                false,
                error._0,
            );
    }
};

type GeneratedOrganization = {
    organizationId: { _0: string };
    name: string;
    shortCode: string;
};

const mapOrganization = (organization: GeneratedOrganization): CreateOrganizationResult => ({
    id: organization.organizationId._0,
    name: organization.name,
    shortCode: organization.shortCode,
});

export const createOrganizationUseCase = {
    execute: (command: CreateOrganizationCommand): EitherAsync<SystemError, CreateOrganizationResult> =>
        EitherAsync.liftEither(
            resultToEither<GeneratedOrganization, Organization_error>(
                Organization_create(command.name, undefined) as RescriptResult<
                    GeneratedOrganization,
                    Organization_error
                >,
            )
                .map(mapOrganization)
                .mapLeft(toSystemError),
        ),
};
