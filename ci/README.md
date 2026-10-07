# การทำงานของ CI

## ตำแหน่ง Pipeline

งาน Multibranch ของแต่ละส่วนใช้ `ci/Jenkinsfile.backend` และ
`ci/Jenkinsfile.frontend` โดย branch ที่ต้องการให้ build ต้องมีไฟล์ทั้งสองนี้
ไม่ได้ใช้ `Jenkinsfile` ที่ราก repo ควรปิดงานแบบรวมเดิมเพื่อไม่ให้ build และ deploy ซ้ำ
การจัดคิว build ด้วย `disableConcurrentBuilds()` มีผลแยกตามงานและ branch
ไม่ได้จัดคิวข้ามงาน

เมื่อมีการ push ทั้งสอง Multibranch jobs อาจเริ่มทำงาน แต่การแก้ไฟล์ CI เฉพาะ
frontend จะไม่ตั้ง `BACKEND_CHANGED` และการแก้ไฟล์ CI เฉพาะ backend จะไม่ตั้ง
`FRONTEND_CHANGED` ไฟล์ CI ที่ใช้ร่วมกันยังทำให้ทั้งสองส่วนรัน ส่วนขั้นตรวจหา
ความลับยังรันในทุก build ตามหัวข้อถัดไป

## การตรวจหาความลับ

Pipeline ทั้งสองส่วนรัน Gitleaks ในทุก branch และ PR รวมถึงโหมด FAST
การแก้เอกสาร และการแก้ไฟล์ที่ไม่เกี่ยวกับส่วนของงานนั้น แต่ละงานสแกนทั้ง repo
ไม่ใช่เฉพาะไดเรกทอรี frontend หรือ backend หากพบความลับ build จะหยุด
และรายงานจะปิดบังค่าความลับ

รายการยกเว้นของกฎ `generic-api-key` สำหรับตัวอย่างใน README ต้องตรงทั้ง
ตำแหน่ง `backend/README.md` และ token ตัวอย่าง `abc123def456`
ความลับอื่นในไฟล์เดียวกันยังถูกสแกน การสแกน Git ยังคงตรวจประวัติ commit
ตามพฤติกรรมเดิม

## Image และการ deploy

Backend image ที่ผ่านการตรวจถูก push ไปยัง Docker Hub repository สาธารณะ
`docker.io/pongphisut/taskflow-api` โดย Pipeline เข้าสู่ระบบด้วย Jenkins credential
`dockerhub` ชนิด Username with password: ชื่อผู้ใช้ Docker Hub และ access token
ที่มีสิทธิ์ Read & Write Pipeline อ่าน cache จาก tag `buildcache` เดิมได้
แต่ไม่อัปเดต tag นี้อีกแล้ว ขั้นตอน GitOps เปลี่ยน `image.tag` และเปิด migration
ส่วน image repository อ่านจาก `values.yaml` ของ chart

Image tag ใช้ commit SHA เต็มของโค้ดที่ checkout ดังนั้นการแก้การตั้งค่า CI หรือ build
จะได้ tag ใหม่แม้โค้ด backend ไม่เปลี่ยน การรัน commit เดิมซ้ำจะ build image
ในเครื่อง CI ใหม่ แล้วสแกนและทดสอบก่อน push ไปยัง registry ทุกครั้ง
Helm values ยังคงรับค่า `IMAGE_TAG` เช่นเดิม

งาน build ของ job และ branch เดียวกันเข้าคิวด้วย `disableConcurrentBuilds()`
เพื่อไม่ให้ build เก่ารออนุมัติแล้ว deploy ตามหลัง build ใหม่ ควรปล่อยให้ build
ที่เริ่มก่อนการเปลี่ยนแปลงนี้จบหรือยกเลิกก่อนพึ่งพาเงื่อนไขดังกล่าว
กฎ deploy คือ `develop` ไป staging และ `main` ไป production หลังอนุมัติ
branch สำหรับ feature และ PR ไม่ deploy โดย Pipeline มี timeout รวม 60 นาที

## การตรวจสอบ

```sh
git diff --check
```

รันงาน Multibranch ทั้งสองเพื่อยืนยันว่า Pipeline ใช้ได้กับ Jenkins plugins
ที่ติดตั้ง ตรวจว่า feature branch และ PR สแกนความลับแต่ไม่ deploy
และตรวจว่า image scan กับ E2E ของ backend ผ่านก่อนอนุมัติ production

## Migration และการเผยแพร่ image

ทั้งสอง environment ที่ deploy ใช้ `NODE_ENV=production` ส่วน `APP_ENV`
กำหนดพฤติกรรมของแอปเป็น staging หรือ production Migration job ใช้ runner
จาก image tag เดียวกับที่จะ deploy และต้องสำเร็จก่อนอัปเดต API Deployment
Jenkins เปิด `migration.enabled` ตอนเปลี่ยน GitOps image tag เป็น image
ที่มี runner นี้แล้ว ห้ามเปิด job ดังกล่าวกับ image tag รุ่นเก่าที่ไม่มี runner

Migration ที่มีอยู่เป็นการเปลี่ยน schema เพิ่มเติม จึงต้องมีตาราง `users`
และ `recipes` อยู่ก่อน คลัสเตอร์ใหม่ที่มีฐานข้อมูลว่างต้องมี baseline migration
ที่ผ่านการตรวจทานก่อน deploy ครั้งแรก Runner จะหยุดพร้อมข้อความระบุสาเหตุ
หากยังไม่มี schema ตั้งต้น

ชุด E2E ใน CI สร้าง schema เดิมด้วยการ synchronize ในโหมด development ก่อน
จากนั้นรัน migration เพิ่มเติม แล้วทดสอบ HTTP โดยใช้ `NODE_ENV=production`
ทั้งกรณี `APP_ENV=staging` และ `APP_ENV=production` วิธีนี้ตรวจเส้นทาง
การอัปเกรด แต่ยังไม่ทดแทนการทดสอบ baseline บนฐานข้อมูลว่าง

PR แบบ FULL จะ build และสแกน Docker image ในเครื่อง CI โดยไม่ได้รับ credential
สำหรับเขียนไปยัง Docker Hub หรือ GitOps สำหรับ `develop` และ `main`
Pipeline จะ push image ที่ตรวจแล้วหลัง Trivy, E2E และการตรวจ SBOM
(เฉพาะ `main`) ผ่าน Pipeline อ่าน remote build cache ได้ แต่ไม่อัปเดต cache นั้น

## เงื่อนไข Android release

Frontend build บน `main` ต้องมี Jenkins environment variable
`MOBILE_API_BASE_URL` เป็น HTTPS API URL และต้องมี Jenkins credentials ดังนี้:
`android-upload-keystore` (ไฟล์), `android-keystore-password`,
`android-key-alias` และ `android-key-password` (secret text)

ขั้นตอนนี้ build และเก็บ APK แบบ release ที่เซ็นด้วย release key สำหรับแจกให้ติดตั้งเอง
(บัญชี Android Developer Console แบบ limited distribution ไม่ได้ลง Play Store)
โดยใช้ `config/prod.json` และใส่ API URL สำหรับ build ครั้งนั้น (เปิดการซื้อจำลอง
เพราะยังไม่มีระบบจ่ายเงินจริง) หากยังไม่ได้ตั้ง URL และ credentials งาน build บน `main`
จะล้มเหลวตามที่ตั้งใจไว้ `main` ไม่ build debug APK แล้ว ส่วน branch อื่นยังสร้าง
debug APK ด้วย debug key ที่ทีมแชร์กัน

## ค่าที่ต้องเตรียมก่อนทดลอง Pipeline

### Feature branch และ PR

Feature branch ที่ชื่อ `feature/...` รัน FAST; PR รัน FULL แต่ไม่ publish image
หรือ deploy การทดสอบ E2E ใช้ค่าจำลองจาก `backend/docker-compose.ci.yaml`
จึงไม่ต้องใส่ production secret เพื่อทดลองสองกรณีนี้ ต้องมี Jenkins jobs,
agent images, PVC และเครื่องมือของ CI ตามไฟล์ใน `ci/pods/` อยู่แล้ว

### Jenkins สำหรับ `develop` และ `main`

- Backend บน `develop` และ `main`: credential `dockerhub` ชนิด Username with
  password สำหรับ push image, `github-jenkins` สำหรับเขียน GitOps repo,
  การตั้งค่า SonarQube ชื่อ `SonarQube` พร้อม webhook สำหรับ Quality Gate,
  และ `discord-webhook-url` สำหรับการแจ้งผล CI
- Backend บน `main` เพิ่ม `cosign-private-key` (file), `cosign-password`
  (secret text) และ `cosign-public-key` (file) สำหรับเซ็นและตรวจ SBOM
- Frontend บน `main` เพิ่ม `MOBILE_API_BASE_URL` เป็น HTTPS URL และ Android
  signing credentials ทั้งสี่รายการในหัวข้อก่อนหน้า

ตรวจว่า Jenkins Multibranch jobs ชี้ไปที่ `ci/Jenkinsfile.backend` และ
`ci/Jenkinsfile.frontend` และเห็น branch ที่ push ขึ้น remote แล้ว

ทั้งสอง Pipeline แจ้ง Discord เมื่อ CI ของ PR ที่มี target เป็น `main` หรือ
`develop` จบ รวมถึงผล success, failure, unstable และ aborted โดยระบุเลข PR,
source, target และลิงก์ PR ส่วน build ของ branch `main`/`develop` หลัง merge
ยังแจ้งเช่นเดิม ต้องตั้งค่า Multibranch ให้ค้นพบ PR เหล่านี้และให้ trusted PR
build เข้าถึง credential `discord-webhook-url` ห้ามเปิด credential นี้ให้ PR
จาก source ที่ไม่เชื่อถือ เพราะ PR แก้ Jenkinsfile และสคริปต์ส่งแจ้งเตือนได้
หากต้องแจ้ง PR จาก fork ด้วย ให้ส่งผ่าน Jenkins job ที่ใช้ trusted Jenkinsfile
แยกต่างหากซึ่งไม่ได้รันโค้ดจาก PR

แจ้งเตือน Frontend และ Backend แสดง branch/PR กับ full commit SHA เดียวกัน
เพื่อจับคู่สอง job ได้ โดยหัวข้อความระบุ component ชัดเจน Frontend บน
`main` จะแนบลิงก์ release APK และบน `develop` จะแนบลิงก์ debug APK เมื่อ
build และ archive artifact สำเร็จ หากรอบนั้นไม่มีการเปลี่ยน frontend หรือ
build APK ไม่สำเร็จ จะไม่มีลิงก์ APK ลิงก์เปิดผ่าน Jenkins จึงต้องมีสิทธิ์
เข้าถึง Jenkins และ Jenkins ต้องตั้ง `BUILD_URL` ให้เป็น URL ที่ผู้รับเปิดได้

### ค่า runtime ใน staging และ production

Chart สร้าง ConfigMap สำหรับ `NODE_ENV`, `APP_ENV`, `PORT`, `DB_HOST`,
`DB_PORT`, `DB_NAME`, `JWT_EXPIRES_IN`, `BCRYPT_SALT_ROUNDS` และ `REDIS_URL`
อยู่แล้ว ค่า `DB_USER`, `DB_PASSWORD`, `JWT_SECRET` และ `R2_*` มาจาก
Kubernetes Secret ที่ chart สร้างหรือจาก `secrets.existingSecret`

ก่อน deploy จริง ต้องแทน `JWT_SECRET` และรหัส PostgreSQL ตัวอย่างใน chart
ด้วยค่าของแต่ละ environment ผ่าน Secret ที่จัดการแยก ตรวจว่า Secret
`taskflow-extra-env` ใน namespace ของ environment นั้นมี `PSU_AI_API_KEY`
ที่ใช้ได้ ไฟล์ SealedSecret ใน GitOps repo ไม่ได้อยู่ใต้ path ของ Argo CD
Application สำหรับ chart จึงต้องตรวจว่าได้นำไปใช้และถอดรหัสเป็น Secret แล้ว
แม้ chart ระบุ extra Secret เป็น optional แต่ backend สร้าง AI client ตอนเริ่ม
แอปและอาจเริ่มไม่ขึ้นเมื่อไม่มี API key

ถ้าจะทดสอบความสามารถของแอปครบ ให้ตั้ง `R2_ACCOUNT_ID`,
`R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET_NAME` สำหรับอัปโหลด,
`GOOGLE_CLIENT_IDS` ให้ตรงกับ client ID ที่ฝังใน mobile build สำหรับ Google
Sign-In และ `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `MAIL_FROM`
สำหรับอีเมลรีเซ็ตรหัสผ่าน ใน staging หากไม่ตั้ง SMTP แอปจะพิมพ์อีเมลลง log;
ใน production คำขอส่งอีเมลจะล้มเหลว ค่า `PSU_AI_BASE_URL` และ `PSU_AI_MODEL`
มีค่าเริ่มต้นในโค้ด ส่วน `TRUST_PROXY` ต้องกำหนดตามจำนวน proxy ที่เชื่อถือ
หากต้องการให้ rate limit เห็น IP ผู้ใช้จริง

`frontend/config/staging.json` และ `frontend/config/prod.json` ยังมี
`API_BASE_URL` ว่าง โดย CI ของ `develop` สร้าง debug APK จาก `config/dev.json`
ซึ่งชี้ emulator ไปที่เครื่องนักพัฒนา ไม่ได้สร้างแอปที่ชี้ staging API
การใส่ค่าใน `staging.json` อย่างเดียวจึงยังไม่เปลี่ยน artifact ของ CI
สำหรับ `main` release gate จะใช้ `MOBILE_API_BASE_URL` จาก Jenkins แทน

`DB_SYNCHRONIZE` ใน chart ยังไม่ถูก backend อ่าน จึงไม่ต้องใส่ค่าเพิ่มเพื่อ
เปิดหรือปิด schema synchronization ให้ใช้ `APP_ENV` ตามที่ chart กำหนด

## ร่างแผนลบ `DB_SYNCHRONIZE`

Backend ยังไม่อ่านค่า `DB_SYNCHRONIZE` จาก ConfigMap ของ chart จึงคงค่านี้ไว้
ในงานรอบนี้ หลังจากทดสอบ migration job กับฐานข้อมูล staging ที่มีอยู่
และเพิ่มพร้อมทดสอบ baseline migration สำหรับฐานข้อมูลใหม่แล้ว ให้ลบ
`config.dbSynchronize` จาก `values.yaml` และ `DB_SYNCHRONIZE` จาก
`templates/configmap.yaml` โดยให้พฤติกรรมจัดการ schema อ้างอิง `APP_ENV`
ที่ผ่านการตรวจค่าแล้ว และไม่เปิด synchronize ใน staging หรือ production
