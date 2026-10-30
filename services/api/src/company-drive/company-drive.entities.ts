// Made by Dr Ali
// A company folder and a file stored for staff. The bytes are not a public upload.

import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'company_drive_folders' })
export class CompanyDriveFolder {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 40 })
  name!: string;

  @Column({ name: 'name_key', type: 'varchar', length: 40 })
  nameKey!: string;

  @Column({ type: 'boolean', default: true })
  active!: boolean;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}

@Entity({ name: 'company_drive_files' })
export class CompanyDriveFile {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'folder_id', type: 'uuid' })
  folderId!: string;

  @Column({ type: 'varchar', length: 80 })
  name!: string;

  @Column({ name: 'name_key', type: 'varchar', length: 80 })
  nameKey!: string;

  @Column({ type: 'varchar', length: 8 })
  ext!: string;

  @Column({ type: 'varchar', length: 128 })
  mime!: string;

  @Column({ type: 'int' })
  size!: number;

  @Column({ type: 'bytea' })
  data!: Buffer;

  @Column({ name: 'uploader_id', type: 'uuid' })
  uploaderId!: string;

  @Column({ type: 'boolean', default: true })
  active!: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
