// Made by Dr Ali
// Create order body — never accepts userId (taken from JWT).

import { IsObject, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateOrderDto {
  @IsUUID()
  serviceId!: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  preferredBranch?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  subServiceId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  subServiceNameEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  subServiceNameAr?: string;

  @IsOptional()
  @IsObject()
  formData?: Record<string, unknown>;

  @IsOptional()
  @IsString()
  @MaxLength(4000)
  notes?: string;

  /** Optional — links the request to a published, available hotel/flight offer. */
  @IsOptional()
  @IsUUID()
  offerId?: string;
}
