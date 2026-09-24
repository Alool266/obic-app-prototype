// Made by Dr Ali
// GET /v1/services — public catalog (guest browse OK).

import { Controller, Get, Param, Query } from '@nestjs/common';
import { ServicesService } from './services.service';

@Controller('services')
export class ServicesController {
  constructor(private readonly servicesService: ServicesService) {}

  @Get()
  list(
    @Query('country') country?: string,
    @Query('city') _city?: string,
    @Query('includeUnavailable') includeUnavailable?: string,
  ) {
    return this.servicesService.listActive(
      country,
      includeUnavailable === 'true' || includeUnavailable === '1',
    );
  }

  @Get(':parentSlug/sub-services')
  listSubServices(
    @Param('parentSlug') parentSlug: string,
    @Query('country') country?: string,
    @Query('city') _city?: string,
    @Query('includeUnavailable') includeUnavailable?: string,
  ) {
    return this.servicesService.listSubServicesByParentSlug(
      parentSlug,
      country,
      includeUnavailable === 'true' || includeUnavailable === '1',
    );
  }

  @Get(':idOrSlug')
  one(@Param('idOrSlug') idOrSlug: string) {
    return this.servicesService.findByIdOrSlug(idOrSlug);
  }
}
