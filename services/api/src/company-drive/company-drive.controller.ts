// Made by Dr Ali
// Company drive. Customers receive 403. Downloads stay on the staff route.

import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { memoryStorage } from 'multer';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminTotpEnrollGuard } from '../common/guards/admin-totp-enroll.guard';
import { AdminTotpStepUpGuard } from '../common/guards/admin-totp-stepup.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { DRIVE_FILE_BYTES } from './company-drive';
import { CompanyDriveService, DriveUpload } from './company-drive.service';
import { SaveDriveFolderDto, SetDriveFileActiveDto } from './dto/company-drive.dto';

const driveUpload = FileInterceptor('file', {
  storage: memoryStorage(),
  limits: { fileSize: DRIVE_FILE_BYTES },
});

function asUpload(file: Express.Multer.File | undefined): DriveUpload {
  if (!file?.buffer?.length) throw new BadRequestException('Choose a file');
  return { originalName: file.originalname || '', buffer: file.buffer };
}

@ApiTags('company-drive')
@ApiBearerAuth()
@Controller('company-drive')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class CompanyDriveController {
  constructor(private readonly drive: CompanyDriveService) {}

  @Get()
  mine(@CurrentUser() actor: AuthUser) {
    return this.drive.mine(actor);
  }

  @Get('folders/:id')
  folder(@CurrentUser() actor: AuthUser, @Param('id', ParseUUIDPipe) id: string) {
    return this.drive.mineFolder(actor, id);
  }

  @Post('folders/:id/files')
  @UseInterceptors(driveUpload)
  add(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.drive.addMine(actor, id, asUpload(file));
  }

  @Get('files/:id')
  download(@CurrentUser() actor: AuthUser, @Param('id', ParseUUIDPipe) id: string) {
    return this.drive.downloadMine(actor, id);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/company-drive')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminCompanyDriveController {
  constructor(private readonly drive: CompanyDriveService) {}

  @Get()
  board(@CurrentUser() actor: AuthUser) {
    return this.drive.board(actor);
  }

  @Post('folders')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveDriveFolderDto) {
    return this.drive.saveFolder(actor, dto);
  }

  @Patch('folders/:id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveDriveFolderDto,
  ) {
    return this.drive.saveFolder(actor, dto, id);
  }

  @Get('folders/:id')
  folder(@CurrentUser() actor: AuthUser, @Param('id', ParseUUIDPipe) id: string) {
    return this.drive.adminFolder(actor, id);
  }

  @Post('folders/:id/files')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  @UseInterceptors(driveUpload)
  add(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.drive.addAdmin(actor, id, asUpload(file));
  }

  @Patch('files/:id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  setActive(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SetDriveFileActiveDto,
  ) {
    return this.drive.setFileActive(actor, id, dto);
  }

  @Get('files/:id')
  download(@CurrentUser() actor: AuthUser, @Param('id', ParseUUIDPipe) id: string) {
    return this.drive.downloadAdmin(actor, id);
  }
}
