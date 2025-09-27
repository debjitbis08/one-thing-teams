import type { APIRoute } from "astro";

import { postJs } from "../../contexts/id/web/RegisterUserController.gen";
import { registerDependencies } from "../../contexts/id/workflows/register";

export const POST: APIRoute = async ctx => {
  const result = await postJs(registerDependencies, ctx as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: {
      "Content-Type": "application/json",
    },
  });
};

export const prerender = false;