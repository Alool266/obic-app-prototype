// Made by Dr Ali
// Admin DTOs — whitelist only; never accept client-supplied actor ids for AuthZ.

import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';
import { OrderStatus } from '../../orders/order.entity';
import { UserRole } from '../../common/enums/user-role.enum';

export class AdminUpdateOrderDto {
  @IsOptional()
  @IsEnum(OrderStatus)
  status?: OrderStatus;

  /**
   * Assign to an Employee — SuperAdmin, or Form2 sales-rep / branch manager
   * (branch-scoped). null clears assignment.
   */
  @IsOptional()
  @ValidateIf((_, v) => v !== null && v !== undefined)
  @IsUUID()
  assignedEmployeeId?: string | null;
}

export class AdminUpdateStaffRoleDto {
  @IsEnum(UserRole)
  role!: UserRole;
}

/**
 * Form2 rule 5 — SuperAdmin creates Employee from Admin.
 * Email or phone required (production contacts filled later via profile edit).
 */
export class AdminCreateStaffDto {
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(320)
  email?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  @Matches(/^[0-9+()\-\s]*$/, {
    message: 'Phone may only contain digits and +()- space',
  })
  phone?: string | null;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  staffTitle?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  branchLabel?: string | null;
}

/** SuperAdmin edits staff profile / temp desk labels. Privilege stays on `role`. */
export class AdminUpdateStaffProfileDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  @Matches(/^[0-9+()\-\s]*$/, {
    message: 'Phone may only contain digits and +()- space',
  })
  phone?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  staffTitle?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  branchLabel?: string | null;

  /** Optional public avatar URL (from /v1/uploads). */
  @IsOptional()
  @IsString()
  @MaxLength(1024)
  avatarUrl?: string | null;

  /**
   * Allow Employee to open Internal Ops. Ignored for SuperAdmin targets
   * (SuperAdmin always has Ops). Cleared automatically if role → Customer.
   */
  @IsOptional()
  @IsBoolean()
  opsAccess?: boolean;

  /**
   * Allow Employee to manage hotel/flight offers. Ignored for SuperAdmin targets
   * (SuperAdmin always can). Cleared automatically if role → Customer.
   */
  @IsOptional()
  @IsBoolean()
  offersAccess?: boolean;

  @IsOptional()
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  newPassword?: string;
}

/** SuperAdmin — global AI auto-reply kill-switch (DB). */
export class AdminAiSettingsDto {
  @IsBoolean()
  globalAutoReplyEnabled!: boolean;
}
