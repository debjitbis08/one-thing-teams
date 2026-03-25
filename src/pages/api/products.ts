import type { APIRoute } from "astro";

import { postJs } from "../../contexts/pm/web/CreateProductController.gen";
import { createProductDependencies } from "../../contexts/pm/infrastructure/CreateProductBridge";
import { listProductsForOrg } from "../../contexts/pm/infrastructure/read/ProductReadRepository";

export const prerender = false;

export const GET: APIRoute = async ctx => {
  const session = ctx.locals.session;
  if (!session) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const products = await listProductsForOrg(session.organizationId);
  return new Response(JSON.stringify({ products }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
};

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
