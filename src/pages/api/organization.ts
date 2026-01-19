import type { APIRoute } from "astro";
import { postJs } from "../../contexts/pm/web/OrganizationHandler.gen";
import { patchJs } from "../../contexts/pm/web/RenameOrganizationController.gen";
import { renameOrganizationDependencies } from "../../contexts/pm/infrastructure/RenameOrganizationBridge";

export const prerender = false;

export const POST: APIRoute = async (ctx) => {
    const result = await postJs(ctx as any);
    return new Response(JSON.stringify(result.body), {
        status: result.status,
        headers: {
            "Content-Type": "application/json",
        },
    });
};

export const PATCH: APIRoute = async ctx => {
  const result = await patchJs(renameOrganizationDependencies, {
    request: ctx.request as any,
    session: ctx.locals.session,
  } as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: {
      "Content-Type": "application/json",
    },
  });
};
