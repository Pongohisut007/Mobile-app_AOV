import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OrdersService } from './orders.service';
import { OrderItem } from './entities/order-item.entity';
import { Order } from './entities/order.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Order, OrderItem])],
  // ไม่มี controller: คำสั่งซื้อสร้างผ่าน /iap เท่านั้น (เดิมเปิด CRUD ให้ทุกคนโดยไม่ต้อง login)
  providers: [OrdersService],
})
export class OrdersModule {}
