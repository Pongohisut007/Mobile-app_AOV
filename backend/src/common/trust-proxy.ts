/**
 * แปลง TRUST_PROXY เป็นค่าที่ Express รับ ('trust proxy')
 * - ว่าง/ไม่ตั้ง = ไม่เชื่อ proxy (ใช้ IP ที่ต่อเข้ามาตรง ๆ)
 * - ตัวเลข = จำนวน proxy ข้างหน้า เช่น 1 (ingress ตัวเดียว)
 * - true/false
 * - อื่น ๆ = รายการ IP/subnet ที่เชื่อ เช่น "loopback, 10.0.0.0/8"
 */
export function parseTrustProxy(
  value: string | undefined,
): boolean | number | string | undefined {
  const trimmed = value?.trim();
  if (!trimmed) return undefined;
  if (trimmed === 'true') return true;
  if (trimmed === 'false') return false;
  if (/^\d+$/.test(trimmed)) return Number(trimmed);
  return trimmed;
}
