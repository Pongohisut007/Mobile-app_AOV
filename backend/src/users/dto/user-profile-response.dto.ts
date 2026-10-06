import { UserRole, UserStatus } from '../entities/user.entity';

export interface UserProfileResponse {
  id: string;
  displayName: string;
  email: string;
  avatarUrl: string | null;
  role: UserRole;
  status: UserStatus;
  recipeCount: number;
  purchasedCount: number;
  savedCount: number;
  draftCount: number;
  /** ค่าเฉลี่ยรีวิวที่สูตรของคนนี้ได้รับ */
  rating: number;

  // ตัวเลขผลงาน (แอปเลือกแสดงตามบทบาท creator / user)
  /** จำนวนรีวิวที่สูตรของคนนี้ได้รับ */
  reviewCount: number;
  /** จำนวนครั้งที่สูตรของคนนี้ถูกซื้อ */
  salesCount: number;
  /** หัวใจจากคนอื่นบนสูตร official ของคนนี้ */
  officialSavedCount: number;
  /** หัวใจจากคนอื่นบนสูตร community ของคนนี้ */
  communitySavedCount: number;
  /** ความคิดเห็นจากคนอื่นบนสูตร community ของคนนี้ */
  commentsReceivedCount: number;
  /** รีวิวที่คนนี้เขียนให้สูตรที่ซื้อมา */
  reviewsWrittenCount: number;
  /** false = สมัครผ่าน Google และยังไม่ได้ตั้งรหัสผ่าน (แอปแสดง "ตั้งรหัสผ่าน") */
  hasPassword: boolean;
}
