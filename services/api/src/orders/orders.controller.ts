// Made by Dr Ali
// POST/GET /v1/orders — JWT required; userId from token only.

import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { PhoneVerifiedGuard } from '../common/guards/phone-verified.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { CreateOrderDto } from './dto/create-order.dto';
import { OrdersService } from './orders.service';

@Controller('orders')
@UseGuards(JwtAuthGuard, PhoneVerifiedGuard)
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  create(@CurrentUser() actor: AuthUser, @Body() dto: CreateOrderDto) {
    return this.ordersService.create(actor, dto);
  }

  @Get()
  listMine(@CurrentUser() actor: AuthUser) {
    return this.ordersService.listMine(actor);
  }

  @Get(':id/chat')
  openChat(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.ordersService.openChat(actor, id);
  }

  @Get(':id')
  getMine(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.ordersService.getMine(actor, id);
  }
}
