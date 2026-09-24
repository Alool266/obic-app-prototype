// Made by Dr Ali
// Durable upload blobs — survives Render/ephemeral disk redeploys (trial).

import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryColumn,
} from 'typeorm';

@Entity({ name: 'uploaded_files' })
export class UploadedFile {
  /** Same as public filename stem (uuid) — URL is /uploads/{id}{ext}. */
  @PrimaryColumn({ type: 'uuid' })
  id!: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 255 })
  filename!: string;

  @Column({ name: 'original_name', type: 'varchar', length: 512, nullable: true })
  originalName!: string | null;

  @Column({ type: 'varchar', length: 128 })
  mime!: string;

  @Column({ type: 'int' })
  size!: number;

  @Column({ type: 'bytea' })
  data!: Buffer;

  @Column({ name: 'uploader_id', type: 'uuid', nullable: true })
  uploaderId!: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
