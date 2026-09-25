// Made by Dr Ali
// Users controller — private routes require JWT; ownership = subject from token.

import { Body, Controller, Get, Patch, Put, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { ChangePasswordDto } from './dto/change-password.dto';
import { UpdateAvatarDto } from './dto/update-avatar.dto';
import { UpdateAddressesDto } from './dto/update-addresses.dto';
import { UpdateMeDto } from './dto/update-me.dto';
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

  @Patch('me/avatar')
  @UseGuards(JwtAuthGuard)
  updateAvatar(
    @CurrentUser() actor: AuthUser,
    @Body() dto: UpdateAvatarDto,
  ) {
    return this.usersService.updateAvatar(actor, dto.avatarUrl);
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
