// Made by Dr Ali
// /v1/vip — customer consultations + trip builder.
// /v1/admin/vip — staff: record external payment, assign, official group.

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
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import {
  AssignVipDto,
  CreateConsultationDto,
  CreateGroupDto,
  CreateTripDto,
  MarkPaidDto,
  QuoteTripDto,
  TransitionTripDto,
} from './dto/vip.dto';
import { VipService } from './vip.service';

@ApiTags('vip')
@ApiBearerAuth()
@Controller('vip')
@UseGuards(JwtAuthGuard)
export class VipController {
  constructor(private readonly vip: VipService) {}

  @Post('consultations')
  @ApiOperation({ summary: 'Buy a timed consultation (10/20/30/60 min, USD)' })
  createConsultation(
    @CurrentUser() actor: AuthUser,
    @Body() dto: CreateConsultationDto,
  ) {
    return this.vip.createConsultation(actor, dto);
  }

  @Get('consultations')
  @ApiOperation({ summary: 'My consultations' })
  myConsultations(@CurrentUser() actor: AuthUser) {
    return this.vip.myConsultations(actor);
  }

  @Get('consultations/:id')
  @ApiOperation({ summary: 'Consultation detail with remaining seconds' })
  getConsultation(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.vip.getConsultation(actor, id);
  }

  @Post('consultations/:id/start')
  @ApiOperation({ summary: 'Start a paid consultation — hard stop at duration' })
  start(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.vip.startConsultation(actor, id);
  }

  @Post('consultations/:id/end')
  @ApiOperation({ summary: 'End a running consultation early' })
  end(@CurrentUser() actor: AuthUser, @Param('id', ParseUUIDPipe) id: string) {
    return this.vip.endConsultation(actor, id);
  }

  @Post('consultations/:id/cancel')
  @ApiOperation({ summary: 'Cancel a consultation that has not run' })
  cancelConsultation(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.vip.cancelConsultation(actor, id);
  }

  @Post('trips')
  @ApiOperation({ summary: 'Start a VIP trip request (Draft)' })
  createTrip(@CurrentUser() actor: AuthUser, @Body() dto: CreateTripDto) {
    return this.vip.createTrip(actor, dto);
  }

  @Get('trips')
  @ApiOperation({ summary: 'My VIP trips' })
  myTrips(@CurrentUser() actor: AuthUser) {
    return this.vip.myTrips(actor);
  }

  @Get('trips/:id')
  @ApiOperation({ summary: 'Trip detail with frozen quotation' })
  getTrip(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.vip.getTrip(actor, id);
  }

  @Post('trips/:id/quote')
  @ApiOperation({ summary: 'Compute and freeze a quotation from Active prices' })
  quote(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: QuoteTripDto,
  ) {
    return this.vip.quoteTrip(actor, id, dto);
  }

  @Post('trips/:id/accept')
  @ApiOperation({ summary: 'Accept the frozen quotation' })
  accept(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.vip.acceptTrip(actor, id);
  }

  @Post('trips/:id/cancel')
  @ApiOperation({ summary: 'Cancel my trip' })
  cancelTrip(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.vip.cancelTrip(actor, id);
  }
}

@ApiTags('admin-vip')
@ApiBearerAuth()
@Controller('admin/vip')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.Employee, UserRole.SuperAdmin)
export class AdminVipController {
  constructor(private readonly vip: VipService) {}

  @Get('consultations')
  @ApiOperation({ summary: 'All consultations (staff)' })
  consultations() {
    return this.vip.adminConsultations();
  }

  @Post('consultations/:id/mark-paid')
  @ApiOperation({ summary: 'Record external payment for a consultation' })
  markConsultationPaid(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: MarkPaidDto,
  ) {
    return this.vip.adminMarkConsultationPaid(actor, id, dto);
  }

  @Get('trips')
  @ApiOperation({ summary: 'All VIP trips (staff, optionally ?status=)' })
  trips(@Query('status') status?: string) {
    return this.vip.adminTrips(status);
  }

  @Post('trips/:id/assign')
  @ApiOperation({ summary: 'Assign the responsible VIP employee' })
  assign(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AssignVipDto,
  ) {
    return this.vip.adminAssignTrip(actor, id, dto);
  }

  @Post('trips/:id/mark-paid')
  @ApiOperation({ summary: 'Record external payment for an accepted trip' })
  markTripPaid(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: MarkPaidDto,
  ) {
    return this.vip.adminMarkTripPaid(actor, id, dto);
  }

  @Post('trips/:id/create-group')
  @ApiOperation({ summary: 'Create the official VIP group (after payment, VIP-001)' })
  createGroup(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CreateGroupDto,
  ) {
    return this.vip.adminCreateGroup(actor, id, dto);
  }

  @Patch('trips/:id/transition')
  @ApiOperation({ summary: 'Move a trip through its workflow states' })
  transition(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: TransitionTripDto,
  ) {
    return this.vip.adminTransitionTrip(actor, id, dto);
  }
}
