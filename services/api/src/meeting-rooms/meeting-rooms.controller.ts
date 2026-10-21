// Made by Dr Ali
// Meeting rooms. Customers receive 403. The desk is SuperAdmin and Internal Ops.

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
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminTotpEnrollGuard } from '../common/guards/admin-totp-enroll.guard';
import { AdminTotpStepUpGuard } from '../common/guards/admin-totp-stepup.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { BookMeetingRoomDto, SaveMeetingRoomDto } from './dto/meeting-room.dto';
import { MeetingRoomsService } from './meeting-rooms.service';

@ApiTags('meeting-rooms')
@ApiBearerAuth()
@Controller('meeting-rooms')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class MeetingRoomsController {
  constructor(private readonly rooms: MeetingRoomsService) {}

  @Get()
  schedule(
    @CurrentUser() actor: AuthUser,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.rooms.schedule(actor, from, to);
  }

  @Post('bookings')
  book(@CurrentUser() actor: AuthUser, @Body() dto: BookMeetingRoomDto) {
    return this.rooms.book(actor, dto);
  }

  @Post('bookings/:id/cancel')
  cancel(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.rooms.cancel(actor, id);
  }
}

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin/meeting-rooms')
@UseGuards(JwtAuthGuard, RolesGuard, AdminTotpEnrollGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminMeetingRoomsController {
  constructor(private readonly rooms: MeetingRoomsService) {}

  @Get()
  board(
    @CurrentUser() actor: AuthUser,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.rooms.board(actor, from, to);
  }

  @Post()
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  create(@CurrentUser() actor: AuthUser, @Body() dto: SaveMeetingRoomDto) {
    return this.rooms.createRoom(actor, dto);
  }

  @Patch(':id')
  @Roles(UserRole.SuperAdmin)
  @UseGuards(AdminTotpStepUpGuard)
  update(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveMeetingRoomDto,
  ) {
    return this.rooms.updateRoom(actor, id, dto);
  }
}
