// Made by Dr Ali
// Users controller — private routes require JWT; ownership = subject from token.

import {
  Body,
  Controller,
  Delete,
  Get,
  Patch,
  Put,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { ChangeEmailDto } from './dto/change-email.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { UpdateAvatarDto } from './dto/update-avatar.dto';
import { UpdateAddressesDto } from './dto/update-addresses.dto';
import { UpdateMeDto } from './dto/update-me.dto';
import { UpdateMomentsCoverDto } from './dto/update-moments-cover.dto';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@CurrentUser() actor: AuthUser) {
    return this.usersService.findMe(actor);
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard)
  updateMe(@CurrentUser() actor: AuthUser, @Body() dto: UpdateMeDto) {
    return this.usersService.updateMe(actor, dto);
  }

  @Patch('me/password')
  @UseGuards(JwtAuthGuard)
  changePassword(
    @CurrentUser() actor: AuthUser,
    @Body() dto: ChangePasswordDto,
  ) {
    return this.usersService.changePassword(actor, dto);
  }

  @Patch('me/email')
  @UseGuards(JwtAuthGuard)
  changeEmail(@CurrentUser() actor: AuthUser, @Body() dto: ChangeEmailDto) {
    return this.usersService.changeEmail(actor, dto);
  }

  @Patch('me/avatar')
  @UseGuards(JwtAuthGuard)
  updateAvatar(
    @CurrentUser() actor: AuthUser,
    @Body() dto: UpdateAvatarDto,
  ) {
    return this.usersService.updateAvatar(actor, dto.avatarUrl);
  }

  @Patch('me/moments-cover')
  @UseGuards(JwtAuthGuard)
  updateMomentsCover(
    @CurrentUser() actor: AuthUser,
    @Body() dto: UpdateMomentsCoverDto,
  ) {
    return this.usersService.updateMomentsCover(actor, dto.coverUrl);
  }

  @Delete('me')
  @UseGuards(JwtAuthGuard)
  deleteMe(@CurrentUser() actor: AuthUser) {
    return this.usersService.deleteMe(actor);
  }

  @Put('me/addresses')
  @UseGuards(JwtAuthGuard)
  updateAddresses(
    @CurrentUser() actor: AuthUser,
    @Body() dto: UpdateAddressesDto,
  ) {
    return this.usersService.updateAddresses(actor, dto);
  }
}
