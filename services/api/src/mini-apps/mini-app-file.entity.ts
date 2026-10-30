// Made by Dr Ali
// One file inside a hosted mini-app package. Bytes live in Postgres so a
// later Render deploy does not drop them when the disk is wiped.

import { Column, Entity, PrimaryColumn } from 'typeorm';

@Entity({ name: 'mini_app_files' })
export class MiniAppFile {
  @PrimaryColumn({ name: 'mini_app_id', type: 'uuid' })
  miniAppId!: string;

  @PrimaryColumn({ type: 'varchar', length: 512 })
  path!: string;

  @Column({ type: 'varchar', length: 128 })
  mime!: string;

  @Column({ type: 'int' })
  size!: number;

  @Column({ type: 'bytea' })
  data!: Buffer;
}
