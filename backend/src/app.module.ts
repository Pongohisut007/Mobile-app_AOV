import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { TypeormModule } from './TypeORM/typeorm.module';
import { UsersModule } from './TypeORM/users/users.module';
import { FoodsModule } from './TypeORM/foods/foods.module';




@Module({
  imports: [TypeormModule, UsersModule, FoodsModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
