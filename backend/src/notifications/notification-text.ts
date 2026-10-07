import {
  NotificationData,
  NotificationType,
} from './entities/notification.entity';

export type PushLocale = 'th' | 'en';

export interface NotificationTextInput {
  type: NotificationType;
  data: NotificationData;
  recipeTitle: string;
  /** ชื่อคนที่ทำ (คนซื้อ/รีวิว/คอมเมนต์) */
  actorName: string;
}

export function pushLocaleOf(locale: string | null | undefined): PushLocale {
  return locale?.toLowerCase().startsWith('en') ? 'en' : 'th';
}

/**
 * ข้อความของ push (ในแอปประกอบข้อความเองจาก type/data ตามภาษาที่เลือก)
 * ไม่ใส่ข้อมูลส่วนตัวเกินจำเป็น เพราะข้อความ push วิ่งผ่าน Google/Apple
 */
export function notificationText(
  input: NotificationTextInput,
  locale: PushLocale,
): { title: string; body: string } {
  const { type, data, recipeTitle, actorName } = input;
  const en = locale === 'en';

  switch (type) {
    case NotificationType.RECIPE_PURCHASED:
      return en
        ? { title: 'New sale', body: `${actorName} bought "${recipeTitle}"` }
        : {
            title: 'มีคนซื้อสูตรของคุณ',
            body: `${actorName} ซื้อ "${recipeTitle}"`,
          };
    case NotificationType.RECIPE_MODERATED:
      if (data.status === 'rejected') {
        return en
          ? {
              title: 'Recipe not approved',
              body: `"${recipeTitle}" did not pass review. Edit it and try again.`,
            }
          : {
              title: 'สูตรของคุณไม่ผ่านการตรวจ',
              body: `"${recipeTitle}" ไม่ผ่านการตรวจ แก้ไขแล้วลองใหม่ได้`,
            };
      }
      return en
        ? {
            title: 'Recipe hidden',
            body: `"${recipeTitle}" was hidden by the Recipy team`,
          }
        : {
            title: 'สูตรของคุณถูกซ่อน',
            body: `"${recipeTitle}" ถูกทีมงานซ่อนจากผู้ใช้อื่น`,
          };
    case NotificationType.RECIPE_REVIEWED:
      return en
        ? {
            title: 'New review',
            body: `${actorName} rated "${recipeTitle}" ${data.rating ?? ''}★`,
          }
        : {
            title: 'รีวิวใหม่',
            body: `${actorName} ให้ ${data.rating ?? ''} ดาว "${recipeTitle}"`,
          };
    case NotificationType.RECIPE_COMMENTED:
      return en
        ? {
            title: `New comment on "${recipeTitle}"`,
            body: `${actorName}: ${data.excerpt ?? ''}`,
          }
        : {
            title: `คอมเมนต์ใหม่ใน "${recipeTitle}"`,
            body: `${actorName}: ${data.excerpt ?? ''}`,
          };
  }
}

/** ตัดข้อความยาวให้พอดี push/รายการ (ไม่ตัดกลางตัวอักษรที่ประกอบกัน) */
export function excerpt(text: string, max = 100): string {
  const clean = text.replace(/\s+/g, ' ').trim();
  const chars = Array.from(clean);
  return chars.length <= max ? clean : `${chars.slice(0, max - 1).join('')}…`;
}
