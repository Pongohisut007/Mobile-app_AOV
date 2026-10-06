# การทำงานของ CI

## ตำแหน่ง Pipeline

งาน Multibranch ของแต่ละส่วนใช้ `ci/Jenkinsfile.backend` และ
`ci/Jenkinsfile.frontend` โดย branch ที่ต้องการให้ build ต้องมีไฟล์ทั้งสองนี้
ไม่ได้ใช้ `Jenkinsfile` ที่ราก repo ควรปิดงานแบบรวมเดิมเพื่อไม่ให้ build และ deploy ซ้ำ
การจัดคิว build ด้วย `disableConcurrentBuilds()` มีผลแยกตามงานและ branch
ไม่ได้จัดคิวข้ามงาน

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

ขั้นตอนนี้ build และเก็บ App Bundle แบบ release ที่เซ็นด้วย release key
โดยใช้ `config/prod.json` และใส่ API URL สำหรับ build ครั้งนั้น พร้อมปิด
การซื้อจำลอง หากยังไม่ได้ตั้ง URL และ credentials งาน build บน `main`
จะล้มเหลวตามที่ตั้งใจไว้ ส่วน debug build ยังใช้ debug key ที่ทีมแชร์กัน

## ร่างแผนลบ `DB_SYNCHRONIZE`

Backend ยังไม่อ่านค่า `DB_SYNCHRONIZE` จาก ConfigMap ของ chart จึงคงค่านี้ไว้
ในงานรอบนี้ หลังจากทดสอบ migration job กับฐานข้อมูล staging ที่มีอยู่
และเพิ่มพร้อมทดสอบ baseline migration สำหรับฐานข้อมูลใหม่แล้ว ให้ลบ
`config.dbSynchronize` จาก `values.yaml` และ `DB_SYNCHRONIZE` จาก
`templates/configmap.yaml` โดยให้พฤติกรรมจัดการ schema อ้างอิง `APP_ENV`
ที่ผ่านการตรวจค่าแล้ว และไม่เปิด synchronize ใน staging หรือ production
