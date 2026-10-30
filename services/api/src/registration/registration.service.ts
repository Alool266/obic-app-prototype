// Made by Dr Ali
// Non-VIP company-registration applications: eligibility (approved rules
// only), mandatory checkout basket frozen from Active price versions,
// document checklist with Green/Yellow/Red review, correction/resubmit loop
// with full version history. No payment is taken here — payments wait for
// the written provider decision (boss C6).

import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AiService } from '../ai/ai.service';
import { AuditLog } from '../chat/audit-log.entity';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import {
  assertActivatable,
  assertPriceTransition,
  computeQuoteTotals,
  type PriceStatus,
} from '../prices/price';
import { PricesService } from '../prices/prices.service';
import {
  AssignRegistrationDto,
  CreateEligibilityRuleDto,
  CreateRegistrationDto,
  EligibilityCheckDto,
  ExtractDocumentDto,
  ReviewExtractionDto,
  ReviewRegistrationDocDto,
  TransitionEligibilityRuleDto,
  TransitionRegistrationDto,
  UpdateRegistrationDto,
  UploadRegistrationDocDto,
} from './dto/registration.dto';
import { DocumentExtraction } from './document-extraction.entity';
import { EligibilityRule } from './eligibility-rule.entity';
import {
  buildComparisons,
  hasMismatch,
  parsePassportExtraction,
  PASSPORT_FIELDS,
  type PassportField,
} from './ocr';
import { RegistrationApplication } from './registration-application.entity';
import { RegistrationDocument } from './registration-document.entity';
import { RegistrationEvent } from './registration-event.entity';
import {
  assertRegistrationTransition,
  buildChecklist,
  cityCodeFor,
  docStatusColor,
  isTerminalRegistrationStatus,
  mandatoryBasketPriceIds,
  resolveEligibility,
  type RegistrationStatus,
} from './registration';

@Injectable()
export class RegistrationService {
  constructor(
    @InjectRepository(RegistrationApplication)
    private readonly applications: Repository<RegistrationApplication>,
    @InjectRepository(RegistrationDocument)
    private readonly documents: Repository<RegistrationDocument>,
    @InjectRepository(RegistrationEvent)
    private readonly events: Repository<RegistrationEvent>,
    @InjectRepository(EligibilityRule)
    private readonly rules: Repository<EligibilityRule>,
    @InjectRepository(AuditLog)
    private readonly auditLogs: Repository<AuditLog>,
    @InjectRepository(DocumentExtraction)
    private readonly extractions: Repository<DocumentExtraction>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    private readonly prices: PricesService,
    private readonly ai: AiService,
    private readonly config: ConfigService,
  ) {}

  // ---------------------------------------------------------- eligibility

  async checkEligibility(dto: EligibilityCheckDto) {
    const rules = await this.activeRules();
    const result = resolveEligibility(rules, dto);
    // For ineligible customers, price the approved alternatives (SH-004).
    const alternatives: Array<{
      city: string;
      quote: unknown;
    }> = [];
    for (const city of result.alternativeCities) {
      try {
        alternatives.push({
          city,
          quote: await this.prices.quote({
            serviceKey: 'company-registration',
            city,
            nationality: dto.nationality,
          }),
        });
      } catch {
        alternatives.push({ city, quote: null });
      }
    }
    return { ...result, alternatives };
  }

  async adminListRules() {
    const rows = await this.rules.find({
      order: { city: 'ASC', activity: 'ASC', version: 'ASC' },
      take: 500,
    });
    return { rows };
  }

  async adminCreateRule(actor: AuthUser, dto: CreateEligibilityRuleDto) {
    const exists = await this.rules.findOne({
      where: { city: dto.city, activity: dto.activity, version: dto.version },
    });
    if (exists) {
      throw new ConflictException(
        'This city, activity and rule version already exist',
      );
    }
    const row = await this.rules.save(
      this.rules.create({
        version: dto.version,
        city: dto.city.trim(),
        activity: dto.activity.trim(),
        nationality: dto.nationality?.trim() ? dto.nationality.trim() : null,
        insideChina: dto.insideChina ?? null,
        outcome: dto.outcome,
        reason: dto.reason?.trim() ? dto.reason.trim() : null,
        alternativeCities: dto.alternativeCities ?? null,
        status: 'Draft',
        effectiveFrom: dto.effectiveFrom ?? null,
        effectiveTo: null,
        approvedBy: null,
        sourceRef: dto.sourceRef?.trim() ? dto.sourceRef.trim() : null,
        createdBy: actor.userId,
      }),
    );
    await this.audit(actor.userId, 'eligibility_rule_create', row.id, {
      city: row.city,
      activity: row.activity,
      version: row.version,
    });
    return row;
  }

  async adminTransitionRule(
    actor: AuthUser,
    id: string,
    dto: TransitionEligibilityRuleDto,
  ) {
    const row = await this.rules.findOne({ where: { id } });
    if (!row) throw new NotFoundException('This eligibility rule was not found');
    try {
      assertPriceTransition(row.status, dto.status);
    } catch {
      throw new BadRequestException(
        `Cannot move a rule from ${row.status} to ${dto.status}`,
      );
    }
    const from: PriceStatus = row.status;
    if (dto.effectiveFrom) row.effectiveFrom = dto.effectiveFrom;
    if (dto.status === 'Approved') row.approvedBy = actor.userId;
    if (dto.status === 'Active') {
      try {
        assertActivatable({
          effectiveFrom: row.effectiveFrom,
          approverId: row.approvedBy,
        });
      } catch {
        throw new BadRequestException(
          'A rule needs an effective date and an approver before it goes active',
        );
      }
    }
    row.status = dto.status;
    const saved = await this.rules.save(row);
    await this.audit(actor.userId, 'eligibility_rule_transition', saved.id, {
      from,
      to: saved.status,
    });
    return saved;
  }

  // --------------------------------------------------------- applications

  async createApplication(actor: AuthUser, dto: CreateRegistrationDto) {
    const rules = await this.activeRules();
    const eligibility = resolveEligibility(rules, dto);
    const trackingId = await this.newTrackingId();
    const app = await this.applications.save(
      this.applications.create({
        userId: actor.userId,
        trackingId,
        contractId: null,
        city: dto.city.trim(),
        area: dto.area?.trim() ? dto.area.trim() : null,
        nationality: dto.nationality?.trim() ? dto.nationality.trim() : null,
        insideChina: dto.insideChina,
        qualification: dto.qualification?.trim()
          ? dto.qualification.trim()
          : null,
        activity: dto.activity.trim(),
        eligibilityOutcome: eligibility.outcome,
        eligibilityRuleVersion: eligibility.ruleVersion,
        eligibilityReason: eligibility.reason,
        accountantTier: dto.accountantTier ?? null,
        includeWorkResidence: dto.includeWorkResidence ?? false,
        status: 'DRAFT',
        priceSnapshot: null,
        formData: dto.formData ?? null,
        assignedEmployeeId: null,
        submittedAt: null,
      }),
    );
    for (const item of buildChecklist(dto.insideChina)) {
      await this.documents.save(
        this.documents.create({
          applicationId: app.id,
          docType: item.docType,
          label: item.label,
          required: item.required,
          status: 'missing',
          version: 0,
          history: [],
        }),
      );
    }
    await this.event(app, actor.userId, 'customer', 'application_created', {
      note: `Eligibility: ${eligibility.outcome}`,
    });
    return this.detail(app);
  }

  async myApplications(actor: AuthUser) {
    const rows = await this.applications.find({
      where: { userId: actor.userId },
      order: { createdAt: 'DESC' },
      take: 100,
    });
    return { rows: rows.map((row) => this.summary(row)) };
  }

  async getApplication(actor: AuthUser, id: string) {
    const app = await this.load(id);
    this.assertCanView(actor, app);
    return this.detail(app);
  }

  async updateApplication(
    actor: AuthUser,
    id: string,
    dto: UpdateRegistrationDto,
  ) {
    const app = await this.load(id);
    if (app.userId !== actor.userId) {
      throw new ForbiddenException('This application belongs to another customer');
    }
    if (app.status !== 'DRAFT' && app.status !== 'NEEDS_CUSTOMER_ACTION') {
      throw new BadRequestException(
        'This application can no longer be edited in its current state',
      );
    }
    if (dto.accountantTier !== undefined) app.accountantTier = dto.accountantTier;
    if (dto.includeWorkResidence !== undefined) {
      app.includeWorkResidence = dto.includeWorkResidence;
    }
    if (dto.qualification !== undefined) {
      app.qualification = dto.qualification.trim() ? dto.qualification.trim() : null;
    }
    if (dto.formData !== undefined) {
      app.formData = { ...(app.formData ?? {}), ...dto.formData };
    }
    const saved = await this.applications.save(app);
    await this.event(saved, actor.userId, 'customer', 'application_updated');
    return this.detail(saved);
  }

  async uploadDocument(
    actor: AuthUser,
    id: string,
    dto: UploadRegistrationDocDto,
  ) {
    const app = await this.load(id);
    if (app.userId !== actor.userId) {
      throw new ForbiddenException('This application belongs to another customer');
    }
    if (isTerminalRegistrationStatus(app.status)) {
      throw new BadRequestException('This application is closed');
    }
    let doc = await this.documents.findOne({
      where: { applicationId: app.id, docType: dto.docType },
    });
    if (!doc) {
      doc = this.documents.create({
        applicationId: app.id,
        docType: dto.docType,
        label: dto.docType,
        required: false,
        status: 'missing',
        version: 0,
        history: [],
      });
    }
    doc.version += 1;
    doc.fileUrl = dto.fileUrl;
    doc.fileName = dto.fileName ?? null;
    doc.status = 'pending';
    doc.reviewNote = null;
    doc.reviewedBy = null;
    doc.reviewedAt = null;
    doc.history = [
      ...(doc.history ?? []),
      {
        version: doc.version,
        action: 'uploaded',
        actorId: actor.userId,
        fileUrl: dto.fileUrl,
        note: null,
        at: new Date().toISOString(),
      },
    ];
    const saved = await this.documents.save(doc);
    await this.event(app, actor.userId, 'customer', 'document_uploaded', {
      field: dto.docType,
      note: `Version ${saved.version}`,
    });
    return this.docDto(saved);
  }

  async submit(actor: AuthUser, id: string) {
    const app = await this.load(id);
    if (app.userId !== actor.userId) {
      throw new ForbiddenException('This application belongs to another customer');
    }
    const resubmitting = app.status === 'NEEDS_CUSTOMER_ACTION';
    if (app.status !== 'DRAFT' && !resubmitting) {
      throw new BadRequestException('Only a draft can be submitted');
    }
    if (app.eligibilityOutcome === 'ineligible') {
      throw new BadRequestException(
        'This city and activity are not eligible. Please choose one of the approved alternative cities.',
      );
    }
    if (!app.accountantTier) {
      throw new BadRequestException(
        'Please choose a General Accountant option before submitting — OBIC never pre-selects it for you.',
      );
    }
    const priceIds = mandatoryBasketPriceIds(app.city, app.accountantTier);
    if (!priceIds) {
      throw new BadRequestException(
        'Company registration is not offered for this city yet',
      );
    }
    if (app.includeWorkResidence) {
      const code = cityCodeFor(app.city);
      if (code) priceIds.push(`PRICE-${code}-WORKRES`);
    }
    const { lines, missing } = await this.prices.activeLinesByPriceIds(priceIds);
    if (missing.length > 0) {
      throw new BadRequestException(
        'Prices for this city are not published yet. Our team has not activated them; please try again later.',
      );
    }
    const currencies = new Set(
      (
        await this.prices.active({ serviceKey: 'company-registration', city: app.city })
      ).rows
        .filter((row) => priceIds.includes(row.priceId))
        .map((row) => row.currency),
    );
    if (currencies.size > 1) {
      throw new BadRequestException('Basket prices use more than one currency');
    }
    const totals = computeQuoteTotals(lines);
    const from = app.status;
    app.priceSnapshot = {
      currency: currencies.values().next().value ?? 'CNY',
      lines,
      totals,
      frozenAt: new Date().toISOString(),
    };
    app.submittedAt = new Date();
    const docs = await this.documents.find({
      where: { applicationId: app.id },
    });
    const hasMissingRequired = docs.some(
      (doc) => doc.required && doc.status !== 'approved' && doc.status !== 'pending',
    );
    // Always land on SUBMITTED first, then route: missing required
    // documents wait in PENDING_DOCUMENTS, complete files go to review.
    const route: RegistrationStatus = hasMissingRequired
      ? 'PENDING_DOCUMENTS'
      : 'UNDER_REVIEW';
    if (resubmitting) {
      this.assertTransition(from, route);
      app.status = route;
    } else {
      this.assertTransition(from, 'SUBMITTED');
      this.assertTransition('SUBMITTED', route);
      app.status = route;
    }
    const saved = await this.applications.save(app);
    await this.event(saved, actor.userId, 'customer', resubmitting ? 'resubmitted' : 'submitted', {
      from,
      to: route,
      delayParty: resubmitting || hasMissingRequired ? 'customer' : null,
    });
    return this.detail(saved);
  }

  async cancel(actor: AuthUser, id: string, note?: string) {
    const app = await this.load(id);
    if (app.userId !== actor.userId && actor.role !== UserRole.SuperAdmin) {
      throw new ForbiddenException('This application belongs to another customer');
    }
    this.assertTransition(app.status, 'CANCELLED');
    const from = app.status;
    app.status = 'CANCELLED';
    const saved = await this.applications.save(app);
    await this.event(
      saved,
      actor.userId,
      app.userId === actor.userId ? 'customer' : 'staff',
      'cancelled',
      { from, to: 'CANCELLED', note: note ?? null },
    );
    return this.detail(saved);
  }

  // ---------------------------------------------------------------- staff

  async staffList(status?: string) {
    const rows = await this.applications.find({
      where: status && this.isStatus(status) ? { status } : {},
      order: { updatedAt: 'DESC' },
      take: 200,
    });
    return { rows: rows.map((row) => this.summary(row)) };
  }

  async staffDetail(id: string) {
    return this.detail(await this.load(id));
  }

  async staffAssign(actor: AuthUser, id: string, dto: AssignRegistrationDto) {
    const app = await this.load(id);
    app.assignedEmployeeId = dto.employeeId;
    const saved = await this.applications.save(app);
    await this.event(saved, actor.userId, 'staff', 'assigned', {
      note: dto.employeeId,
    });
    await this.audit(actor.userId, 'registration_assign', saved.id, {
      employeeId: dto.employeeId,
    });
    return this.detail(saved);
  }

  async staffTransition(
    actor: AuthUser,
    id: string,
    dto: TransitionRegistrationDto,
  ) {
    const app = await this.load(id);
    // Submit/cancel have dedicated customer paths; staff drive review states.
    if (dto.status === 'SUBMITTED' || dto.status === 'DRAFT') {
      throw new BadRequestException('Staff cannot move an application there');
    }
    this.assertTransition(app.status, dto.status);
    if (dto.status === 'APPROVED') {
      const docs = await this.documents.find({
        where: { applicationId: app.id },
      });
      const unapproved = docs.filter(
        (doc) => doc.required && doc.status !== 'approved',
      );
      if (unapproved.length > 0) {
        throw new BadRequestException(
          `Required documents are not all approved: ${unapproved
            .map((doc) => doc.label)
            .join(', ')}`,
        );
      }
      if (!app.contractId) {
        app.contractId = app.trackingId.replace('OBIC-REG-', 'OBIC-CTR-');
      }
    }
    const from = app.status;
    app.status = dto.status;
    const saved = await this.applications.save(app);
    await this.event(saved, actor.userId, 'staff', 'status_changed', {
      from,
      to: dto.status,
      note: dto.note ?? null,
      delayParty: dto.status === 'NEEDS_CUSTOMER_ACTION' ? 'customer' : 'company',
    });
    await this.audit(actor.userId, 'registration_transition', saved.id, {
      from,
      to: dto.status,
    });
    return this.detail(saved);
  }

  async staffReviewDocument(
    actor: AuthUser,
    id: string,
    docId: string,
    dto: ReviewRegistrationDocDto,
  ) {
    const app = await this.load(id);
    const doc = await this.documents.findOne({
      where: { id: docId, applicationId: app.id },
    });
    if (!doc) throw new NotFoundException('This document was not found');
    if (doc.status === 'missing') {
      throw new BadRequestException('The customer has not uploaded this document yet');
    }
    if (
      (dto.decision === 'request_correction' || dto.decision === 'block') &&
      !dto.note?.trim()
    ) {
      throw new BadRequestException(
        'Tell the customer exactly what to fix: name the field/document and the reason.',
      );
    }
    switch (dto.decision) {
      case 'approve':
        doc.status = 'approved';
        break;
      case 'request_correction':
        doc.status = 'correction_requested';
        break;
      case 'block':
        doc.status = 'blocked';
        break;
      default: {
        const neverDecision: never = dto.decision;
        throw new Error(neverDecision);
      }
    }
    doc.reviewNote = dto.note?.trim() ? dto.note.trim() : null;
    doc.reviewedBy = actor.userId;
    doc.reviewedAt = new Date();
    doc.history = [
      ...(doc.history ?? []),
      {
        version: doc.version,
        action: dto.decision,
        actorId: actor.userId,
        fileUrl: doc.fileUrl,
        note: doc.reviewNote,
        at: new Date().toISOString(),
      },
    ];
    const saved = await this.documents.save(doc);
    await this.event(app, actor.userId, 'staff', `document_${dto.decision}`, {
      field: doc.docType,
      note: doc.reviewNote,
    });
    // A correction or block always becomes a clear customer action (NV-007).
    if (
      dto.decision !== 'approve' &&
      !isTerminalRegistrationStatus(app.status) &&
      app.status !== 'NEEDS_CUSTOMER_ACTION'
    ) {
      const from = app.status;
      try {
        assertRegistrationTransition(from, 'NEEDS_CUSTOMER_ACTION');
        app.status = 'NEEDS_CUSTOMER_ACTION';
        await this.applications.save(app);
        await this.event(app, actor.userId, 'staff', 'status_changed', {
          from,
          to: 'NEEDS_CUSTOMER_ACTION',
          note: doc.reviewNote,
          delayParty: 'customer',
        });
      } catch {
        // In states where this move is not allowed (e.g. DRAFT), the
        // document decision stands on its own and the timeline shows it.
      }
    }
    return this.docDto(saved);
  }

  // ------------------------------------------------------------ OCR (M04)

  /** OCR is a high-risk feature in the boss plan — env flag, off by default. */
  private ocrEnabled(): boolean {
    const raw = (this.config.get<string>('OCR_ENABLED') ?? '')
      .trim()
      .toLowerCase();
    return raw === '1' || raw === 'true' || raw === 'yes' || raw === 'on';
  }

  /**
   * Read an uploaded passport photo and store the three-way comparison.
   * The AI only reads; nothing about the customer is edited here (TST-006).
   */
  async extractDocument(
    actor: AuthUser,
    id: string,
    docId: string,
    dto: ExtractDocumentDto,
  ) {
    if (!this.ocrEnabled()) {
      throw new ServiceUnavailableException(
        'Document reading is not enabled yet (OCR_ENABLED)',
      );
    }
    const app = await this.load(id);
    if (app.userId !== actor.userId) {
      throw new ForbiddenException('This application belongs to another customer');
    }
    const doc = await this.documents.findOne({
      where: { id: docId, applicationId: app.id },
    });
    if (!doc) throw new NotFoundException('This document was not found');
    if (doc.docType !== 'passport') {
      throw new BadRequestException(
        'Automatic reading is available for the passport only for now',
      );
    }
    if (doc.version < 1 || !doc.fileUrl) {
      throw new BadRequestException('Upload the passport photo first');
    }
    const result = await this.ai.extractPassportFields({
      userId: actor.userId,
      dataBase64: dto.dataBase64,
      mime: dto.mime,
    });
    const { fields, confidence } = parsePassportExtraction(result.raw);
    const typed = this.pickPassportValues({
      ...(app.formData ?? {}),
      ...(dto.typedValues ?? {}),
    });
    const owner = await this.users.findOne({ where: { id: app.userId } });
    const saved: Partial<Record<PassportField, string | null>> = {
      fullName: owner?.name ?? null,
      nationality: owner?.country ?? null,
    };
    const comparisons = buildComparisons({
      extracted: fields,
      confidence,
      typed,
      saved,
    });
    // A newer read supersedes older unreviewed reads of the same document.
    await this.extractions.update(
      { documentId: doc.id, status: 'pending_review' },
      { status: 'superseded' },
    );
    const savedExtraction = await this.extractions.save(
      this.extractions.create({
        applicationId: app.id,
        documentId: doc.id,
        docType: doc.docType,
        docVersion: doc.version,
        provider: result.provider,
        modelVersion: result.model,
        extractedFields: fields,
        confidence,
        comparisons,
        hasMismatch: hasMismatch(comparisons),
        status: 'pending_review',
        reviewedBy: null,
        reviewedAt: null,
        reviewNote: null,
      }),
    );
    await this.event(app, actor.userId, 'customer', 'document_read', {
      field: doc.docType,
      note: savedExtraction.hasMismatch
        ? 'Differences found — sent to staff review'
        : 'Read — sent to staff review',
    });
    return savedExtraction;
  }

  /** Staff queue: extractions waiting for a human decision, oldest first. */
  async ocrQueue() {
    const rows = await this.extractions.find({
      where: { status: 'pending_review' },
      order: { createdAt: 'ASC' },
      take: 200,
    });
    const appIds = [...new Set(rows.map((row) => row.applicationId))];
    const apps = appIds.length
      ? await this.applications.find({ where: appIds.map((appId) => ({ id: appId })) })
      : [];
    const byId = new Map(apps.map((app) => [app.id, app]));
    return {
      rows: rows.map((row) => ({
        ...row,
        trackingId: byId.get(row.applicationId)?.trackingId ?? null,
        city: byId.get(row.applicationId)?.city ?? null,
        applicationStatus: byId.get(row.applicationId)?.status ?? null,
      })),
    };
  }

  /**
   * Human decision on an extraction. Confirm also approves the passport —
   * the reviewer has now compared document vs typed vs saved. Reject sends
   * the document back to the customer with the exact reason. Customer data
   * is never edited by staff or AI here.
   */
  async reviewExtraction(
    actor: AuthUser,
    extractionId: string,
    dto: ReviewExtractionDto,
  ) {
    const extraction = await this.extractions.findOne({
      where: { id: extractionId },
    });
    if (!extraction) throw new NotFoundException('This reading was not found');
    if (extraction.status !== 'pending_review') {
      throw new BadRequestException('This reading was already decided');
    }
    if (dto.decision === 'reject' && !dto.note?.trim()) {
      throw new BadRequestException(
        'Tell the customer exactly what to fix: name the field and the reason.',
      );
    }
    const app = await this.load(extraction.applicationId);
    const doc = await this.documents.findOne({
      where: { id: extraction.documentId },
    });
    extraction.status = dto.decision === 'confirm' ? 'confirmed' : 'rejected';
    extraction.reviewedBy = actor.userId;
    extraction.reviewedAt = new Date();
    extraction.reviewNote = dto.note?.trim() ? dto.note.trim() : null;
    const saved = await this.extractions.save(extraction);

    if (doc && doc.version === extraction.docVersion) {
      doc.status = dto.decision === 'confirm' ? 'approved' : 'correction_requested';
      doc.reviewNote = extraction.reviewNote;
      doc.reviewedBy = actor.userId;
      doc.reviewedAt = new Date();
      doc.history = [
        ...(doc.history ?? []),
        {
          version: doc.version,
          action: dto.decision === 'confirm' ? 'ocr_confirmed' : 'ocr_rejected',
          actorId: actor.userId,
          fileUrl: doc.fileUrl,
          note: extraction.reviewNote,
          at: new Date().toISOString(),
        },
      ];
      await this.documents.save(doc);
    }
    await this.event(
      app,
      actor.userId,
      'staff',
      dto.decision === 'confirm' ? 'document_read_confirmed' : 'document_read_rejected',
      { field: extraction.docType, note: extraction.reviewNote },
    );
    if (
      dto.decision === 'reject' &&
      !isTerminalRegistrationStatus(app.status) &&
      app.status !== 'NEEDS_CUSTOMER_ACTION' &&
      app.status !== 'DRAFT'
    ) {
      const from = app.status;
      try {
        assertRegistrationTransition(from, 'NEEDS_CUSTOMER_ACTION');
        app.status = 'NEEDS_CUSTOMER_ACTION';
        await this.applications.save(app);
        await this.event(app, actor.userId, 'staff', 'status_changed', {
          from,
          to: 'NEEDS_CUSTOMER_ACTION',
          note: extraction.reviewNote,
          delayParty: 'customer',
        });
      } catch {
        // Document decision stands even if the state move is not allowed.
      }
    }
    await this.audit(actor.userId, 'ocr_review', saved.id, {
      decision: dto.decision,
      applicationId: app.id,
    });
    return saved;
  }

  private pickPassportValues(
    source: Record<string, unknown>,
  ): Partial<Record<PassportField, string | null>> {
    const out: Partial<Record<PassportField, string | null>> = {};
    for (const field of PASSPORT_FIELDS) {
      const value = source[field];
      out[field] = typeof value === 'string' && value.trim() ? value.trim() : null;
    }
    return out;
  }

  // -------------------------------------------------------------- helpers

  private async activeRules(): Promise<EligibilityRule[]> {
    const rows = await this.rules.find({
      where: { status: 'Active' },
      take: 500,
    });
    const today = new Date().toISOString().slice(0, 10);
    return rows.filter(
      (row) =>
        (!row.effectiveFrom || row.effectiveFrom <= today) &&
        (!row.effectiveTo || row.effectiveTo >= today),
    );
  }

  private async load(id: string): Promise<RegistrationApplication> {
    const app = await this.applications.findOne({ where: { id } });
    if (!app) throw new NotFoundException('This application was not found');
    return app;
  }

  private assertCanView(actor: AuthUser, app: RegistrationApplication): void {
    if (app.userId === actor.userId) return;
    if (
      actor.role === UserRole.Employee ||
      actor.role === UserRole.SuperAdmin
    ) {
      return;
    }
    throw new ForbiddenException('This application belongs to another customer');
  }

  private assertTransition(
    from: RegistrationStatus,
    to: RegistrationStatus,
  ): void {
    try {
      assertRegistrationTransition(from, to);
    } catch {
      throw new BadRequestException(
        `Cannot move an application from ${from} to ${to}`,
      );
    }
  }

  private isStatus(value: string): value is RegistrationStatus {
    return [
      'DRAFT',
      'SUBMITTED',
      'PENDING_DOCUMENTS',
      'UNDER_REVIEW',
      'NEEDS_CUSTOMER_ACTION',
      'APPROVED',
      'REJECTED',
      'IN_PROGRESS',
      'COMPLETED',
      'CANCELLED',
    ].includes(value);
  }

  private async newTrackingId(): Promise<string> {
    const year = new Date().getFullYear();
    for (let attempt = 0; attempt < 8; attempt += 1) {
      const suffix = Math.floor(100000 + Math.random() * 900000);
      const candidate = `OBIC-REG-${year}-${suffix}`;
      const exists = await this.applications.findOne({
        where: { trackingId: candidate },
      });
      if (!exists) return candidate;
    }
    throw new ConflictException('Could not allocate a tracking ID');
  }

  private async event(
    app: RegistrationApplication,
    actorId: string | null,
    actorType: 'customer' | 'staff' | 'system',
    action: string,
    opts: {
      from?: string | null;
      to?: string | null;
      field?: string | null;
      note?: string | null;
      delayParty?: string | null;
    } = {},
  ): Promise<void> {
    await this.events.save(
      this.events.create({
        applicationId: app.id,
        actorId,
        actorType,
        action,
        fromStatus: opts.from ?? null,
        toStatus: opts.to ?? null,
        field: opts.field ?? null,
        note: opts.note ?? null,
        delayParty: opts.delayParty ?? null,
        meta: null,
      }),
    );
  }

  private async audit(
    actorId: string,
    action: string,
    resourceId: string,
    meta: Record<string, unknown>,
  ): Promise<void> {
    await this.auditLogs.save(
      this.auditLogs.create({
        actorId,
        action,
        resourceType: 'registration',
        resourceId,
        meta,
      }),
    );
  }

  private summary(app: RegistrationApplication) {
    return {
      id: app.id,
      trackingId: app.trackingId,
      contractId: app.contractId,
      userId: app.userId,
      city: app.city,
      area: app.area,
      nationality: app.nationality,
      insideChina: app.insideChina,
      activity: app.activity,
      eligibilityOutcome: app.eligibilityOutcome,
      status: app.status,
      assignedEmployeeId: app.assignedEmployeeId,
      submittedAt: app.submittedAt,
      createdAt: app.createdAt,
      updatedAt: app.updatedAt,
    };
  }

  private async detail(app: RegistrationApplication) {
    const [documents, events, extractions] = await Promise.all([
      this.documents.find({
        where: { applicationId: app.id },
        order: { createdAt: 'ASC' },
      }),
      this.events.find({
        where: { applicationId: app.id },
        order: { createdAt: 'ASC' },
        take: 500,
      }),
      this.extractions.find({
        where: { applicationId: app.id },
        order: { createdAt: 'DESC' },
        take: 50,
      }),
    ]);
    return {
      ...this.summary(app),
      qualification: app.qualification,
      eligibilityRuleVersion: app.eligibilityRuleVersion,
      eligibilityReason: app.eligibilityReason,
      accountantTier: app.accountantTier,
      includeWorkResidence: app.includeWorkResidence,
      priceSnapshot: app.priceSnapshot,
      formData: app.formData,
      documents: documents.map((doc) => this.docDto(doc)),
      extractions,
      events,
    };
  }

  private docDto(doc: RegistrationDocument) {
    return {
      id: doc.id,
      docType: doc.docType,
      label: doc.label,
      required: doc.required,
      status: doc.status,
      color: docStatusColor(doc.status),
      fileUrl: doc.fileUrl,
      fileName: doc.fileName,
      version: doc.version,
      reviewNote: doc.reviewNote,
      reviewedBy: doc.reviewedBy,
      reviewedAt: doc.reviewedAt,
      history: doc.history ?? [],
    };
  }
}
