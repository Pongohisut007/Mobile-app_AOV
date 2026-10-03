sealed class PurchasedRecipesEvent {
  const PurchasedRecipesEvent();
}

/// อ่าน token จากเครื่องแล้วโหลดสูตรที่ซื้อแล้วของคนนั้นใหม่ทั้งหมด
/// ไม่มี token = ยังไม่ได้ซื้ออะไร จึงใช้ตัวนี้ได้ทั้งตอนล็อกอิน สลับบัญชี และ logout
final class PurchasedRecipesRequested extends PurchasedRecipesEvent {
  const PurchasedRecipesRequested();
}

/// โหลดใหม่โดยไม่ล้างของเดิมก่อน ใช้กับ pull-to-refresh และหลังจ่ายเงินเสร็จ
/// คนเดิมยังล็อกอินอยู่ จึงโชว์รายการเก่าไปก่อนได้ระหว่างรอ
final class PurchasedRecipesRefreshed extends PurchasedRecipesEvent {
  const PurchasedRecipesRefreshed();
}
