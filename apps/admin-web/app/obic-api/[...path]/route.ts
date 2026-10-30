// Made by Dr Ali
// Same-origin API proxy for Admin Web (avoids browser/Clash blocking 127.0.0.1:3001).

import { NextRequest, NextResponse } from 'next/server';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const UPSTREAM =
  process.env.OBIC_API_UPSTREAM?.replace(/\/$/, '') || 'http://127.0.0.1:3001';

async function proxy(req: NextRequest, pathParts: string[]) {
  const path = pathParts.join('/');
  const url = new URL(req.url);
  const target = `${UPSTREAM}/${path}${url.search}`;

  const headers = new Headers();
  const pass = ['authorization', 'content-type', 'accept', 'x-obic-totp'];
  for (const h of pass) {
    const v = req.headers.get(h);
    if (v) headers.set(h, v);
  }

  let body: ArrayBuffer | undefined;
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    body = await req.arrayBuffer();
  }

  let upstream: Response;
  try {
    upstream = await fetch(target, {
      method: req.method,
      headers,
      body,
      cache: 'no-store',
      // @ts-expect-error Node fetch
      duplex: body ? 'half' : undefined,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'upstream down';
    return NextResponse.json(
      { message: `API unreachable (${UPSTREAM}). Start services/api on :3001. ${msg}` },
      { status: 502 },
    );
  }

  const outHeaders = new Headers();
  const ct = upstream.headers.get('content-type');
  if (ct) outHeaders.set('content-type', ct);

  return new NextResponse(upstream.body, {
    status: upstream.status,
    headers: outHeaders,
  });
}

type Ctx = { params: Promise<{ path: string[] }> };

export async function GET(req: NextRequest, ctx: Ctx) {
  const { path } = await ctx.params;
  return proxy(req, path);
}
export async function POST(req: NextRequest, ctx: Ctx) {
  const { path } = await ctx.params;
  return proxy(req, path);
}
export async function PUT(req: NextRequest, ctx: Ctx) {
  const { path } = await ctx.params;
  return proxy(req, path);
}
export async function PATCH(req: NextRequest, ctx: Ctx) {
  const { path } = await ctx.params;
  return proxy(req, path);
}
export async function DELETE(req: NextRequest, ctx: Ctx) {
  const { path } = await ctx.params;
  return proxy(req, path);
}
export async function OPTIONS() {
  return new NextResponse(null, { status: 204 });
}
