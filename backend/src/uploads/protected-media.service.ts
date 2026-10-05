import { Injectable, Optional } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CacheNamespace } from '../cache/app-cache.module';
import { AppCacheService } from '../cache/app-cache.service';

/**
 * ไฟล์นี้อยู่ในขั้นตอนที่ต้องซื้อก่อนดูหรือไม่
 * (section ที่ไม่ใช่ตัวอย่าง ของสูตร official) ถ้าใช่ ต้องเปิดด้วยลิงก์ที่มีลายเซ็น
 * รูปปก/รูปโปรไฟล์/แบนเนอร์ และขั้นตอนตัวอย่าง เปิดได้ตามปกติ
 */
@Injectable()
export class ProtectedMediaService {
  // ผลถูกล้างพร้อม cache สูตร (สร้าง/แก้/ลบสูตร) เลยเก็บได้นาน
  static readonly ttlSeconds = 600;

  constructor(
    private readonly dataSource: DataSource,
    @Optional() private readonly cache?: AppCacheService,
  ) {}

  isProtected(kind: string, filename: string): Promise<boolean> {
    const path = `/uploads/${kind}/${filename}`;
    const load = () => this.lookup(path);
    return this.cache
      ? this.cache.getOrSet(
          CacheNamespace.recipes,
          `protected-media:${path}`,
          ProtectedMediaService.ttlSeconds,
          load,
        )
      : load();
  }

  private async lookup(path: string): Promise<boolean> {
    const rows: unknown[] = await this.dataSource.query(
      `SELECT 1
         FROM recipe_contents content
         JOIN recipe_sections section ON section.id = content.section_id
         JOIN recipes recipe ON recipe.id = section.recipe_id
        WHERE (content.media_url = $1 OR content.media_url LIKE $2)
          AND section.is_preview = false
          AND recipe.type = 'official'
        LIMIT 1`,
      // เผื่อข้อมูลเก่าที่เก็บเป็น URL เต็ม (http://host/uploads/...)
      [path, `%${path}`],
    );
    return rows.length > 0;
  }
}
