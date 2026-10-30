// Made by Dr Ali
// Public marketplace catalog for يومي / سفر — served from OUR API only.

import { Controller, Get, Query } from '@nestjs/common';
import { MarketplaceService } from './marketplace.service';

@Controller('marketplace')
export class MarketplaceController {
  constructor(private readonly marketplace: MarketplaceService) {}

  @Get('hotels')
  hotels(@Query('city') city?: string) {
    return this.marketplace.hotels(city);
  }

  @Get('flights')
  flights(@Query('from') from?: string, @Query('to') to?: string) {
    return this.marketplace.flights(from, to);
  }

  @Get('trains')
  trains() {
    return this.marketplace.trains();
  }

  @Get('attractions')
  attractions(@Query('city') city?: string) {
    return this.marketplace.attractions(city);
  }

  @Get('tours')
  tours() {
    return this.marketplace.tours();
  }

  @Get('transfers')
  transfers() {
    return this.marketplace.transfers();
  }

  @Get('cars')
  cars() {
    return this.marketplace.cars();
  }

  @Get('merchants')
  merchants(
    @Query('category') category?: string,
    @Query('city') city?: string,
  ) {
    return this.marketplace.merchants(category, city);
  }

  @Get('promos')
  promos(@Query('scope') scope?: string) {
    return this.marketplace.promos(scope);
  }
}
