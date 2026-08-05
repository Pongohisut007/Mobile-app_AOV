import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',

        host: config.getOrThrow<string>('database.host'),
        port: config.getOrThrow<number>('database.port'),
        username: config.getOrThrow<string>('database.username'),
        password: config.getOrThrow<string>('database.password'),
        database: config.getOrThrow<string>('database.name'),

        autoLoadEntities: true,

        // เปิดใช้งานเฉพาะตอนพัฒนา
        synchronize: config.get<string>('NODE_ENV') !== 'production',

        migrations: [`${__dirname}/migrations/*{.ts,.js}`],
      }),
    }),
  ],
})
export class DatabaseModule {}