// Made by Dr Ali

import { Module } from '@nestjs/common';
import {
  AdminHubContentController,
  HubContentController,
} from './hub-content.controller';
import { HubContentService } from './hub-content.service';

@Module({
  controllers: [HubContentController, AdminHubContentController],
  providers: [HubContentService],
  exports: [HubContentService],
})
export class HubContentModule {}
