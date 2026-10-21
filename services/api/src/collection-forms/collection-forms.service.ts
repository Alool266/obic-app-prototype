// Made by Dr Ali
// One form sent to many staff. Each person keeps a single row, and the desk reads them together.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import {
  assertOfficeFields,
  isOfficeFieldType,
  validateOfficeAnswers,
  type OfficeFieldDef,
} from '../office-forms/office-form';
import type { OfficeFieldSnapshot } from '../office-forms/office-form.entities';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import { assertCollectionEdit } from './collection-form';
import {
  CollectionForm,
  CollectionFormField,
  CollectionFormMember,
  CollectionFormResponse,
} from './collection-form.entities';
import {
  SaveCollectionFormDto,
  SubmitCollectionFormDto,
} from './dto/collection-form.dto';

@Injectable()
export class CollectionFormsService {
  constructor(
    @InjectRepository(CollectionForm)
    private readonly forms: Repository<CollectionForm>,
    @InjectRepository(CollectionFormField)
    private readonly fields: Repository<CollectionFormField>,
    @InjectRepository(CollectionFormMember)
    private readonly members: Repository<CollectionFormMember>,
    @InjectRepository(CollectionFormResponse)
    private readonly responses: Repository<CollectionFormResponse>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async home(actor: AuthUser) {
    const user = await this.requireStaff(actor);
    const memberships = await this.members.find({ where: { userId: user.id } });
    const ids = memberships.map((row) => row.collectionId);
    if (!ids.length) return { collections: [] };
    const forms = await this.forms.find({
      where: { id: In(ids) },
      order: { updatedAt: 'DESC' },
    });
    const [fieldRows, mine] = await Promise.all([
      this.fields.find({
        where: { collectionId: In(ids) },
        order: { position: 'ASC' },
      }),
      this.responses.find({
        where: { collectionId: In(ids), userId: user.id },
      }),
    ]);
    return {
      collections: forms.map((form) => ({
        ...this.toForm(form, fieldRows),
        response: this.toOwnResponse(
          mine.find((row) => row.collectionId === form.id) ?? null,
        ),
      })),
    };
  }

  async submit(actor: AuthUser, id: string, dto: SubmitCollectionFormDto) {
    const user = await this.requireStaff(actor);
    const form = await this.forms.findOne({ where: { id } });
    if (!form) throw new NotFoundException('Collection not found');
    if (!form.active) {
      throw new BadRequestException('This collection is closed');
    }
    const member = await this.members.findOne({
      where: { collectionId: form.id, userId: user.id },
    });
    if (!member) {
      throw new ForbiddenException('This collection was not sent to you');
    }
    const defs = this.toDefs(
      await this.fields.find({
        where: { collectionId: form.id },
        order: { position: 'ASC' },
      }),
    );
    let answers: Record<string, string>;
    try {
      answers = validateOfficeAnswers(defs, dto.answers ?? {});
    } catch (error) {
      throw this.answerError(error);
    }
    const snapshot = defs.map((field) => this.toSnapshot(field));
    const existing = await this.responses.findOne({
      where: { collectionId: form.id, userId: user.id },
    });
    const saved = await this.saveResponse(existing, {
      collectionId: form.id,
      userId: user.id,
      answers,
      fieldsSnapshot: snapshot,
    });
    await this.audit(user.id, 'collection_form_submit', saved.id, {
      collectionId: form.id,
    });
    return this.toOwnResponse(saved);
  }

  async board(actor: AuthUser) {
    await this.requireReviewer(actor);
    const forms = await this.forms.find({ order: { updatedAt: 'DESC' } });
    const ids = forms.map((form) => form.id);
    if (!ids.length) return { collections: [] };
    const [fieldRows, memberRows, responseRows] = await Promise.all([
      this.fields.find({
        where: { collectionId: In(ids) },
        order: { position: 'ASC' },
      }),
      this.members.find({ where: { collectionId: In(ids) } }),
      this.responses.find({ where: { collectionId: In(ids) } }),
    ]);
    const people = memberRows.length
      ? await this.users.find({
          where: { id: In(memberRows.map((row) => row.userId)) },
        })
      : [];
    return {
      collections: forms.map((form) => {
        const audience = memberRows.filter((row) => row.collectionId === form.id);
        const answers = responseRows.filter((row) => row.collectionId === form.id);
        return {
          ...this.toForm(form, fieldRows),
          responseCount: answers.length,
          rows: audience.map((member) => {
            const response = answers.find((row) => row.userId === member.userId);
            return {
              userId: member.userId,
              name: people.find((person) => person.id === member.userId)?.name ?? '',
              answers: response?.answers ?? null,
              updatedAt: response
                ? new Date(response.updatedAt).toISOString()
                : null,
            };
          }),
        };
      }),
    };
  }

  async create(actor: AuthUser, dto: SaveCollectionFormDto) {
    const user = await this.requireSuperAdmin(actor);
    const defs = this.checkedFields(dto);
    const audienceIds = await this.checkedAudience(dto.audienceIds);
    const saved = await this.forms.manager.transaction(async (manager) => {
      const form = await manager.save(
        manager.create(CollectionForm, {
          nameEn: dto.nameEn.trim(),
          nameAr: dto.nameAr.trim(),
          nameZh: dto.nameZh.trim(),
          active: dto.active,
        }),
      );
      await manager.save(
        defs.map((field, position) =>
          manager.create(CollectionFormField, this.toFieldRow(form.id, position, field)),
        ),
      );
      await manager.save(
        audienceIds.map((userId) =>
          manager.create(CollectionFormMember, {
            collectionId: form.id,
            userId,
          }),
        ),
      );
      return form;
    });
    await this.audit(user.id, 'admin_create_collection_form', saved.id, {
      nameEn: saved.nameEn,
      audience: audienceIds.length,
    });
    return this.board(actor);
  }

  async update(actor: AuthUser, id: string, dto: SaveCollectionFormDto) {
    const user = await this.requireSuperAdmin(actor);
    const form = await this.forms.findOne({ where: { id } });
    if (!form) throw new NotFoundException('Collection not found');
    const defs = this.checkedFields(dto);
    const audienceIds = await this.checkedAudience(dto.audienceIds);
    const [previousFields, previousMembers, responseCount] = await Promise.all([
      this.fields.find({
        where: { collectionId: form.id },
        order: { position: 'ASC' },
      }),
      this.members.find({ where: { collectionId: form.id } }),
      this.responses.count({ where: { collectionId: form.id } }),
    ]);
    try {
      assertCollectionEdit({
        responseCount,
        previousFields: this.toDefs(previousFields),
        nextFields: defs,
        previousAudience: previousMembers.map((row) => row.userId),
        nextAudience: audienceIds,
      });
    } catch (error) {
      if (error instanceof Error && error.message === 'COLLECTION_LOCKED') {
        throw new BadRequestException(
          'This collection already has answers, so its fields and people stay as they are',
        );
      }
      throw error;
    }
    form.nameEn = dto.nameEn.trim();
    form.nameAr = dto.nameAr.trim();
    form.nameZh = dto.nameZh.trim();
    form.active = dto.active;
    await this.forms.manager.transaction(async (manager) => {
      await manager.save(form);
      if (responseCount === 0) {
        await manager.delete(CollectionFormField, { collectionId: form.id });
        await manager.delete(CollectionFormMember, { collectionId: form.id });
        await manager.save(
          defs.map((field, position) =>
            manager.create(
              CollectionFormField,
              this.toFieldRow(form.id, position, field),
            ),
          ),
        );
        await manager.save(
          audienceIds.map((userId) =>
            manager.create(CollectionFormMember, {
              collectionId: form.id,
              userId,
            }),
          ),
        );
      }
    });
    await this.audit(user.id, 'admin_update_collection_form', form.id, {
      active: form.active,
    });
    return this.board(actor);
  }

  private async saveResponse(
    existing: CollectionFormResponse | null,
    input: {
      collectionId: string;
      userId: string;
      answers: Record<string, string>;
      fieldsSnapshot: OfficeFieldSnapshot[];
    },
  ): Promise<CollectionFormResponse> {
    if (existing) {
      existing.answers = input.answers;
      existing.fieldsSnapshot = input.fieldsSnapshot;
      return this.responses.save(existing);
    }
    try {
      return await this.responses.save(this.responses.create(input));
    } catch (error) {
      if (!isUniqueViolation(error)) throw error;
      const again = await this.responses.findOne({
        where: { collectionId: input.collectionId, userId: input.userId },
      });
      if (!again) throw error;
      return this.saveResponse(again, input);
    }
  }

  private checkedFields(dto: SaveCollectionFormDto): OfficeFieldDef[] {
    try {
      return assertOfficeFields(
        dto.fields.map((field) => ({
          key: field.key,
          labelEn: field.labelEn,
          labelAr: field.labelAr,
          labelZh: field.labelZh,
          type: field.type,
          required: field.required,
          options: field.options ?? [],
        })),
      );
    } catch (error) {
      throw this.fieldError(error);
    }
  }

  private async checkedAudience(ids: string[]): Promise<string[]> {
    const audienceIds = [...new Set(ids)];
    if (!audienceIds.length) {
      throw new BadRequestException('Choose at least one person');
    }
    const staff = await this.users.find({
      where: { id: In(audienceIds), deletedAt: IsNull() },
    });
    const allowed = new Set(
      staff
        .filter(
          (person) =>
            person.role === UserRole.Employee ||
            person.role === UserRole.SuperAdmin,
        )
        .map((person) => person.id),
    );
    if (audienceIds.some((id) => !allowed.has(id))) {
      throw new BadRequestException('Send a collection only to staff');
    }
    return audienceIds;
  }

  private toFieldRow(
    collectionId: string,
    position: number,
    field: OfficeFieldDef,
  ) {
    return {
      collectionId,
      position,
      fieldKey: field.key,
      labelEn: field.labelEn,
      labelAr: field.labelAr,
      labelZh: field.labelZh,
      fieldType: field.type,
      required: field.required,
      options: field.options,
    };
  }

  private toDefs(rows: CollectionFormField[]): OfficeFieldDef[] {
    return rows.map((row) => {
      if (!isOfficeFieldType(row.fieldType)) {
        throw new BadRequestException('Check the form fields');
      }
      return {
        key: row.fieldKey,
        labelEn: row.labelEn,
        labelAr: row.labelAr,
        labelZh: row.labelZh,
        type: row.fieldType,
        required: row.required,
        options: Array.isArray(row.options) ? row.options : [],
      };
    });
  }

  private toSnapshot(field: OfficeFieldDef): OfficeFieldSnapshot {
    return {
      key: field.key,
      labelEn: field.labelEn,
      labelAr: field.labelAr,
      labelZh: field.labelZh,
      type: field.type,
      options: field.options,
    };
  }

  private toForm(form: CollectionForm, fieldRows: CollectionFormField[]) {
    const mine = fieldRows
      .filter((row) => row.collectionId === form.id)
      .sort((a, b) => a.position - b.position);
    return {
      id: form.id,
      nameEn: form.nameEn,
      nameAr: form.nameAr,
      nameZh: form.nameZh,
      active: form.active,
      fields: this.toDefs(mine),
    };
  }

  private toOwnResponse(row: CollectionFormResponse | null) {
    if (!row) return null;
    return {
      answers: row.answers,
      updatedAt: new Date(row.updatedAt).toISOString(),
    };
  }

  private fieldError(error: unknown): BadRequestException {
    const code = error instanceof Error ? error.message : '';
    switch (code) {
      case 'FIELD_COUNT':
        return new BadRequestException('Add between 1 and 12 fields');
      case 'FIELD_KEY':
        return new BadRequestException(
          'Each field needs a unique key like item_name',
        );
      case 'FIELD_LABEL':
        return new BadRequestException(
          'Each field needs a name in English, Arabic, and Chinese',
        );
      case 'FIELD_OPTIONS':
        return new BadRequestException(
          'A choice needs 2 to 8 options, and other fields have none',
        );
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the form fields');
    }
  }

  private answerError(error: unknown): BadRequestException {
    const code = error instanceof Error ? error.message : '';
    switch (code) {
      case 'FIELD_REQUIRED':
        return new BadRequestException('Fill every required field');
      case 'FIELD_TOO_LONG':
        return new BadRequestException('One answer is too long');
      case 'FIELD_NUMBER':
        return new BadRequestException('Enter a number');
      case 'FIELD_CHOICE':
        return new BadRequestException('Choose one of the options');
      default:
        if (error instanceof Error) throw error;
        return new BadRequestException('Check the answers');
    }
  }

  private async requireStaff(actor: AuthUser): Promise<User> {
    const user = await this.users.findOne({ where: { id: actor.userId } });
    if (
      !user ||
      user.deletedAt ||
      (user.role !== UserRole.Employee && user.role !== UserRole.SuperAdmin)
    ) {
      throw new ForbiddenException('Staff only');
    }
    return user;
  }

  private async requireReviewer(actor: AuthUser): Promise<User> {
    const user = await this.requireStaff(actor);
    if (!canOpenInternalOps(user)) {
      throw new ForbiddenException('SuperAdmin or Internal Ops only');
    }
    return user;
  }

  private async requireSuperAdmin(actor: AuthUser): Promise<User> {
    const user = await this.requireStaff(actor);
    if (user.role !== UserRole.SuperAdmin) {
      throw new ForbiddenException('SuperAdmin only');
    }
    return user;
  }

  private async audit(
    actorId: string,
    action: string,
    resourceId: string,
    meta: Record<string, unknown>,
  ) {
    await this.auditLogs.save(
      this.auditLogs.create({
        actorId,
        action,
        resourceType: 'collection_form',
        resourceId,
        meta,
      }),
    );
  }
}

function isUniqueViolation(error: unknown): boolean {
  if (!error || typeof error !== 'object') return false;
  const row = error as { code?: string; driverError?: { code?: string } };
  return row.code === '23505' || row.driverError?.code === '23505';
}
