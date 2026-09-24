// Made by Dr Ali
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { AiHistoryService } from './ai-history.service';
import { AiAssistantMessage } from './assistant-message.entity';
import { AiAssistantThread } from './assistant-thread.entity';

function repoMock<T extends { id?: string }>() {
  const rows: T[] = [];
  return {
    rows,
    create: (x: Partial<T>) => ({ ...x } as T),
    save: jest.fn(async (x: T | T[]) => {
      if (Array.isArray(x)) {
        for (const item of x) {
          if (!(item as { id?: string }).id) {
            (item as { id: string }).id = `m-${rows.length + 1}`;
          }
          rows.push(item);
        }
        return x;
      }
      if (!x.id) (x as { id: string }).id = `t-${rows.length + 1}`;
      const idx = rows.findIndex((r) => r.id === x.id);
      if (idx >= 0) rows[idx] = x;
      else rows.push(x);
      return x;
    }),
    find: jest.fn(async (opts?: { where?: Partial<T>; order?: unknown; take?: number }) => {
      let out = [...rows];
      if (opts?.where) {
        out = out.filter((r) =>
          Object.entries(opts.where!).every(
            ([k, v]) => (r as Record<string, unknown>)[k] === v,
          ),
        );
      }
      if (opts?.take != null) out = out.slice(0, opts.take);
      return out;
    }),
    findOne: jest.fn(async (opts?: { where?: Partial<T> }) => {
      if (!opts?.where) return rows[0] ?? null;
      return (
        rows.find((r) =>
          Object.entries(opts.where!).every(
            ([k, v]) => (r as Record<string, unknown>)[k] === v,
          ),
        ) ?? null
      );
    }),
    count: jest.fn(async (opts?: { where?: Partial<T> }) => {
      if (!opts?.where) return rows.length;
      return rows.filter((r) =>
        Object.entries(opts.where!).every(
          ([k, v]) => (r as Record<string, unknown>)[k] === v,
        ),
      ).length;
    }),
    delete: jest.fn(async (ids: string[]) => {
      for (const id of ids) {
        const i = rows.findIndex((r) => r.id === id);
        if (i >= 0) rows.splice(i, 1);
      }
    }),
    remove: jest.fn(async (x: T | T[]) => {
      const list = Array.isArray(x) ? x : [x];
      for (const item of list) {
        const i = rows.findIndex((r) => r.id === item.id);
        if (i >= 0) rows.splice(i, 1);
      }
    }),
  };
}

describe('AiHistoryService IDOR', () => {
  it('refuses to append to another user thread', async () => {
    const threads = repoMock<AiAssistantThread>();
    const messages = repoMock<AiAssistantMessage>();
    const svc = new AiHistoryService(
      threads as never,
      messages as never,
    );

    await threads.save(
      threads.create({
        id: 'thread-a',
        userId: 'user-a',
        title: 'hi',
        createdAt: new Date(),
        updatedAt: new Date(),
      }) as AiAssistantThread,
    );

    await expect(
      svc.appendExchange({
        userId: 'user-b',
        threadId: 'thread-a',
        userMessage: 'hack',
        assistantReply: 'nope',
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);

    expect(messages.rows).toHaveLength(0);
  });

  it('getThread hides other users (same not-found)', async () => {
    const threads = repoMock<AiAssistantThread>();
    const messages = repoMock<AiAssistantMessage>();
    const svc = new AiHistoryService(
      threads as never,
      messages as never,
    );

    await threads.save(
      threads.create({
        id: 'thread-a',
        userId: 'user-a',
        title: 'secret',
        createdAt: new Date(),
        updatedAt: new Date(),
      }) as AiAssistantThread,
    );

    await expect(svc.getThread('user-b', 'thread-a')).rejects.toBeInstanceOf(
      NotFoundException,
    );
    await expect(svc.getThread('user-b', 'missing')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('listThreads only returns caller rows', async () => {
    const threads = repoMock<AiAssistantThread>();
    const messages = repoMock<AiAssistantMessage>();
    const svc = new AiHistoryService(
      threads as never,
      messages as never,
    );

    await threads.save(
      threads.create({
        id: 't1',
        userId: 'user-a',
        title: 'a',
        createdAt: new Date(),
        updatedAt: new Date(),
      }) as AiAssistantThread,
    );
    await threads.save(
      threads.create({
        id: 't2',
        userId: 'user-b',
        title: 'b',
        createdAt: new Date(),
        updatedAt: new Date(),
      }) as AiAssistantThread,
    );

    const listed = await svc.listThreads('user-a');
    expect(listed.map((t) => t.id)).toEqual(['t1']);
  });
});
