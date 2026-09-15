import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateMockPurchaseDto } from './dto/create-mock-purchase.dto';
import { IapService, MockPurchaseResult } from './iap.service';

@UseGuards(JwtAuthGuard)
@Controller('iap')
export class IapController {
  constructor(private readonly iapService: IapService) {}

  /**
   * Development-only stand-in for Google Play purchase verification.
   * It intentionally accepts a cart item, not a price or success flag from the app.
   */
  @Post('mock/purchases')
  createMockPurchase(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateMockPurchaseDto,
  ): Promise<MockPurchaseResult> {
    return this.iapService.createMockPurchase(userId, dto.cartItemId);
  }
}
