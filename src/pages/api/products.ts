import type { APIRoute } from "astro";

import { postJs } from "../../contexts/pm/web/CreateProductController.gen";
import { createProductDependencies } from "../../contexts/pm/infrastructure/CreateProductBridge";

export const prerender = false;

export const POST: APIRoute = async ctx => {
  const result = await postJs(createProductDependencies, {
    request: ctx.request as any,
    session: ctx.locals.session,
  } as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: { "Content-Type": "application/json" },
  });
};
