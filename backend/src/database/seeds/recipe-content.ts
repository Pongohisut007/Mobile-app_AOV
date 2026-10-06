import type { DishKind, DishSeed } from './demo-data';

export interface IngredientLine {
  name: string;
  amount: number | null;
  unit: string | null;
  note?: string;
  optional?: boolean;
}

export interface ContentDraft {
  type: 'text' | 'tip' | 'warning' | 'video';
  title: string;
  text: string;
}

export interface SectionDraft {
  title: string;
  description: string;
  contents: ContentDraft[];
}

interface Protein {
  name: string;
  amount: number;
  unit: string;
  prep: string;
}

const PROTEINS: [RegExp, Protein][] = [
  [
    /prawn|shrimp/i,
    {
      name: 'กุ้งสด',
      amount: 300,
      unit: 'กรัม',
      prep: 'แกะเปลือก ผ่าหลังเอาเส้นดำออก',
    },
  ],
  [
    /squid/i,
    {
      name: 'ปลาหมึก',
      amount: 300,
      unit: 'กรัม',
      prep: 'ล้างสะอาด หั่นเป็นวง',
    },
  ],
  [
    /salmon/i,
    {
      name: 'ปลาแซลมอน',
      amount: 250,
      unit: 'กรัม',
      prep: 'ซับให้แห้ง หั่นชิ้นพอดีคำ',
    },
  ],
  [
    /fish|trout|sea bass/i,
    {
      name: 'ปลาเนื้อขาว',
      amount: 400,
      unit: 'กรัม',
      prep: 'ขอดเกล็ด ล้างให้สะอาด',
    },
  ],
  [
    /lamb/i,
    { name: 'ขาแกะ', amount: 600, unit: 'กรัม', prep: 'ล้างแล้วซับให้แห้ง' },
  ],
  [
    /beef|steak/i,
    {
      name: 'เนื้อวัว',
      amount: 300,
      unit: 'กรัม',
      prep: 'หั่นชิ้นบางขวางเสี้ยน',
    },
  ],
  [
    /pork|tonkatsu|wonton/i,
    { name: 'หมูสันใน', amount: 300, unit: 'กรัม', prep: 'หั่นชิ้นพอดีคำ' },
  ],
  [
    /chicken|karaage|katsu|ayam|drumstick|tso|kung pao/i,
    { name: 'สะโพกไก่', amount: 300, unit: 'กรัม', prep: 'หั่นชิ้นพอดีคำ' },
  ],
  [
    /tofu/i,
    {
      name: 'เต้าหู้แข็ง',
      amount: 1,
      unit: 'ก้อน',
      prep: 'ซับน้ำแล้วหั่นเต๋า',
    },
  ],
  [
    /egg/i,
    { name: 'ไข่ไก่', amount: 4, unit: 'ฟอง', prep: 'ตอกใส่ชาม ตีพอเข้ากัน' },
  ],
];

const VEGETABLE: Protein = {
  name: 'ผักรวม',
  amount: 300,
  unit: 'กรัม',
  prep: 'ล้างให้สะอาด หั่นพอดีคำ',
};

export function proteinOf(dish: DishSeed): Protein {
  return (
    PROTEINS.find(([pattern]) => pattern.test(dish.titleEn))?.[1] ?? VEGETABLE
  );
}

const KIND_INGREDIENTS: Record<DishKind, IngredientLine[]> = {
  stirfry: [
    { name: 'กระเทียม', amount: 5, unit: 'กลีบ', note: 'สับหยาบ' },
    { name: 'พริกขี้หนู', amount: 5, unit: 'เม็ด', note: 'บุบพอแตก' },
    { name: 'ซอสหอยนางรม', amount: 1, unit: 'ช้อนโต๊ะ' },
    { name: 'ซีอิ๊วขาว', amount: 1, unit: 'ช้อนโต๊ะ' },
    { name: 'น้ำตาลทราย', amount: 1, unit: 'ช้อนชา' },
    { name: 'น้ำมันพืช', amount: 2, unit: 'ช้อนโต๊ะ' },
  ],
  noodle: [
    {
      name: 'เส้นก๋วยเตี๋ยว',
      amount: 200,
      unit: 'กรัม',
      note: 'แช่น้ำให้นิ่ม',
    },
    { name: 'กระเทียม', amount: 4, unit: 'กลีบ', note: 'สับ' },
    { name: 'ซีอิ๊วดำ', amount: 1, unit: 'ช้อนชา' },
    { name: 'ซอสหอยนางรม', amount: 1, unit: 'ช้อนโต๊ะ' },
    { name: 'ผักคะน้า', amount: 100, unit: 'กรัม', note: 'หั่นท่อน' },
    { name: 'ไข่ไก่', amount: 1, unit: 'ฟอง' },
    { name: 'น้ำมันพืช', amount: 2, unit: 'ช้อนโต๊ะ' },
  ],
  curry: [
    { name: 'พริกแกง', amount: 2, unit: 'ช้อนโต๊ะ' },
    { name: 'กะทิ', amount: 400, unit: 'มิลลิลิตร' },
    { name: 'น้ำปลา', amount: 1.5, unit: 'ช้อนโต๊ะ' },
    { name: 'น้ำตาลปี๊บ', amount: 1, unit: 'ช้อนโต๊ะ' },
    { name: 'ใบมะกรูด', amount: 4, unit: 'ใบ', note: 'ฉีกเอาก้านออก' },
    {
      name: 'มะเขือเปราะ',
      amount: 5,
      unit: 'ลูก',
      note: 'ผ่าสี่',
      optional: true,
    },
  ],
  soup: [
    { name: 'น้ำซุป', amount: 1, unit: 'ลิตร' },
    { name: 'ข่า', amount: 5, unit: 'แว่น' },
    { name: 'ตะไคร้', amount: 2, unit: 'ต้น', note: 'หั่นท่อนแล้วทุบ' },
    { name: 'ใบมะกรูด', amount: 4, unit: 'ใบ' },
    { name: 'น้ำปลา', amount: 2, unit: 'ช้อนโต๊ะ' },
    { name: 'น้ำมะนาว', amount: 2, unit: 'ช้อนโต๊ะ' },
    { name: 'เห็ดฟาง', amount: 150, unit: 'กรัม', optional: true },
  ],
  salad: [
    { name: 'น้ำมะนาว', amount: 3, unit: 'ช้อนโต๊ะ' },
    { name: 'น้ำปลา', amount: 2, unit: 'ช้อนโต๊ะ' },
    { name: 'น้ำตาลทราย', amount: 1, unit: 'ช้อนโต๊ะ' },
    { name: 'พริกขี้หนู', amount: 8, unit: 'เม็ด', note: 'ซอย' },
    { name: 'หอมแดง', amount: 3, unit: 'หัว', note: 'ซอยบาง' },
    { name: 'ผักชี', amount: 1, unit: 'ต้น', note: 'เด็ดใบ' },
  ],
  grill: [
    { name: 'กระเทียม', amount: 6, unit: 'กลีบ', note: 'โขลก' },
    { name: 'รากผักชี', amount: 2, unit: 'ราก' },
    { name: 'พริกไทยดำ', amount: 1, unit: 'ช้อนชา' },
    { name: 'ซีอิ๊วขาว', amount: 2, unit: 'ช้อนโต๊ะ' },
    { name: 'น้ำผึ้ง', amount: 1, unit: 'ช้อนโต๊ะ' },
    { name: 'กะทิ', amount: 100, unit: 'มิลลิลิตร', optional: true },
  ],
  fried: [
    { name: 'แป้งทอดกรอบ', amount: 150, unit: 'กรัม' },
    { name: 'แป้งข้าวโพด', amount: 2, unit: 'ช้อนโต๊ะ' },
    { name: 'กระเทียม', amount: 4, unit: 'กลีบ', note: 'สับละเอียด' },
    { name: 'พริกไทยขาว', amount: 1, unit: 'ช้อนชา' },
    { name: 'น้ำเย็นจัด', amount: 150, unit: 'มิลลิลิตร' },
    { name: 'น้ำมันสำหรับทอด', amount: 1, unit: 'ลิตร' },
  ],
  rice: [
    {
      name: 'ข้าวสวย',
      amount: 2,
      unit: 'ถ้วย',
      note: 'ใช้ข้าวค้างคืนจะร่วนกว่า',
    },
    { name: 'กระเทียม', amount: 4, unit: 'กลีบ', note: 'สับ' },
    { name: 'ไข่ไก่', amount: 2, unit: 'ฟอง' },
    { name: 'ซีอิ๊วขาว', amount: 1, unit: 'ช้อนโต๊ะ' },
    { name: 'ต้นหอม', amount: 2, unit: 'ต้น', note: 'ซอย' },
    { name: 'น้ำมันพืช', amount: 2, unit: 'ช้อนโต๊ะ' },
  ],
  steam: [
    { name: 'ขิง', amount: 1, unit: 'แง่ง', note: 'ซอยเส้น' },
    { name: 'ซีอิ๊วขาว', amount: 2, unit: 'ช้อนโต๊ะ' },
    { name: 'น้ำมันงา', amount: 1, unit: 'ช้อนชา' },
    { name: 'ต้นหอม', amount: 2, unit: 'ต้น' },
    { name: 'มะนาว', amount: 2, unit: 'ลูก', optional: true },
  ],
  snack: [
    { name: 'แผ่นแป้ง', amount: 8, unit: 'แผ่น' },
    { name: 'ผักกาดหอม', amount: 1, unit: 'หัว' },
    { name: 'แครอท', amount: 1, unit: 'หัว', note: 'ขูดเส้น' },
    { name: 'สะระแหน่', amount: 1, unit: 'กำ' },
    { name: 'น้ำจิ้มบ๊วย', amount: 4, unit: 'ช้อนโต๊ะ', optional: true },
  ],
  dessert: [
    { name: 'แป้งสาลีอเนกประสงค์', amount: 200, unit: 'กรัม' },
    { name: 'น้ำตาลทราย', amount: 80, unit: 'กรัม' },
    { name: 'กะทิ', amount: 250, unit: 'มิลลิลิตร' },
    { name: 'ไข่ไก่', amount: 2, unit: 'ฟอง' },
    { name: 'เกลือ', amount: 0.5, unit: 'ช้อนชา' },
  ],
  drink: [
    { name: 'นมสด', amount: 200, unit: 'มิลลิลิตร' },
    { name: 'นมข้นหวาน', amount: 2, unit: 'ช้อนโต๊ะ' },
    { name: 'น้ำแข็ง', amount: 1, unit: 'แก้ว' },
    { name: 'น้ำเชื่อม', amount: 1, unit: 'ช้อนโต๊ะ', optional: true },
  ],
};

const DRINK_BASE: Record<string, IngredientLine> = {
  'Thai iced tea': { name: 'ผงชาไทย', amount: 3, unit: 'ช้อนโต๊ะ' },
  'Thai iced coffee': { name: 'กาแฟดำเข้มข้น', amount: 60, unit: 'มิลลิลิตร' },
  'Banana milkshake': { name: 'กล้วยหอม', amount: 2, unit: 'ลูก' },
  'Mango lassi': { name: 'มะม่วงสุก', amount: 1, unit: 'ลูก' },
};

export function ingredientsFor(dish: DishSeed): IngredientLine[] {
  if (dish.kind === 'drink') {
    return [
      DRINK_BASE[dish.titleEn] ?? DRINK_BASE['Thai iced tea'],
      ...KIND_INGREDIENTS.drink,
    ];
  }
  const protein = proteinOf(dish);
  return [
    {
      name: protein.name,
      amount: protein.amount,
      unit: protein.unit,
      note: protein.prep,
    },
    ...KIND_INGREDIENTS[dish.kind],
  ];
}

const TIMES: Record<DishKind, [number, number, 'easy' | 'medium' | 'hard']> = {
  stirfry: [10, 10, 'easy'],
  noodle: [15, 10, 'easy'],
  curry: [20, 35, 'medium'],
  soup: [15, 25, 'medium'],
  salad: [15, 5, 'easy'],
  grill: [30, 20, 'medium'],
  fried: [20, 20, 'medium'],
  rice: [10, 10, 'easy'],
  steam: [15, 20, 'medium'],
  snack: [25, 10, 'medium'],
  dessert: [30, 40, 'hard'],
  drink: [5, 5, 'easy'],
};

export function timesFor(dish: DishSeed) {
  const [preparationMinutes, cookingMinutes, difficulty] = TIMES[dish.kind];
  return { preparationMinutes, cookingMinutes, difficulty };
}

export function descriptionFor(dish: DishSeed): string {
  const byKind: Record<DishKind, string> = {
    stirfry: 'ผัดไฟแรงหอมกระทะ รสกลมกล่อม ทำเสร็จในไม่กี่นาที',
    noodle: 'เส้นนุ่มเหนียว คลุกซอสเข้มข้น หอมกลิ่นกระทะ',
    curry: 'แกงเข้มข้น หอมเครื่องแกง กินคู่ข้าวสวยร้อน ๆ',
    soup: 'น้ำซุปหอมสมุนไพร ซดร้อน ๆ ชื่นใจ',
    salad: 'รสแซ่บ เปรี้ยว เผ็ด หวาน สดชื่นทุกคำ',
    grill: 'หมักนุ่ม ย่างหอม ๆ กินกับน้ำจิ้มรสเด็ด',
    fried: 'ทอดกรอบนอกนุ่มใน เคล็ดลับแป้งไม่อมน้ำมัน',
    rice: 'เมนูจานเดียวทำง่าย อิ่มอร่อยครบในจานเดียว',
    steam: 'นึ่งให้นุ่มชุ่มฉ่ำ รสชาติเบา ๆ ดีต่อสุขภาพ',
    snack: 'ทานเล่นได้ทั้งวัน จัดใส่กล่องไปกินนอกบ้านก็สะดวก',
    dessert: 'ขนมหวานหอมกะทิ หวานกำลังดี',
    drink: 'เครื่องดื่มเย็นชื่นใจ หอมมัน หวานกำลังดี',
  };
  return `${dish.title} ${byKind[dish.kind]}`;
}

const COOKING: Record<DishKind, ContentDraft[]> = {
  stirfry: [
    {
      type: 'text',
      title: 'เจียวกระเทียม',
      text: 'ตั้งกระทะให้ร้อนจัด ใส่น้ำมัน ผัดกระเทียมและพริกจนหอม',
    },
    {
      type: 'text',
      title: 'ผัดโปรตีน',
      text: 'ใส่{protein}ลงไปผัดด้วยไฟแรงจนสุกเกือบทั่ว',
    },
    {
      type: 'text',
      title: 'ปรุงรส',
      text: 'ใส่ซอสหอยนางรม ซีอิ๊วขาว และน้ำตาล ผัดให้ซอสเคลือบทั่ว',
    },
  ],
  noodle: [
    {
      type: 'text',
      title: 'ผัดเครื่อง',
      text: 'เจียวกระเทียมให้หอม ใส่{protein}ผัดจนสุก',
    },
    {
      type: 'text',
      title: 'ใส่เส้น',
      text: 'ใส่เส้นและซีอิ๊วดำ ผัดเร็ว ๆ ด้วยไฟแรงให้เส้นหอมกระทะ',
    },
    {
      type: 'text',
      title: 'ใส่ไข่และผัก',
      text: 'ดันเส้นไปข้างกระทะ ตอกไข่ ยีให้สุกแล้วคลุกรวมกับผัก',
    },
  ],
  curry: [
    {
      type: 'text',
      title: 'ผัดพริกแกง',
      text: 'ตั้งหัวกะทิให้แตกมัน ใส่พริกแกงผัดจนหอม',
    },
    {
      type: 'text',
      title: 'ใส่โปรตีน',
      text: 'ใส่{protein}ผัดกับเครื่องแกงให้เข้ากัน แล้วเติมหางกะทิ',
    },
    {
      type: 'text',
      title: 'เคี่ยวและปรุงรส',
      text: 'เคี่ยวไฟกลางจนเนื้อนุ่ม ปรุงด้วยน้ำปลาและน้ำตาลปี๊บ ใส่ใบมะกรูด',
    },
  ],
  soup: [
    {
      type: 'text',
      title: 'ต้มน้ำซุปสมุนไพร',
      text: 'ต้มน้ำซุปให้เดือด ใส่ข่า ตะไคร้ ใบมะกรูด ต้มต่อ 5 นาที',
    },
    {
      type: 'text',
      title: 'ใส่โปรตีน',
      text: 'ใส่{protein}และเห็ด ต้มจนสุก อย่าให้เดือดนานเกินไป',
    },
    {
      type: 'text',
      title: 'ปรุงรส',
      text: 'ปิดไฟ แล้วปรุงด้วยน้ำปลาและน้ำมะนาว ชิมให้กลมกล่อม',
    },
  ],
  salad: [
    {
      type: 'text',
      title: 'ลวกวัตถุดิบ',
      text: 'ลวก{protein}ในน้ำเดือดพอสุก แช่น้ำเย็นแล้วสะเด็ดน้ำ',
    },
    {
      type: 'text',
      title: 'ผสมน้ำยำ',
      text: 'ผสมน้ำมะนาว น้ำปลา น้ำตาล และพริก คนจนน้ำตาลละลาย',
    },
    {
      type: 'text',
      title: 'คลุกเคล้า',
      text: 'ใส่วัตถุดิบทั้งหมดลงในชาม ราดน้ำยำ คลุกเบา ๆ แล้วโรยผักชี',
    },
  ],
  grill: [
    {
      type: 'text',
      title: 'หมัก',
      text: 'โขลกกระเทียม รากผักชี พริกไทย คลุกกับ{protein}และซอส หมักทิ้งไว้อย่างน้อย 30 นาที',
    },
    {
      type: 'text',
      title: 'ย่าง',
      text: 'ย่างไฟกลางพลิกบ่อย ๆ ทาซอสหมักระหว่างย่างจนสุกหอม',
    },
    {
      type: 'text',
      title: 'พักเนื้อ',
      text: 'พักไว้ 3-5 นาทีก่อนหั่น เนื้อจะฉ่ำไม่แห้ง',
    },
  ],
  fried: [
    {
      type: 'text',
      title: 'หมัก',
      text: 'คลุก{protein}กับกระเทียมและพริกไทย หมักไว้ 15 นาที',
    },
    {
      type: 'text',
      title: 'ชุบแป้ง',
      text: 'ผสมแป้งทอดกรอบกับน้ำเย็นจัด ชุบ{protein}ให้ทั่ว',
    },
    {
      type: 'text',
      title: 'ทอดสองรอบ',
      text: 'ทอดไฟกลางจนสุก ตักขึ้นพัก แล้วทอดซ้ำไฟแรงอีก 1 นาทีให้กรอบ',
    },
  ],
  rice: [
    {
      type: 'text',
      title: 'ผัดเครื่อง',
      text: 'เจียวกระเทียม ใส่{protein}ผัดจนสุก',
    },
    { type: 'text', title: 'ใส่ไข่', text: 'ตอกไข่ลงไป ยีให้สุกพอดี' },
    {
      type: 'text',
      title: 'ใส่ข้าว',
      text: 'ใส่ข้าว ผัดเร็ว ๆ ให้ร่วน ปรุงด้วยซีอิ๊วขาว โรยต้นหอม',
    },
  ],
  steam: [
    {
      type: 'text',
      title: 'จัดลงจาน',
      text: 'วาง{protein}ลงจานทนความร้อน โรยขิงซอย',
    },
    { type: 'text', title: 'นึ่ง', text: 'นึ่งไฟแรงประมาณ 12-15 นาทีจนสุก' },
    {
      type: 'text',
      title: 'ราดซอส',
      text: 'ราดซีอิ๊วผสมน้ำมันงาร้อน ๆ โรยต้นหอม',
    },
  ],
  snack: [
    {
      type: 'text',
      title: 'เตรียมไส้',
      text: 'ปรุง{protein}ให้สุก หั่นผักเป็นเส้นเตรียมไว้',
    },
    {
      type: 'text',
      title: 'ห่อ',
      text: 'จุ่มแผ่นแป้งในน้ำอุ่นพอนิ่ม วางไส้แล้วม้วนให้แน่น',
    },
    {
      type: 'text',
      title: 'จัดเสิร์ฟ',
      text: 'หั่นครึ่ง จัดใส่จานพร้อมน้ำจิ้ม',
    },
  ],
  dessert: [
    {
      type: 'text',
      title: 'ผสมแป้ง',
      text: 'ร่อนแป้ง ผสมน้ำตาล ไข่ และกะทิ คนจนเนียน',
    },
    { type: 'text', title: 'พักแป้ง', text: 'พักแป้งไว้ 20 นาทีให้ตัว' },
    {
      type: 'text',
      title: 'นึ่ง/อบ',
      text: 'เทใส่พิมพ์ นึ่งหรืออบทีละชั้นจนสุก ทิ้งให้เย็นก่อนตัด',
    },
  ],
  drink: [
    {
      type: 'text',
      title: 'เตรียมฐาน',
      text: 'ชงหรือปั่นวัตถุดิบหลักให้เข้มข้น',
    },
    {
      type: 'text',
      title: 'ผสมนม',
      text: 'เติมนมสดและนมข้นหวาน คนให้เข้ากัน ชิมความหวาน',
    },
    { type: 'text', title: 'เสิร์ฟ', text: 'เทลงแก้วที่ใส่น้ำแข็งเต็มแก้ว' },
  ],
};

const TIPS: Record<DishKind, string> = {
  stirfry: 'ใช้ไฟแรงตลอดและอย่าใส่ของในกระทะเยอะเกินไป ผักจะกรอบไม่คายน้ำ',
  noodle: 'อย่าแช่เส้นนานเกิน เส้นจะเละเวลาผัด',
  curry: 'ผัดพริกแกงกับหัวกะทิให้แตกมันจริง ๆ แกงจะหอมและสีสวย',
  soup: 'ใส่น้ำมะนาวหลังปิดไฟ จะได้ไม่ขม',
  salad: 'คลุกน้ำยำก่อนเสิร์ฟทันที ผักจะไม่สลด',
  grill: 'ทาน้ำมันที่ตะแกรงก่อนย่าง เนื้อจะไม่ติด',
  fried: 'น้ำมันต้องร้อนประมาณ 170°C ลองหยดแป้งแล้วฟูขึ้นทันทีคือใช้ได้',
  rice: 'ใช้ข้าวค้างคืน ข้าวจะร่วนไม่แฉะ',
  steam: 'รอน้ำเดือดจัดก่อนค่อยวางจานลงนึ่ง',
  snack: 'คลุมด้วยผ้าชุบน้ำหมาด ๆ แป้งจะไม่แห้งแข็ง',
  dessert: 'ร่อนแป้งก่อนผสม เนื้อขนมจะเนียนไม่เป็นเม็ด',
  drink: 'แช่แก้วในตู้เย็นก่อน เครื่องดื่มจะเย็นนานขึ้น',
};

/**
 * section ของสูตร: [0] = ตัวอย่าง (เตรียมวัตถุดิบ) ที่เหลือ = ต้องซื้อ (official)
 * [videoUrl] ใส่วิดีโอประกอบในขั้นตอนปรุง (เฉพาะบางสูตร official)
 */
export function sectionsFor(
  dish: DishSeed,
  official: boolean,
  videoUrl: string | null,
): SectionDraft[] {
  const protein = dish.kind === 'drink' ? 'วัตถุดิบ' : proteinOf(dish).name;
  const fill = (text: string) => text.replaceAll('{protein}', protein);
  const ingredientList = ingredientsFor(dish)
    .map((line) => line.name)
    .join(', ');

  const sections: SectionDraft[] = [
    {
      title: 'เตรียมวัตถุดิบ',
      description: 'เตรียมของให้พร้อมก่อนเริ่มทำ',
      contents: [
        { type: 'text', title: 'วัตถุดิบที่ใช้', text: ingredientList },
        {
          type: 'text',
          title: 'เตรียมของ',
          text:
            dish.kind === 'drink'
              ? 'เตรียมแก้วและน้ำแข็งให้พร้อม'
              : `${proteinOf(dish).prep} แล้วเตรียมเครื่องปรุงทั้งหมดไว้ใกล้มือ`,
        },
      ],
    },
    {
      title: 'ขั้นตอนการทำ',
      description: `วิธีทำ${dish.title}แบบละเอียด`,
      contents: [
        ...COOKING[dish.kind].map((step) => ({
          ...step,
          text: fill(step.text),
        })),
        ...(videoUrl
          ? [
              {
                type: 'video' as const,
                title: 'ดูวิดีโอขั้นตอนนี้',
                text: videoUrl,
              },
            ]
          : []),
      ],
    },
  ];

  if (official) {
    sections.push({
      title: 'เคล็ดลับจากเชฟ',
      description: 'เทคนิคที่ทำให้อร่อยแบบร้าน',
      contents: [
        { type: 'tip', title: 'เคล็ดลับ', text: TIPS[dish.kind] },
        {
          type: 'warning',
          title: 'ข้อควรระวัง',
          text:
            dish.kind === 'fried'
              ? 'ระวังน้ำมันกระเด็น ซับวัตถุดิบให้แห้งก่อนลงทอดเสมอ'
              : 'ชิมก่อนปรุงเพิ่มทุกครั้ง ความเค็มของซอสแต่ละยี่ห้อไม่เท่ากัน',
        },
      ],
    });
  } else {
    sections[1].contents.push({
      type: 'tip',
      title: 'เคล็ดลับ',
      text: TIPS[dish.kind],
    });
  }
  return sections;
}
