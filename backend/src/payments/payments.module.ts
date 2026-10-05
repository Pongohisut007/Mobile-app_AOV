import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PaymentsService } from './payments.service';
import { Payment } from './entities/payment.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Payment])],
  // ไม่มี controller: การจ่ายเงินบันทึกผ่าน /iap เท่านั้น
  providers: [PaymentsService],
})
export class PaymentsModule {}
