import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { AdminOnly } from '../auth/decorators/admin-only.decorator';
import { BannerService } from './banner.service';
import { CreateBannerDto } from './dto/create-banner.dto';
import { UpdateBannerDto } from './dto/update-banner.dto';
import { Banner } from './entities/banner.entity';

@Controller('banners')
export class BannerController {
  constructor(private readonly bannerService: BannerService) {}

  @Get()
  findAll(): Promise<Banner[]> {
    return this.bannerService.findAll();
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string): Promise<Banner> {
    return this.bannerService.findOne(id);
  }

  @AdminOnly()
  @Post()
  create(@Body() dto: CreateBannerDto): Promise<Banner> {
    return this.bannerService.create(dto);
  }

  @AdminOnly()
  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateBannerDto,
  ): Promise<Banner> {
    return this.bannerService.update(id, dto);
  }

  @AdminOnly()
  @Delete(':id')
  remove(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    return this.bannerService.remove(id);
  }
}
