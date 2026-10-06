/**
 * ข้อมูลตั้งต้นสำหรับ seed (ผู้ใช้ หมวด สูตร ข้อความรีวิว/คอมเมนต์)
 * รูปอาหารมาจาก TheMealDB / TheCocktailDB (ลิงก์สาธารณะ ใช้ได้ถาวร)
 */

const MEAL_IMAGE = 'https://www.themealdb.com/images/media/meals/';
const DRINK_IMAGE = 'https://www.thecocktaildb.com/images/media/drink/';

export type DishKind =
  | 'stirfry'
  | 'noodle'
  | 'curry'
  | 'soup'
  | 'salad'
  | 'grill'
  | 'fried'
  | 'rice'
  | 'steam'
  | 'snack'
  | 'dessert'
  | 'drink';

export interface CategorySeed {
  name: string;
  nameEn: string;
  slug: string;
  description: string;
  imageUrl: string;
}

export const CATEGORIES: CategorySeed[] = [
  {
    name: 'อาหารไทย',
    nameEn: 'Thai food',
    slug: 'thai-food',
    description: 'สูตรอาหารไทยรสจัดจ้าน',
    imageUrl: `${MEAL_IMAGE}sstssx1487349585.jpg`,
  },
  {
    name: 'เมนูจานเดียว',
    nameEn: 'One-dish meals',
    slug: 'single-dish',
    description: 'เมนูทำง่าย อิ่มได้ในจานเดียว',
    imageUrl: `${MEAL_IMAGE}wai9bw1619788844.jpg`,
  },
  {
    name: 'อาหารตามสั่ง',
    nameEn: 'Made to order',
    slug: 'made-to-order',
    description: 'เมนูผัดร้อน ๆ แบบร้านตามสั่ง',
    imageUrl: `${MEAL_IMAGE}el64dy1763483009.jpg`,
  },
  {
    name: 'ก๋วยเตี๋ยว',
    nameEn: 'Noodles',
    slug: 'noodles',
    description: 'ก๋วยเตี๋ยวน้ำ แห้ง และเส้นผัด',
    imageUrl: `${MEAL_IMAGE}rg9ze01763479093.jpg`,
  },
  {
    name: 'ยำ',
    nameEn: 'Spicy salads',
    slug: 'spicy-thai-salad',
    description: 'ยำรสแซ่บ เปรี้ยว เผ็ด หวาน',
    imageUrl: `${MEAL_IMAGE}6g3rso1763486069.jpg`,
  },
  {
    name: 'ไก่ทอด',
    nameEn: 'Fried chicken',
    slug: 'fire-chiken',
    description: 'ไก่ทอดกรอบนอกนุ่มใน',
    imageUrl: `${MEAL_IMAGE}tyywsw1505930373.jpg`,
  },
  {
    name: 'ปิ้งย่าง',
    nameEn: 'Grilled',
    slug: 'grill',
    description: 'เมนูปิ้งย่างหอมกลิ่นถ่าน',
    imageUrl: `${MEAL_IMAGE}qqwypw1504642429.jpg`,
  },
  {
    name: 'อาหารสุขภาพ',
    nameEn: 'Healthy food',
    slug: 'good-food',
    description: 'เมนูคลีน ไขมันต่ำ ผักเยอะ',
    imageUrl: `${MEAL_IMAGE}minfsc1763766806.jpg`,
  },
  {
    name: 'น้ำจิ้ม',
    nameEn: 'Dipping sauces',
    slug: 'dipping-sauce',
    description: 'น้ำจิ้มและซอสคู่เมนูโปรด',
    imageUrl: `${MEAL_IMAGE}6s3i3p1763488540.jpg`,
  },
  {
    name: 'ชานม',
    nameEn: 'Milk tea',
    slug: 'bubble-tea',
    description: 'ชา กาแฟ และเครื่องดื่มเย็น ๆ',
    imageUrl: `${DRINK_IMAGE}trvwpu1441245568.jpg`,
  },
];

export interface DishSeed {
  title: string;
  titleEn: string;
  imageUrl: string;
  categories: string[];
  kind: DishKind;
}

const meal = (
  title: string,
  titleEn: string,
  file: string,
  categories: string[],
  kind: DishKind,
): DishSeed => ({
  title,
  titleEn,
  imageUrl: `${MEAL_IMAGE}${file}`,
  categories,
  kind,
});

const drink = (title: string, titleEn: string, file: string): DishSeed => ({
  title,
  titleEn,
  imageUrl: `${DRINK_IMAGE}${file}`,
  categories: ['bubble-tea'],
  kind: 'drink',
});

/** 100 สูตร */
export const DISHES: DishSeed[] = [
  // ไทย
  meal(
    'ผัดขี้เมาเส้นใหญ่',
    'Drunken noodles (Pad kee mao)',
    '2wx8cm1763373419.jpg',
    ['noodles', 'made-to-order'],
    'noodle',
  ),
  meal(
    'ก๋วยเตี๋ยวเนื้อตุ๋นตะไคร้',
    'Lemongrass beef noodle stew',
    'ntafxw1763586291.jpg',
    ['noodles'],
    'soup',
  ),
  meal(
    'แกงมัสมั่นเนื้อ',
    'Massaman beef curry',
    'tvttqv1504640475.jpg',
    ['thai-food'],
    'curry',
  ),
  meal(
    'ผัดซีอิ๊วหมู',
    'Pad see ew with pork',
    'uuuspp1468263334.jpg',
    ['noodles', 'made-to-order'],
    'noodle',
  ),
  meal(
    'ผัดไทยกุ้งสด',
    'Pad Thai with prawns',
    'rg9ze01763479093.jpg',
    ['noodles', 'thai-food'],
    'noodle',
  ),
  meal(
    'พะแนงไก่',
    'Panang chicken curry',
    '0dhtwr1763371444.jpg',
    ['thai-food'],
    'curry',
  ),
  meal(
    'กุ้งผัดผักรวม',
    'Prawn stir-fry with vegetables',
    '96lt871763480970.jpg',
    ['made-to-order'],
    'stirfry',
  ),
  meal(
    'ไก่เสียบไม้ซอสพริกแกงเผ็ด',
    'Red curry chicken kebabs',
    'prjve31763486864.jpg',
    ['grill'],
    'grill',
  ),
  meal(
    'บะหมี่กุ้งผัดพริกเผา',
    'Spicy Thai prawn noodles',
    '568t931763584227.jpg',
    ['noodles'],
    'noodle',
  ),
  meal(
    'ผัดกะเพราไก่',
    'Stir-fried chicken with holy basil',
    'el64dy1763483009.jpg',
    ['made-to-order', 'single-dish'],
    'stirfry',
  ),
  meal(
    'เนื้อผัดน้ำมันหอย',
    'Beef stir-fry with oyster sauce',
    'kyuxew1763479470.jpg',
    ['made-to-order'],
    'stirfry',
  ),
  meal(
    'ทอดมันไก่ น้ำจิ้มไก่',
    'Thai chicken cakes with sweet chilli sauce',
    '6s3i3p1763488540.jpg',
    ['fire-chiken', 'dipping-sauce'],
    'fried',
  ),
  meal(
    'แกงจืดผักกะทิ',
    'Coconut vegetable broth',
    '4k8nzy1763583384.jpg',
    ['good-food'],
    'soup',
  ),
  meal(
    'ข้าวซอยไก่',
    'Khao soi chicken curry noodles',
    '118oj61763423896.jpg',
    ['noodles', 'thai-food'],
    'soup',
  ),
  meal(
    'น่องไก่ทอดสมุนไพร',
    'Herb fried chicken drumsticks',
    'ittake1763586925.jpg',
    ['fire-chiken'],
    'fried',
  ),
  meal(
    'ข้าวผัดกุ้ง',
    'Prawn fried rice',
    'hblwvg1763478203.jpg',
    ['single-dish', 'made-to-order'],
    'rice',
  ),
  meal(
    'แกงเขียวหวานไก่น้ำใส',
    'Green chicken soup',
    '7kb44y1763589084.jpg',
    ['thai-food'],
    'soup',
  ),
  meal(
    'แกงเขียวหวานไก่',
    'Green curry with chicken',
    'sstssx1487349585.jpg',
    ['thai-food'],
    'curry',
  ),
  meal(
    'แกงหมูถั่วลิสง',
    'Pork and peanut curry',
    'snmtd61763426568.jpg',
    ['thai-food'],
    'curry',
  ),
  meal(
    'แกงกุ้งกะทิ',
    'Prawn coconut curry',
    'qqlwv91763501559.jpg',
    ['thai-food'],
    'curry',
  ),
  meal(
    'ซุปฟักทองสไตล์ไทย',
    'Thai pumpkin soup',
    '1brbso1763585098.jpg',
    ['good-food'],
    'soup',
  ),
  meal(
    'ยำเส้นหมี่ข้าว',
    'Rice noodle salad',
    '6g3rso1763486069.jpg',
    ['spicy-thai-salad'],
    'salad',
  ),
  meal(
    'ต้มปลาผักรวม',
    'Fish broth with greens',
    'a2ec961763587756.jpg',
    ['good-food'],
    'soup',
  ),
  meal(
    'ปลานึ่งมะนาว',
    'Steamed fish with lime',
    'yx8j1i1763484612.jpg',
    ['thai-food', 'good-food'],
    'steam',
  ),
  meal(
    'ต้มข่าไก่',
    'Tom kha gai',
    'ol2xxt1763582263.jpg',
    ['thai-food'],
    'soup',
  ),
  meal(
    'ต้มยำกุ้งน้ำข้น',
    'Creamy tom yum with prawns',
    '9c5nlx1763424766.jpg',
    ['thai-food'],
    'soup',
  ),
  meal(
    'ต้มยำกุ้งน้ำใส',
    'Clear tom yum with prawns',
    'l50vz41763422681.jpg',
    ['thai-food', 'good-food'],
    'soup',
  ),
  // เวียดนาม
  meal(
    'ยำกุ้งซอสงาเผ็ด',
    'Bang bang prawn salad',
    '4xcfai1763765676.jpg',
    ['spicy-thai-salad'],
    'salad',
  ),
  meal(
    'ซาลาเปาหมูแดง',
    'Barbecue pork buns',
    'tzsy461763769901.jpg',
    ['single-dish'],
    'steam',
  ),
  meal(
    'ข้าวหน้าเนื้อสไตล์บั๋นหมี่',
    'Beef banh mi bowl',
    'z0ageb1583189517.jpg',
    ['single-dish'],
    'rice',
  ),
  meal('เฝอเนื้อ', 'Beef pho', 'pbzcrx1763765096.jpg', ['noodles'], 'soup'),
  meal(
    'สลัดเส้นหมี่ผักสด',
    'Noodle bowl salad',
    'zry07j1763779321.jpg',
    ['spicy-thai-salad', 'good-food'],
    'salad',
  ),
  meal(
    'ยำกุ้งเส้นหมี่หอมเจียว',
    'Prawn noodle salad with crispy shallots',
    '0iryz91763778419.jpg',
    ['spicy-thai-salad'],
    'salad',
  ),
  meal(
    'บรอกโคลีชุบแป้งทอด น้ำจิ้มญวน',
    'Broccoli tempura with nuoc cham',
    'xnv4wf1763756529.jpg',
    ['dipping-sauce'],
    'fried',
  ),
  meal(
    'เกี๊ยวแผ่นแป้งข้าว',
    'Rice paper dumplings',
    'sfahy01763752319.jpg',
    ['single-dish'],
    'steam',
  ),
  meal(
    'ก๋วยเตี๋ยวน้ำแซลมอน',
    'Salmon noodle soup',
    'ikizdm1763760862.jpg',
    ['noodles', 'good-food'],
    'soup',
  ),
  meal(
    'แซลมอนห่อเส้นหมี่',
    'Salmon noodle wraps',
    'prrirc1763781360.jpg',
    ['good-food'],
    'snack',
  ),
  meal(
    'หมึกทอดเกลือพริกไทย',
    'Salt and pepper squid',
    'yxiilf1763759428.jpg',
    ['made-to-order'],
    'fried',
  ),
  meal(
    'ปลากะพงราดขิงพริก',
    'Sea bass with sizzled ginger and chilli',
    'tqd7s21763780609.jpg',
    ['thai-food'],
    'steam',
  ),
  meal(
    'ยำเนื้อย่างเส้นหมี่',
    'Grilled steak noodle salad',
    'st9shl1763755808.jpg',
    ['spicy-thai-salad', 'grill'],
    'salad',
  ),
  meal(
    'ยำกะหล่ำแครอทรสจี๊ด',
    'Tangy carrot and cabbage salad',
    'dbazbg1763779999.jpg',
    ['good-food', 'spicy-thai-salad'],
    'salad',
  ),
  meal(
    'เต้าหู้ผัดผักเม็ดมะม่วง',
    'Tofu, greens and cashew stir-fry',
    'minfsc1763766806.jpg',
    ['good-food', 'made-to-order'],
    'stirfry',
  ),
  meal(
    'แซนด์วิชบั๋นหมี่ไก่',
    'Chicken banh mi',
    '1wj8w31763781990.jpg',
    ['single-dish'],
    'snack',
  ),
  meal(
    'บั๋นหมี่ผักวีแกน',
    'Vegan banh mi',
    'sonirb1763782831.jpg',
    ['good-food'],
    'snack',
  ),
  meal(
    'ปลาเทราต์ผัดคาราเมล',
    'Caramel trout',
    'p02vq41763754350.jpg',
    ['thai-food'],
    'stirfry',
  ),
  meal(
    'ยำไก่ฉีกสไตล์เวียดนาม',
    'Vietnamese chicken salad',
    'pk8wtn1763758591.jpg',
    ['spicy-thai-salad'],
    'salad',
  ),
  meal(
    'หมูย่างเส้นหมี่',
    'Grilled pork with vermicelli (Bun thit nuong)',
    'qqwypw1504642429.jpg',
    ['grill', 'noodles'],
    'grill',
  ),
  meal(
    'ยำหมูสไตล์เวียดนาม',
    'Vietnamese pork salad',
    'g7jomp1763763994.jpg',
    ['spicy-thai-salad'],
    'salad',
  ),
  meal(
    'ปอเปี๊ยะสดกุ้ง',
    'Fresh prawn rolls',
    '9r2xrg1763771238.jpg',
    ['good-food', 'dipping-sauce'],
    'snack',
  ),
  meal(
    'ผักห่อแผ่นแป้งข้าว',
    'Vegetable rice paper parcels',
    'f698g91763768731.jpg',
    ['good-food'],
    'snack',
  ),
  meal(
    'หมูคาราเมล',
    'Caramel pork',
    '4mzt101763761546.jpg',
    ['single-dish'],
    'stirfry',
  ),
  meal(
    'สุกี้ผักรวม',
    'Vegetable hotpot',
    '4uje7l1763762276.jpg',
    ['good-food'],
    'soup',
  ),
  meal(
    'ขาแกะตุ๋นมันหวาน',
    'Braised lamb shanks with sweet potato',
    '7xte3u1763757761.jpg',
    ['thai-food'],
    'curry',
  ),
  // จีน
  meal(
    'ปอเปี๊ยะทอดหม้อทอดไร้น้ำมัน',
    'Air fryer egg rolls',
    'grhn401765687086.jpg',
    ['single-dish'],
    'fried',
  ),
  meal(
    'เนื้อผัดบรอกโคลี',
    'Beef and broccoli stir-fry',
    'm0p0j81765568742.jpg',
    ['made-to-order'],
    'stirfry',
  ),
  meal(
    'บะหมี่ผัดเนื้อ',
    'Beef lo mein',
    '1529444830.jpg',
    ['noodles'],
    'noodle',
  ),
  meal(
    'โจ๊กไก่',
    'Chicken congee',
    '1529446352.jpg',
    ['good-food', 'single-dish'],
    'soup',
  ),
  meal(
    'ข้าวผัดไก่',
    'Chicken fried rice',
    'wuyd2h1765655837.jpg',
    ['single-dish', 'made-to-order'],
    'rice',
  ),
  meal(
    'ไก่ทอดซอสส้ม',
    'Orange chicken',
    's73ytv1765567838.jpg',
    ['fire-chiken'],
    'fried',
  ),
  meal(
    'ไข่ผัดมะเขือเทศ',
    'Tomato and egg stir-fry',
    'rwvw8q1765660071.jpg',
    ['made-to-order', 'single-dish'],
    'stirfry',
  ),
  meal('ซุปไข่น้ำ', 'Egg drop soup', '1529446137.jpg', ['good-food'], 'soup'),
  meal(
    'ไข่ฟูยองราดซอส',
    'Egg foo young',
    '47y6ii1765658818.jpg',
    ['made-to-order'],
    'fried',
  ),
  meal(
    'ไก่ทอดเจเนอรัลโซ',
    "General Tso's chicken",
    '1529444113.jpg',
    ['fire-chiken'],
    'fried',
  ),
  meal(
    'ซุปเปรี้ยวเผ็ดสไตล์จีน',
    'Hot and sour soup',
    '1529445893.jpg',
    ['thai-food'],
    'soup',
  ),
  meal(
    'ไก่ผัดเม็ดมะม่วงกังเปา',
    'Kung pao chicken',
    '1525872624.jpg',
    ['made-to-order'],
    'stirfry',
  ),
  meal(
    'กุ้งผัดกังเปา',
    'Kung pao prawns',
    '1525873040.jpg',
    ['made-to-order'],
    'stirfry',
  ),
  meal(
    'เต้าหู้หม่าโผว',
    'Mapo tofu',
    '1525874812.jpg',
    ['single-dish'],
    'stirfry',
  ),
  meal(
    'ผักกาดขาวผัดกุ้งแห้ง',
    'Napa cabbage with dried shrimp',
    '9nh4dl1766435484.jpg',
    ['good-food'],
    'stirfry',
  ),
  meal(
    'ราเมนไข่ต้ม',
    'Ramen with boiled egg',
    'ip5xtp1769779958.jpg',
    ['noodles'],
    'soup',
  ),
  meal(
    'แตงกวาราดงาดำ',
    'Sesame cucumber salad',
    '93iok31766436070.jpg',
    ['spicy-thai-salad', 'good-food'],
    'salad',
  ),
  meal(
    'ก๋วยเตี๋ยวผัดกุ้ง',
    'Shrimp chow fun',
    '1529445434.jpg',
    ['noodles', 'made-to-order'],
    'noodle',
  ),
  meal(
    'กุ้งผัดถั่วลันเตา',
    'Shrimp with snow peas',
    'fpl3mv1766433431.jpg',
    ['made-to-order', 'good-food'],
    'stirfry',
  ),
  meal(
    'มะเขือยาวผัดเสฉวน',
    'Sichuan eggplant',
    '1oz4nb1765687990.jpg',
    ['made-to-order'],
    'stirfry',
  ),
  meal(
    'ถั่วฝักยาวผัดเสฉวน',
    'Sichuan long beans',
    'i0610h1765659464.jpg',
    ['made-to-order'],
    'stirfry',
  ),
  meal(
    'เต้าหู้ไข่ราดซอสงา',
    'Silken tofu with sesame soy sauce',
    'j9nray1765657692.jpg',
    ['good-food'],
    'steam',
  ),
  meal(
    'เส้นหมี่ผัดสิงคโปร์',
    'Singapore noodles with shrimp',
    'f3cxnc1765656994.jpg',
    ['noodles'],
    'noodle',
  ),
  meal(
    'ไก่ผัดเปรี้ยวหวาน',
    'Sweet and sour chicken',
    'arzs741766434335.jpg',
    ['made-to-order'],
    'stirfry',
  ),
  meal(
    'หมูผัดเปรี้ยวหวาน',
    'Sweet and sour pork',
    '1529442316.jpg',
    ['made-to-order', 'single-dish'],
    'stirfry',
  ),
  meal(
    'เนื้อผัดเสฉวน',
    'Szechuan beef',
    '1529443236.jpg',
    ['made-to-order'],
    'stirfry',
  ),
  meal('เกี๊ยวน้ำ', 'Wonton soup', '1525876468.jpg', ['noodles'], 'soup'),
  // มาเลเซีย
  meal(
    'ขนมแป้งจี่ถั่วบด',
    'Apam balik',
    'adxcbq1619787919.jpg',
    ['single-dish'],
    'dessert',
  ),
  meal(
    'ไก่ย่างกะทิ',
    'Ayam percik',
    '020z181619788503.jpg',
    ['grill'],
    'grill',
  ),
  meal(
    'เนื้อตุ๋นเรนดัง',
    'Beef rendang',
    'bc8v651619789840.jpg',
    ['thai-food'],
    'curry',
  ),
  meal(
    'ลักซากุ้ง',
    'Laksa king prawn noodles',
    'rvypwy1503069308.jpg',
    ['noodles'],
    'soup',
  ),
  meal(
    'หมี่ผัดมามัก',
    'Mee goreng mamak',
    'xquakq1619787532.jpg',
    ['noodles', 'made-to-order'],
    'noodle',
  ),
  meal(
    'ข้าวมันกะทิ',
    'Nasi lemak',
    'wai9bw1619788844.jpg',
    ['single-dish'],
    'rice',
  ),
  meal(
    'โรตีจอห์น',
    'Roti john',
    'hx335q1619789561.jpg',
    ['single-dish'],
    'snack',
  ),
  meal(
    'ขนมชั้นใบเตย',
    'Pandan layer cake (Seri muka)',
    '6ut2og1619790195.jpg',
    ['thai-food'],
    'dessert',
  ),
  // ญี่ปุ่น
  meal(
    'ไก่ทอดคาราอาเกะ',
    'Chicken karaage',
    'tyywsw1505930373.jpg',
    ['fire-chiken'],
    'fried',
  ),
  meal(
    'แซลมอนย่างเทอริยากิ',
    'Honey teriyaki salmon',
    'xxyupu1468262513.jpg',
    ['grill', 'good-food'],
    'grill',
  ),
  meal(
    'ข้าวสวยญี่ปุ่น',
    'Japanese steamed rice',
    'kw92t41604181871.jpg',
    ['single-dish'],
    'rice',
  ),
  meal(
    'คัตสึด้ง',
    'Katsudon',
    'd8f6qx1604182128.jpg',
    ['single-dish', 'fire-chiken'],
    'rice',
  ),
  meal(
    'ข้าวแกงกะหรี่ไก่ทอด',
    'Katsu chicken curry',
    'vwrpps1503068729.jpg',
    ['single-dish'],
    'curry',
  ),
  meal(
    'ซูชิโฮมเมด',
    'Homemade sushi',
    'g046bb1663960946.jpg',
    ['good-food'],
    'snack',
  ),
  meal('ทงคัตสึ', 'Tonkatsu', 'lwsnkl1604181187.jpg', ['fire-chiken'], 'fried'),
  meal('อุด้งผัด', 'Yaki udon', 'wrustq1511475474.jpg', ['noodles'], 'noodle'),
  // เครื่องดื่ม
  drink('ชาไทยเย็น', 'Thai iced tea', 'trvwpu1441245568.jpg'),
  drink('กาแฟเย็นสไตล์ไทย', 'Thai iced coffee', 'rqpypv1441245650.jpg'),
  drink('นมปั่นกล้วย', 'Banana milkshake', 'rtwwsx1472720307.jpg'),
  drink('ลัสซีมะม่วง', 'Mango lassi', '1bw6sd1487603816.jpg'),
];

export interface UserSeed {
  key: string;
  email: string;
  displayName: string;
  avatarUrl: string | null;
  role: 'admin' | 'creator' | 'user';
  /** สมัครผ่าน Google (ไม่มีรหัสผ่าน) */
  googleOnly?: boolean;
}

const avatar = (n: number) => `https://i.pravatar.cc/300?img=${n}`;

/** 20 คน: admin 1, creator 5, ผู้ใช้ทั่วไป 14 */
export const USERS: UserSeed[] = [
  {
    key: 'admin',
    email: 'admin@recipy.local',
    displayName: 'ทีมงาน Recipy',
    avatarUrl: null,
    role: 'admin',
  },
  {
    key: 'mook',
    email: 'chef.mook@recipy.local',
    displayName: 'เชฟมุก',
    avatarUrl: avatar(47),
    role: 'creator',
  },
  {
    key: 'ton',
    email: 'chef.ton@recipy.local',
    displayName: 'เชฟต้น ครัวไทย',
    avatarUrl: avatar(12),
    role: 'creator',
  },
  {
    key: 'yai',
    email: 'krua.khunyai@recipy.local',
    displayName: 'ครัวคุณยาย',
    avatarUrl: avatar(49),
    role: 'creator',
  },
  {
    key: 'prae',
    email: 'chef.prae@recipy.local',
    displayName: 'เชฟแพร Healthy Kitchen',
    avatarUrl: avatar(45),
    role: 'creator',
  },
  {
    key: 'bites',
    email: 'bangkok.bites@recipy.local',
    displayName: 'Bangkok Bites',
    avatarUrl: avatar(15),
    role: 'creator',
  },
  {
    key: 'somchai',
    email: 'somchai@example.com',
    displayName: 'สมชาย ใจดี',
    avatarUrl: avatar(13),
    role: 'user',
  },
  {
    key: 'malee',
    email: 'malee@example.com',
    displayName: 'มาลี สวยงาม',
    avatarUrl: avatar(44),
    role: 'user',
  },
  {
    key: 'piya',
    email: 'piya@example.com',
    displayName: 'ปิยะ แสงทอง',
    avatarUrl: avatar(33),
    role: 'user',
  },
  {
    key: 'napat',
    email: 'napatsorn@example.com',
    displayName: 'นภัสสร ศรีสุข',
    avatarUrl: avatar(32),
    role: 'user',
  },
  {
    key: 'kit',
    email: 'kittipong@example.com',
    displayName: 'กิตติพงษ์ ทองดี',
    avatarUrl: null,
    role: 'user',
  },
  {
    key: 'onuma',
    email: 'onuma@example.com',
    displayName: 'อรอุมา พรหมมา',
    avatarUrl: avatar(48),
    role: 'user',
  },
  {
    key: 'tana',
    email: 'tanawat@example.com',
    displayName: 'ธนวัฒน์ มีสุข',
    avatarUrl: avatar(53),
    role: 'user',
  },
  {
    key: 'chanida',
    email: 'chanida@example.com',
    displayName: 'ชนิดา วงศ์ไทย',
    avatarUrl: avatar(26),
    role: 'user',
  },
  {
    key: 'weera',
    email: 'weerayut@example.com',
    displayName: 'วีรยุทธ บุญมา',
    avatarUrl: null,
    role: 'user',
  },
  {
    key: 'siri',
    email: 'siriporn@example.com',
    displayName: 'ศิริพร คำแก้ว',
    avatarUrl: avatar(41),
    role: 'user',
  },
  {
    key: 'alex',
    email: 'alex.turner@example.com',
    displayName: 'Alex Turner',
    avatarUrl: avatar(59),
    role: 'user',
  },
  {
    key: 'mai',
    email: 'mai.tran@gmail.com',
    displayName: 'Mai Tran',
    avatarUrl: avatar(20),
    role: 'user',
    googleOnly: true,
  },
  {
    key: 'phum',
    email: 'phum.rakthai@gmail.com',
    displayName: 'ภูมิ รักษ์ไทย',
    avatarUrl: avatar(68),
    role: 'user',
    googleOnly: true,
  },
  {
    key: 'nat',
    email: 'natcha@example.com',
    displayName: 'ณัฐชา อินทร์แก้ว',
    avatarUrl: avatar(9),
    role: 'user',
  },
];

export const BANNERS = [
  {
    imageUrl: '/uploads/images/banner-1-wood-gold.png',
    title: 'สูตรเด็ดจากเชฟประจำสัปดาห์',
    description: 'คัดสูตรขายดีจากเชฟของเรา ทำตามได้ทุกขั้นตอน',
  },
  {
    imageUrl: '/uploads/images/banner-2-fresh-green.png',
    title: 'กินคลีนแบบไม่จำเจ',
    description: 'รวมเมนูสุขภาพ ไขมันต่ำ ผักเยอะ อิ่มอร่อย',
  },
  {
    imageUrl: '/uploads/images/banner-3-promo-red.png',
    title: 'โปรเปิดครัว',
    description: 'สูตรเชฟราคาพิเศษตลอดเดือนนี้',
  },
];

/** วิดีโอที่มีอยู่แล้วใน R2 ใช้เป็นสื่อของขั้นตอนที่ต้องซื้อ */
export const STEP_VIDEOS = [
  '/uploads/videos/090bf045-6467-4769-8acf-f3453ca30b45.mp4',
  '/uploads/videos/fccf6616-5680-423a-8878-d5c84065f747.mp4',
];

export const REVIEW_COMMENTS: Record<number, string[]> = {
  5: [
    'อร่อยมาก ทำตามได้ง่าย ที่บ้านชอบกันทุกคน',
    'สูตรละเอียดมาก ได้รสชาติเหมือนร้านเลย',
    'คุ้มค่ามาก ทำซ้ำไปสามรอบแล้ว',
    'อธิบายเข้าใจง่าย มือใหม่ก็ทำได้',
    'รสชาติกลมกล่อม ไม่ต้องปรับอะไรเพิ่มเลย',
    'วิดีโอช่วยได้เยอะ เห็นภาพชัดเจน',
    'ทำให้แฟนกิน ชมไม่หยุดเลยค่ะ',
    'เคล็ดลับท้ายสูตรใช้ได้จริง',
  ],
  4: [
    'อร่อยดี แต่ส่วนตัวลดน้ำตาลลงนิดหน่อย',
    'ทำตามง่าย ใช้เวลานานกว่าที่บอกนิดนึง',
    'รสชาติดี อยากให้มีตัวเลือกแบบไม่เผ็ดด้วย',
    'โอเคเลย วัตถุดิบหาง่าย',
    'ดีครับ ครั้งหน้าจะลองเพิ่มสมุนไพร',
    'ชอบครับ แต่ปริมาณสำหรับ 2 คนดูเยอะไปนิด',
  ],
  3: [
    'พอใช้ได้ รสชาติยังไม่ถึงกับว้าว',
    'ขั้นตอนบางช่วงอยากให้อธิบายละเอียดกว่านี้',
    'ทำออกมาเค็มไปหน่อย อาจเพราะยี่ห้อน้ำปลา',
    'กลาง ๆ ครับ',
  ],
  2: ['ทำตามแล้วไม่ค่อยเหมือนในรูป', 'ใช้เวลานานกว่าที่เขียนไว้มาก'],
};

export const COMMENTS = [
  'น่ากินมากเลยค่ะ เดี๋ยวลองทำตามบ้าง',
  'ทำตามแล้วอร่อยมากครับ ขอบคุณที่แชร์',
  'ใช้หมูแทนไก่ได้ไหมคะ',
  'เพิ่มพริกอีกนิดจะแซ่บขึ้นอีก',
  'ทำกินเมื่อวาน ลูก ๆ ชอบมาก',
  'สูตรนี้ใช้หม้อทอดไร้น้ำมันได้ไหมครับ',
  'ชอบที่วัตถุดิบหาง่าย',
  'หน้าตาเหมือนร้านเลย',
  'ลองลดน้ำตาลลงครึ่งหนึ่ง ก็ยังอร่อยค่ะ',
  'เก็บไว้ทำวันหยุดนี้เลย',
  'ถ้าไม่มีซอสหอยนางรมใช้อะไรแทนได้บ้างคะ',
  'ทำครั้งแรกก็สำเร็จ ขอบคุณครับ',
  'กลิ่นหอมมาก ทั้งบ้านตามกลิ่นมาเลย',
  'ใส่ผักเพิ่มอีกนิดก็ดีต่อสุขภาพ',
  'อยากให้ลงสูตรแบบเจด้วยค่ะ',
];
