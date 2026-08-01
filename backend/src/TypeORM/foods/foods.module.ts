import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Food } from './foods_entity';
import { FoodController } from './foods_controller';
import { FoodService } from './foods_service';

@Module({
  imports: [TypeOrmModule.forFeature([Food])],
  controllers: [FoodController],
  providers: [FoodService],
})
export class FoodsModule {}