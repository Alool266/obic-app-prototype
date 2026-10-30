// Made by Dr Ali

import {
  IsArray,
  IsBoolean,
  IsIn,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { PRICE_STATUSES } from '../../prices/price';
import {
  ACCOUNTANT_TIERS,
  REGISTRATION_DOC_TYPES,
  REGISTRATION_STATUSES,
} from '../registration';

export class EligibilityCheckDto {
  @IsString()
  @MinLength(1)
  @MaxLength(60)
  city!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  activity!: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  nationality?: string;

  @IsBoolean()
  insideChina!: boolean;
}

export class CreateRegistrationDto extends EligibilityCheckDto {
  @IsOptional()
  @IsString()
  @MaxLength(80)
  area?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  qualification?: string;

  @IsOptional()
  @IsIn(ACCOUNTANT_TIERS)
  accountantTier?: (typeof ACCOUNTANT_TIERS)[number];

  @IsOptional()
  @IsBoolean()
  includeWorkResidence?: boolean;

  @IsOptional()
  @IsObject()
  formData?: Record<string, unknown>;
}

export class UpdateRegistrationDto {
  @IsOptional()
  @IsIn(ACCOUNTANT_TIERS)
  accountantTier?: (typeof ACCOUNTANT_TIERS)[number];

  @IsOptional()
  @IsBoolean()
  includeWorkResidence?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  qualification?: string;

  @IsOptional()
  @IsObject()
  formData?: Record<string, unknown>;
}

export class UploadRegistrationDocDto {
  @IsIn(REGISTRATION_DOC_TYPES)
  docType!: (typeof REGISTRATION_DOC_TYPES)[number];

  @IsString()
  @MinLength(1)
  @MaxLength(1024)
  fileUrl!: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  fileName?: string;
}

export class ReviewRegistrationDocDto {
  @IsIn(['approve', 'request_correction', 'block'])
  decision!: 'approve' | 'request_correction' | 'block';

  /** Required for request_correction / block: field + reason for the customer. */
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;
}

export class TransitionRegistrationDto {
  @IsIn(REGISTRATION_STATUSES)
  status!: (typeof REGISTRATION_STATUSES)[number];

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;
}

export class AssignRegistrationDto {
  @IsUUID()
  employeeId!: string;
}

export class ExtractDocumentDto {
  @IsString()
  @MaxLength(6_000_000)
  dataBase64!: string;

  @IsString()
  @MaxLength(80)
  mime!: string;

  /** What the customer typed for the passport fields (compared, never edited). */
  @IsOptional()
  @IsObject()
  typedValues?: Record<string, unknown>;
}

export class ReviewExtractionDto {
  @IsIn(['confirm', 'reject'])
  decision!: 'confirm' | 'reject';

  /** Required on reject: exactly what the customer must fix. */
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;
}

export class CreateEligibilityRuleDto {
  @IsString()
  @MinLength(1)
  @MaxLength(32)
  version!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(60)
  city!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  activity!: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  nationality?: string;

  @IsOptional()
  @IsBoolean()
  insideChina?: boolean;

  @IsIn(['eligible', 'ineligible'])
  outcome!: 'eligible' | 'ineligible';

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  reason?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  alternativeCities?: string[];

  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  effectiveFrom?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  sourceRef?: string;
}

export class TransitionEligibilityRuleDto {
  @IsIn(PRICE_STATUSES)
  status!: (typeof PRICE_STATUSES)[number];

  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  effectiveFrom?: string;
}
