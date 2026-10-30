// Made by Dr Ali
// Staff fill a form. The submission keeps the field list from the moment it was sent.

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { AuditLog } from '../chat/audit-log.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { canOpenInternalOps } from '../users/user.mapper';
import { User } from '../users/user.entity';
import { SaveOfficeFormDto, SubmitOfficeFormDto } from './dto/office-form.dto';
import {
  assertOfficeFields,
  isOfficeFieldType,
  validateOfficeAnswers,
  type OfficeFieldDef,
} from './office-form';
import {
  OfficeForm,
  OfficeFormField,
  OfficeFormSubmission,
  type OfficeFieldSnapshot,
} from './office-form.entities';

const LIST_LIMIT = 40;

@Injectable()
export class OfficeFormsService {
  constructor(
    @InjectRepository(OfficeForm)
    private readonly forms: Repository<OfficeForm>,
    @InjectRepository(OfficeFormField)
    private readonly fields: Repository<OfficeFormField>,
    @InjectRepository(OfficeFormSubmission)
    private readonly submissions: Repository<OfficeFormSubmission>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
  ) {}

  async home(actor: AuthUser) {
    const user = await this.requireStaff(actor);
    const forms = await this.forms.find({
      where: { active: true },
      order: { nameEn: 'ASC' },
    });
    const fieldRows = await this.fieldsFor(forms.map((form) => form.id));
    const rows = await this.submissions.find({
      where: { userId: user.id },
      order: { createdAt: 'DESC' },
      take: LIST_LIMIT,
    });
    return {
      forms: forms.map((form) => this.toForm(form, fieldRows)),
      submissions: await this.toSubmissions(rows, forms),
    };
  }

  async submit(actor: AuthUser, dto: SubmitOfficeFormDto) {
    const user = await this.requireStaff(actor);
    const form = await this.forms.findOne({ where: { id: dto.formId } });
    if (!form || !form.active) {
      throw new BadRequestException('This form is paused');
    }
    const defs = this.toDefs(
      await this.fields.find({
        where: { formId: form.id },
        order: { position: 'ASC' },
      }),
    );
    let answers: Record<string, string>;
    try {
      answers = validateOfficeAnswers(defs, dto.answers ?? {});
    } catch (error) {
      throw this.answerError(error);
    }
    const saved = await this.submissions.save(
      this.submissions.create({
        formId: form.id,
        userId: user.id,
        answers,
        fieldsSnapshot: defs.map((field) => this.toSnapshot(field)),
      }),
    );
    await this.audit(user.id, 'office_form_submit', saved.id, {
      formId: form.id,
    });
    const [card] = await this.toSubmissions([saved], [form]);
    if (!card) throw new NotFoundException('Form was not saved');
    return card;
  }

  async board(actor: AuthUser) {
    await this.requireReviewer(actor);
    const forms = await this.forms.find({ order: { nameEn: 'ASC' } });
    const fieldRows = await this.fieldsFor(forms.map((form) => form.id));
    const rows = await this.submissions.find({
      order: { createdAt: 'DESC' },
      take: LIST_LIMIT,
    });
    return {
      forms: forms.map((form) => this.toForm(form, fieldRows)),
      submissions: await this.toSubmissions(rows, forms),
    };
  }

  async create(actor: AuthUser, dto: SaveOfficeFormDto) {
    const user = await this.requireSuperAdmin(actor);
    const defs = this.checkedFields(dto);
    const saved = await this.forms.manager.transaction(async (manager) => {
      const form = await manager.save(
        manager.create(OfficeForm, {
          nameEn: dto.nameEn.trim(),
          nameAr: dto.nameAr.trim(),
          nameZh: dto.nameZh.trim(),
          active: dto.active,
        }),
      );
      await manager.save(
        defs.map((field, position) =>
          manager.create(OfficeFormField, this.toFieldRow(form.id, position, field)),
        ),
      );
      return form;
    });
    await this.audit(user.id, 'admin_create_office_form', saved.id, {
      nameEn: saved.nameEn,
    });
    return this.board(actor);
  }

  async update(actor: AuthUser, id: string, dto: SaveOfficeFormDto) {
    const user = await this.requireSuperAdmin(actor);
    const form = await this.forms.findOne({ where: { id } });
    if (!form) throw new NotFoundException('Form not found');
    const defs = this.checkedFields(dto);
    form.nameEn = dto.nameEn.trim();
    form.nameAr = dto.nameAr.trim();
    form.nameZh = dto.nameZh.trim();
    form.active = dto.active;
    await this.forms.manager.transaction(async (manager) => {
      await manager.save(form);
      await manager.delete(OfficeFormField, { formId: form.id });
      await manager.save(
        defs.map((field, position) =>
          manager.create(OfficeFormField, this.toFieldRow(form.id, position, field)),
        ),
      );
    });
    await this.audit(user.id, 'admin_update_office_form', form.id, {
      active: form.active,
    });
    return this.board(actor);
  }

  private checkedFields(dto: SaveOfficeFormDto): OfficeFieldDef[] {
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

  private toFieldRow(formId: string, position: number, field: OfficeFieldDef) {
    return {
      formId,
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

  private toDefs(rows: OfficeFormField[]): OfficeFieldDef[] {
    return rows.map((row) => ({
      key: row.fieldKey,
      labelEn: row.labelEn,
      labelAr: row.labelAr,
      labelZh: row.labelZh,
      type: isOfficeFieldType(row.fieldType) ? row.fieldType : 'short_text',
      required: row.required,
      options: Array.isArray(row.options) ? row.options : [],
    }));
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

  private toForm(form: OfficeForm, fieldRows: OfficeFormField[]) {
    const mine = fieldRows
      .filter((row) => row.formId === form.id)
      .sort((a, b) => a.position - b.position);
    return {
      id: form.id,
      nameEn: form.nameEn,
      nameAr: form.nameAr,
      nameZh: form.nameZh,
      active: form.active,
      fields: this.toDefs(mine).map((field) => ({ ...field })),
    };
  }

  private async fieldsFor(formIds: string[]): Promise<OfficeFormField[]> {
    if (!formIds.length) return [];
    return this.fields.find({
      where: { formId: In(formIds) },
      order: { position: 'ASC' },
    });
  }

  private async toSubmissions(rows: OfficeFormSubmission[], known: OfficeForm[]) {
    const missing = [
      ...new Set(rows.map((row) => row.formId)),
    ].filter((id) => !known.some((form) => form.id === id));
    const loaded = missing.length
      ? await this.forms.find({ where: { id: In(missing) } })
      : [];
    const forms = [...known, ...loaded];
    const userIds = [...new Set(rows.map((row) => row.userId))];
    const people = userIds.length
      ? await this.users.find({ where: { id: In(userIds) } })
      : [];
    return rows.map((row) => {
      const form = forms.find((item) => item.id === row.formId);
      return {
        id: row.id,
        formId: row.formId,
        formNameEn: form?.nameEn ?? '',
        formNameAr: form?.nameAr ?? '',
        formNameZh: form?.nameZh ?? '',
        authorId: row.userId,
        authorName: people.find((person) => person.id === row.userId)?.name ?? '',
        answers: row.answers,
        fields: row.fieldsSnapshot,
        createdAt: new Date(row.createdAt).toISOString(),
      };
    });
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
        resourceType: 'office_form',
        resourceId,
        meta,
      }),
    );
  }
}
