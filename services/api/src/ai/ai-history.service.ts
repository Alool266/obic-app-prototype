// Made by Dr Ali
// Persist / load OBIC AI assistant threads per user (IDOR-safe).

import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AiAssistantMessage } from './assistant-message.entity';
import { AiAssistantThread } from './assistant-thread.entity';

const MAX_THREADS = 40;
const MAX_MESSAGES = 80;
const TITLE_MAX = 48;

@Injectable()
export class AiHistoryService {
  constructor(
    @InjectRepository(AiAssistantThread)
    private readonly threads: Repository<AiAssistantThread>,
    @InjectRepository(AiAssistantMessage)
    private readonly messages: Repository<AiAssistantMessage>,
  ) {}

  async listThreads(userId: string) {
    const rows = await this.threads.find({
      where: { userId },
      order: { updatedAt: 'DESC' },
      take: MAX_THREADS,
    });
    return rows.map((t) => ({
      id: t.id,
      title: t.title,
      updatedAt: t.updatedAt.toISOString(),
      createdAt: t.createdAt.toISOString(),
    }));
  }

  async getThread(userId: string, threadId: string) {
    const thread = await this.requireOwnedThread(userId, threadId);
    const msgs = await this.messages.find({
      where: { threadId: thread.id },
      order: { createdAt: 'ASC' },
      take: MAX_MESSAGES,
    });
    return {
      id: thread.id,
      title: thread.title,
      updatedAt: thread.updatedAt.toISOString(),
      createdAt: thread.createdAt.toISOString(),
      messages: msgs.map((m) => ({
        id: m.id,
        role: m.role,
        content: m.content,
        createdAt: m.createdAt.toISOString(),
      })),
    };
  }

  async deleteThread(userId: string, threadId: string) {
    const thread = await this.requireOwnedThread(userId, threadId);
    await this.threads.remove(thread);
    return { ok: true as const, id: threadId };
  }

  /**
   * Ensure owned thread exists (create if missing), append user + assistant turns.
   * Returns the durable thread id.
   */
  async appendExchange(opts: {
    userId: string;
    threadId?: string | null;
    userMessage: string;
    assistantReply: string;
  }): Promise<{ threadId: string; title: string }> {
    const userText = opts.userMessage.trim().slice(0, 4000);
    const assistantText = opts.assistantReply.trim().slice(0, 8000);
    if (!userText) {
      throw new ForbiddenException('Empty message');
    }

    let thread: AiAssistantThread | null = null;
    if (opts.threadId) {
      thread = await this.threads.findOne({
        where: { id: opts.threadId },
      });
      if (thread && thread.userId !== opts.userId) {
        // IDOR — never append to another user's thread.
        throw new ForbiddenException('Thread not found');
      }
      if (!thread) {
        throw new NotFoundException('Thread not found');
      }
    }

    if (!thread) {
      thread = await this.threads.save(
        this.threads.create({
          userId: opts.userId,
          title: this.titleFrom(userText),
        }),
      );
    } else if (thread.title === 'OBIC AI' || !thread.title.trim()) {
      thread.title = this.titleFrom(userText);
    }

    await this.messages.save([
      this.messages.create({
        threadId: thread.id,
        role: 'user',
        content: userText,
      }),
      this.messages.create({
        threadId: thread.id,
        role: 'assistant',
        content: assistantText || '…',
      }),
    ]);

    // Trim old messages (keep latest MAX_MESSAGES).
    const count = await this.messages.count({
      where: { threadId: thread.id },
    });
    if (count > MAX_MESSAGES) {
      const oldest = await this.messages.find({
        where: { threadId: thread.id },
        order: { createdAt: 'ASC' },
        take: count - MAX_MESSAGES,
        select: ['id'],
      });
      if (oldest.length > 0) {
        await this.messages.delete(oldest.map((m) => m.id));
      }
    }

    thread.updatedAt = new Date();
    await this.threads.save(thread);

    // Cap thread count per user.
    const all = await this.threads.find({
      where: { userId: opts.userId },
      order: { updatedAt: 'DESC' },
    });
    if (all.length > MAX_THREADS) {
      const drop = all.slice(MAX_THREADS);
      await this.threads.remove(drop);
    }

    return { threadId: thread.id, title: thread.title };
  }

  private async requireOwnedThread(userId: string, threadId: string) {
    const thread = await this.threads.findOne({ where: { id: threadId } });
    if (!thread || thread.userId !== userId) {
      // Same message for missing vs other-user — avoid IDOR oracle.
      throw new NotFoundException('Thread not found');
    }
    return thread;
  }

  private titleFrom(text: string): string {
    const cleaned = text.replace(/\s+/g, ' ').trim();
    if (!cleaned) return 'OBIC AI';
    if (cleaned.length <= TITLE_MAX) return cleaned;
    return `${cleaned.slice(0, TITLE_MAX - 1)}…`;
  }
}
