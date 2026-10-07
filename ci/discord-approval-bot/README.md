# อนุมัติ Jenkins Production Approval ผ่านปุ่มใน Discord

Bot นี้รันบนคอม Windows ของคุณผ่าน Discord Gateway และตรวจ Jenkins จากคอมโดยตรง ไม่ต้องเปิดพอร์ต, ใช้ Worker, หรือแก้ k3s. คอมต้องเข้าถึง Jenkins และ Discord ได้ และต้องเปิดอยู่ระหว่างที่รออนุมัติ

Bot ใช้ `input` gate เดิมใน `ci/Jenkinsfile.backend` โดยอ่าน `wfapi/pendingInputActions` ของ build ล่าสุดใน backend `main` ทุก 10 วินาที เมื่อมี gate ใหม่จะส่งข้อความพร้อมปุ่ม จากนั้นตรวจ Discord user ID และยืนยันว่า Jenkins ยังรอ gate เดิมก่อนส่ง `POST` ไปยัง `proceedEmpty`

## 1. เตรียม Discord Application

1. ไปที่ <https://discord.com/developers/applications> สร้าง Application และ Bot
2. ที่ **Bot** คัดลอก Bot Token เก็บไว้ในเครื่อง ห้ามส่ง token ในแชตหรือ commit ลง Git
3. ที่ **Installation** เลือก **Guild Install**, scope `bot`, สิทธิ์ `Send Messages` แล้วติดตั้ง Bot ลง server ที่ต้องการ
4. เปิด Developer Mode ใน Discord แล้วคัดลอก Server ID, Channel ID และ User ID ของผู้อนุมัติแต่ละคน
5. ที่ **General Information** ให้ช่อง **Interactions Endpoint URL** ว่างไว้ เพราะ Bot นี้รับปุ่มผ่าน Gateway หากเคยใส่ URL ของ Worker ให้ลบออก

ไม่ต้องเปิด Message Content Intent หรือ Privileged Intents สำหรับปุ่มนี้

## 2. ตรวจ Jenkins จากคอมเครื่องนี้

เปิด URL ของ Jenkins จากคอมนี้ให้ได้ก่อน จากนั้นระหว่างที่ build ของ backend `main` กำลังรอ `Production Approval` ให้เปิด URL ลักษณะนี้:

```text
https://<jenkins-host>/job/<backend-job>/job/main/<build-number>/wfapi/pendingInputActions
```

ควรได้ JSON array ที่มี `id` และ `proceedUrl`. หากได้ 404 ให้ตรวจว่าติดตั้ง Pipeline: REST API plugin และตรวจ path ของ job. Bot ต้องชี้ `JENKINS_MAIN_JOB_URL` ไปที่ **job ของ branch main** โดยตรง เช่น `https://jenkins.example.com/job/backend/job/main/` ไม่ใช่หน้า Jenkins หลัก

สร้าง Jenkins user สำหรับ Bot ที่มีสิทธิ์อ่าน job/build และอนุมัติ `input` แล้วสร้าง API token ที่ **ชื่อผู้ใช้ → Security**. ใช้ API token แทน password; Jenkins ระบุว่าคำขอที่ยืนยันตัวตนด้วย API token ไม่ต้องมี CSRF crumb

## 3. ตั้งค่าและรันบน Windows

ใน PowerShell ให้เข้าโฟลเดอร์นี้ แล้วสร้าง virtual environment:

```powershell
cd C:\Users\Acer\Documents\Recipy\Mobile-app_AOV\ci\discord-approval-bot
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
```

เปิด `.env` แล้วใส่ค่าจริงทุกช่อง:

```dotenv
DISCORD_BOT_TOKEN=<bot-token>
DISCORD_GUILD_ID=<server-id>
DISCORD_CHANNEL_ID=<channel-id>
APPROVER_IDS=<user-id-1>,<user-id-2>
JENKINS_MAIN_JOB_URL=https://<jenkins-host>/job/<backend-job>/job/main/
JENKINS_USER=<bot-jenkins-username>
JENKINS_API_TOKEN=<jenkins-api-token>
```

`.env` ถูก ignore โดย Git แล้ว เก็บสิทธิ์เข้าถึงไฟล์นี้เฉพาะบัญชี Windows ที่รัน Bot

สั่งรัน:

```powershell
.\.venv\Scripts\python.exe bot.py
```

เมื่อเห็น `Logged in as ...; watching ...` แปลว่า Bot เชื่อม Discord แล้ว Bot จะตรวจ Jenkins ต่อทุก 10 วินาที ถ้าปิด PowerShell หรือคอม sleep Bot จะหยุดทำงาน

## 4. ทดลองแบบไม่ deploy production

1. ตรวจว่า Bot ออนไลน์ใน Discord และ log ไม่มี HTTP 401/403/404 จาก Jenkins
2. ใช้ Jenkins job ทดลองที่มี `input` ข้อความ `Deploy to production?` และชี้ `JENKINS_MAIN_JOB_URL` ไปยัง job ทดลองก่อน
3. เมื่อ job รอ gate ให้ตรวจว่าข้อความพร้อมปุ่มปรากฏใน channel เพียงครั้งเดียว
4. ทดลองกดด้วย Discord user ที่ **ไม่อยู่** ใน `APPROVER_IDS` ต้องถูกปฏิเสธ
5. ทดลองกดด้วยผู้ที่มีสิทธิ์ ต้องเห็น Jenkins ไปต่อและข้อความใน Discord แสดง user ID ผู้อนุมัติ
6. ค่อยเปลี่ยน `JENKINS_MAIN_JOB_URL` กลับเป็น backend `main`

Bot เก็บรหัส gate กับ Discord message ID ใน `.state.sqlite3` เพื่อรับปุ่มเก่าต่อได้หลังรีสตาร์ต อย่าลบไฟล์นี้ระหว่างที่มี build รออนุมัติ

ตอนนี้ `ci/Jenkinsfile.backend` ยังส่ง webhook แจ้ง `Production Approval Required` อยู่ จึงจะเห็นข้อความ webhook เดิมกับข้อความปุ่มจาก Bot อย่างละหนึ่งข้อความ หลังทดสอบ Bot สำเร็จแล้วจึงค่อยเอา notification เดิมออกหากต้องการ

## 5. ให้ Bot เริ่มเมื่อเปิดเครื่อง

หลังทดสอบด้วย PowerShell สำเร็จ ให้ใช้ Windows Task Scheduler สร้าง task **At log on** หรือ **At startup** ที่รัน `C:\Users\Acer\Documents\Recipy\Mobile-app_AOV\ci\discord-approval-bot\.venv\Scripts\python.exe` โดยใส่ argument เป็น path เต็มของ `bot.py` และตั้ง **Start in** เป็นโฟลเดอร์ `ci\discord-approval-bot`. ใช้บัญชี Windows ที่อ่าน `.env` ได้ และตั้ง Power/Windows ไม่ให้ sleep ระหว่างที่ต้องรออนุมัติ

## ข้อจำกัด

- Bot ตรวจเฉพาะ build ล่าสุดของ backend `main` ตาม `JENKINS_MAIN_JOB_URL`
- `ci/Jenkinsfile.backend` ตั้ง timeout **รวมทั้ง pipeline 60 นาที**; หากคอมดับนาน gate จะหมดเวลาไปตาม Jenkins
- หากกด Abort ใน Jenkins ปุ่มเก่าอาจยังแสดงอยู่ แต่เมื่อกด Bot จะตรวจ Jenkins อีกครั้งและไม่อนุมัติ gate ที่ไม่รอแล้ว
- หาก Bot ส่งข้อความสำเร็จแล้วปิดตัวทันที ก่อนบันทึก SQLite อาจส่งข้อความซ้ำหลังรีสตาร์ต ให้ใช้ข้อความล่าสุดและตรวจ Jenkins build URL ก่อนกด
