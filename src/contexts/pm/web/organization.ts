import type { APIRoute } from "astro";
import { executeCommand } from "@foundation/application/CommandHandler";
import { createOrganizationUseCase } from "../application/organization/CreateOrganization";

type CreateOrganizationPayload = {
    name?: unknown;
};

const jsonResponse = (status: number, body: unknown) =>
    new Response(JSON.stringify(body), {
        status,
        headers: {
            "Content-Type": "application/json",
        },
    });

export const post: APIRoute = async ({ request }) => {
    let payload: CreateOrganizationPayload;

    try {
        payload = (await request.json()) as CreateOrganizationPayload;
    } catch (error) {
        return jsonResponse(400, {
            error: "Invalid JSON body",
        });
    }

    if (typeof payload.name !== "string") {
        return jsonResponse(400, {
            error: "Organization name is required",
        });
    }

    const result = await executeCommand(createOrganizationUseCase, {
        name: payload.name,
    }).run();

    return result.caseOf({
        Left: (err) => {
            const { status, message } = err.toWebError();
            return jsonResponse(status, { error: message });
        },
        Right: (organization) => {
            if (!organization) {
                return jsonResponse(500, {
                    error: "Organization was not created",
                });
            }

            return jsonResponse(201, organization);
        },
    });
};
