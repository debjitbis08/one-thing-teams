import type { APIRoute } from "astro";

import { postJs } from "../../contexts/id/web/LoginUserController.gen";

export const prerender = false;

export const POST: APIRoute = async ctx => {
  const result = await postJs(ctx as any);

  const headers = new Headers({
    "Content-Type": "application/json",
  });

  // Set session cookie on successful login
  if (result.status === 200) {
    const body = result.body as { tokens?: { sessionToken?: string } };
    const sessionToken = body?.tokens?.sessionToken;
    if (sessionToken) {
      headers.append(
        "Set-Cookie",
        `sessionToken=${sessionToken}; Path=/; HttpOnly; SameSite=Lax; Max-Age=2592000`,
      );
    }
  }

  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers,
  });
};
