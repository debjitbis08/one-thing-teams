import type { APIRoute } from "astro";

import { postJs } from "../../contexts/id/web/LoginUserController.gen";

export const post: APIRoute = async ctx => {
  const result = await postJs(ctx as any);

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: {
      "Content-Type": "application/json",
    },
  });
};
