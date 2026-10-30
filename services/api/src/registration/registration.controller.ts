// Made by Dr Ali
// /v1/registration — customer Non-VIP company-registration flow.
// /v1/admin/registration — staff review queue + assignment + state moves.
// /v1/admin/eligibility-rules — SuperAdmin versioned eligibility matrix (TOTP).

import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminTotpStepUpGuard } from '../common/guards/admin-totp-stepup.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
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
import { RegistrationService } from './registration.service';

@ApiTags('registration')
@ApiBearerAuth()
@Controller('registration')
@UseGuards(JwtAuthGuard)
export class RegistrationController {
  constructor(private readonly registration: RegistrationService) {}

  @Post('eligibility/check')
  @ApiOperation({ summary: 'Check city/activity eligibility (approved rules only)' })
  check(@Body() dto: EligibilityCheckDto) {
    return this.registration.checkEligibility(dto);
  }

  @Post('applications')
  @ApiOperation({ summary: 'Start a company-registration application (Draft)' })
  create(@CurrentUser() actor: AuthUser, @Body() dto: CreateRegistrationDto) {
    return this.registration.createApplication(actor, dto);
  }

  @Get('applications')
  @ApiOperation({ summary: 'My registration applications' })
  mine(@CurrentUser() actor: AuthUser) {
    return this.registration.myApplications(actor);
  }

  @Get('applications/:id')
  @ApiOperation({ summary: 'Application detail with documents and timeline' })
  get(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.registration.getApplication(actor, id);
  }

  @Patch('applications/:id')
  @ApiOperation({ summary: 'Edit a Draft / needs-action application' })
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateRegistrationDto,
  ) {
    return this.registration.updateApplication(actor, id, dto);
  }

  @Post('applications/:id/documents')
  @ApiOperation({ summary: 'Upload (or re-upload) a checklist document' })
  upload(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UploadRegistrationDocDto,
  ) {
    return this.registration.uploadDocument(actor, id, dto);
  }

  @Post('applications/:id/documents/:docId/extract')
  @ApiOperation({ summary: 'Read an uploaded passport photo (OCR) for staff review' })
  extract(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('docId', ParseUUIDPipe) docId: string,
    @Body() dto: ExtractDocumentDto,
  ) {
    return this.registration.extractDocument(actor, id, docId, dto);
  }

  @Post('applications/:id/submit')
  @ApiOperation({ summary: 'Submit: freezes the Active-price basket snapshot' })
  submit(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.registration.submit(actor, id);
  }

  @Post('applications/:id/cancel')
  @ApiOperation({ summary: 'Cancel my application' })
  cancel(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body('note') note?: string,
  ) {
    return this.registration.cancel(actor, id, note);
  }
}

@ApiTags('admin-registration')
@ApiBearerAuth()
@Controller('admin/registration')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminRegistrationController {
  constructor(private readonly registration: RegistrationService) {}

  @Get('applications')
  @ApiOperation({ summary: 'Staff review queue (optionally ?status=)' })
  list(@Query('status') status?: string) {
    return this.registration.staffList(status);
  }

  @Get('applications/:id')
  @ApiOperation({ summary: 'Staff application detail' })
  get(@Param('id', ParseUUIDPipe) id: string) {
    return this.registration.staffDetail(id);
  }

  @Post('applications/:id/assign')
  @ApiOperation({ summary: 'Assign the responsible employee' })
  assign(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AssignRegistrationDto,
  ) {
    return this.registration.staffAssign(actor, id, dto);
  }

  @Patch('applications/:id/transition')
  @ApiOperation({ summary: 'Move the application through the review states' })
  transition(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: TransitionRegistrationDto,
  ) {
    return this.registration.staffTransition(actor, id, dto);
  }

  @Get('ocr-queue')
  @ApiOperation({ summary: 'Passport readings waiting for a human decision' })
  ocrQueue() {
    return this.registration.ocrQueue();
  }

  @Post('extractions/:extractionId/review')
  @ApiOperation({ summary: 'Confirm or reject a passport reading (human decision)' })
  reviewExtraction(
    @CurrentUser() actor: AuthUser,
    @Param('extractionId', ParseUUIDPipe) extractionId: string,
    @Body() dto: ReviewExtractionDto,
  ) {
    return this.registration.reviewExtraction(actor, extractionId, dto);
  }

  @Post('applications/:id/documents/:docId/review')
  @ApiOperation({ summary: 'Approve / request correction / block a document' })
  review(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('docId', ParseUUIDPipe) docId: string,
    @Body() dto: ReviewRegistrationDocDto,
  ) {
    return this.registration.staffReviewDocument(actor, id, docId, dto);
  }
}

@ApiTags('admin-eligibility-rules')
@ApiBearerAuth()
@Controller('admin/eligibility-rules')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SuperAdmin)
export class AdminEligibilityRulesController {
  constructor(private readonly registration: RegistrationService) {}

  @Get()
  @ApiOperation({ summary: 'List every eligibility rule version (SuperAdmin)' })
  list() {
    return this.registration.adminListRules();
  }

  @Post()
  @ApiOperation({ summary: 'Create a Draft eligibility rule (SuperAdmin)' })
  create(@CurrentUser() actor: AuthUser, @Body() dto: CreateEligibilityRuleDto) {
    return this.registration.adminCreateRule(actor, dto);
  }

  @Patch(':id/transition')
  @UseGuards(AdminTotpStepUpGuard)
  @ApiOperation({ summary: 'Move a rule Draft → Review → Approved → Active → Retired' })
  transition(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: TransitionEligibilityRuleDto,
  ) {
    return this.registration.adminTransitionRule(actor, id, dto);
  }
}
