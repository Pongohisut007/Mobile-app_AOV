/**
 * cache ใน RAM ที่จำกัดตาม "จำนวน byte รวม" (ไม่ใช่จำนวนรายการ)
 * เกินแล้วทิ้งอันที่ไม่ได้ใช้นานสุดก่อน (LRU)
 */
export class ByteLruCache<T> {
  private readonly entries = new Map<string, { value: T; bytes: number }>();
  private totalBytes = 0;

  constructor(private readonly maxBytes: number) {}

  get(key: string): T | undefined {
    const entry = this.entries.get(key);
    if (!entry) return undefined;
    // ย้ายไปท้าย Map = ใช้ล่าสุด
    this.entries.delete(key);
    this.entries.set(key, entry);
    return entry.value;
  }

  set(key: string, value: T, bytes: number): void {
    // ใหญ่เกินทั้ง cache ไม่ต้องเก็บ (จะไล่ของอื่นออกหมดเปล่า ๆ)
    if (bytes > this.maxBytes) return;
    this.delete(key);
    this.entries.set(key, { value, bytes });
    this.totalBytes += bytes;
    while (this.totalBytes > this.maxBytes) {
      const oldest = this.entries.keys().next().value as string | undefined;
      if (oldest === undefined) break;
      this.delete(oldest);
    }
  }

  delete(key: string): void {
    const entry = this.entries.get(key);
    if (!entry) return;
    this.entries.delete(key);
    this.totalBytes -= entry.bytes;
  }
}
