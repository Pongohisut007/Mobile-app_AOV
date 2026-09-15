import { IsUUID } from 'class-validator';

export class CreateMockPurchaseDto {
  @IsUUID()
  cartItemId!: string;
}
