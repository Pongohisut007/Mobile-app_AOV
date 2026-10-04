import { Global, Module } from '@nestjs/common';
import { AppCacheService } from './app-cache.service';

// global: service ไหนก็ inject AppCacheService ได้โดยไม่ต้อง import module นี้ซ้ำ
@Global()
@Module({
  providers: [AppCacheService],
  exports: [AppCacheService],
})
export class AppCacheModule {}

/** ชื่อ namespace ที่ใช้ร่วมกัน (ล้างทั้งกลุ่มเมื่อข้อมูลเปลี่ยน) */
export const CacheNamespace = {
  /** รายการ/รายละเอียดสูตร รวมยอดหัวใจ/รีวิว/คอมเมนต์ */
  recipes: 'recipes',
  categories: 'categories',
  /** สรุปคะแนน + รายการรีวิวของแต่ละสูตร */
  reviews: 'reviews',
  /** รายการคอมเมนต์ของแต่ละสูตร */
  comments: 'comments',
} as const;
