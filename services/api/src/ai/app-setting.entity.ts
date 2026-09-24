// Made by Dr Ali
// Lightweight key/value settings (global AI auto-reply, etc.).

import { Column, Entity, PrimaryColumn, UpdateDateColumn } from 'typeorm';

@Entity({ name: 'app_settings' })
export class AppSetting {
  @PrimaryColumn({ type: 'varchar', length: 80 })
  key!: string;

  @Column({ type: 'text' })
  value!: string;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}

/** Global kill-switch for support/order AI auto-reply (DB override). */
export const AI_AUTO_REPLY_GLOBAL_KEY = 'ai_auto_reply_global';
