<div dir="rtl">

# npm-offline-mirror

> یک **رجیستری محلی npm** سبک و مبتنی بر Docker (با [Verdaccio](https://verdaccio.org)) که از قبل با معروف‌ترین پکیج‌های فرانت‌اند، بک‌اند و ابزارهای توسعه پر می‌شود؛ تا بتوانید روزها یا حتی هفته‌ها **بدون اینترنت** روی پروژه‌های JavaScript / Node.js کار کنید.

🇬🇧 [English README](README.md)

## نحوه کار

```
 آنلاین                                      آفلاین
 ──────                                      ───────
 npm / pnpm / yarn ─► Verdaccio ─► npmjs     npm / pnpm / yarn ─► Verdaccio (فقط کش)
                          │
                      volume کش  ◄── با `make export` خروجی می‌گیرید و با `make import` برمی‌گردانید
```

* یک کانتینر و یک volume. هر چیزی که از طریق این رجیستری نصب کنید برای همیشه کش می‌شود.
* دستور `make warmup` حدود ۷۵۰ پکیج منتخب را **به‌همراه همه وابستگی‌هایشان** از قبل دانلود می‌کند (React، Next، Vue، Angular، Express، NestJS، Prisma، Tailwind، Vite، Jest، ESLint و ...).
* دستور `make popular` می‌تواند N پکیج پرمصرف npm را هم اضافه کند.
* دستورهای `make export` و `make import` همه چیز (ایمیج + کش) را روی فلش یا سیستم دیگر منتقل می‌کنند.

> **چرا «کل npm» نه؟** کل رجیستری ده‌ها ترابایت است. کش منتخب + کش خودکار، ۹۹٪ فایده را با چند گیگابایت می‌دهد.

## پیش‌نیازها

* Docker با Compose نسخه ۲
* Node.js نسخه ۱۸ یا بالاتر (فقط روی هاست و برای `warmup`)
* `make` و `bash` و `curl` (در ویندوز از WSL2 یا Git Bash استفاده کنید)

## شروع سریع

```bash
git clone https://github.com/DANIYYL/NpmOfflineMirror.git
cd npm-offline-mirror

make up          # ساخت و اجرای رجیستری روی http://localhost:4873
make warmup      # (آنلاین) کش همه لیست‌های packages/*.txt – زمان‌بر است
make size        # حجم کش
```

اتصال یک پروژه به رجیستری:

```bash
make client P=../my-app           # فایل ../my-app/.npmrc را می‌نویسد
# یا سراسری:
bash scripts/use-registry.sh --global
```

از این به بعد `npm install <هر چیزی>` از طریق رجیستری کار می‌کند. پکیجی که هنوز کش نشده باشد، تا وقتی آنلاین هستید از npmjs گرفته و **کش** می‌شود.

## لیست پکیج‌ها

| فایل | محتوا |
|---|---|
| `packages/frontend.txt` | React/Vue/Angular/Svelte/Next/Nuxt، مدیریت state، فرم، کتابخانه‌های UI، نمودار، ادیتور و ... |
| `packages/backend.txt` | Express/Fastify/NestJS/Koa/Hono، احراز هویت، ORM و درایور دیتابیس، صف، SDKهای ابری، ابزارهای کمکی و ... |
| `packages/tooling.txt` | TypeScript، Vite/Webpack/Rollup/esbuild، Babel، ESLint/Prettier، Jest/Vitest/Playwright، `@types/*` و ... |
| `packages/persian.txt` | *(اختیاری)* ابزارهای فارسی/راست‌به‌چپ/تاریخ شمسی – اگر لازم ندارید پاکش کنید |
| `packages/custom.txt` | **مال شما.** هر پکیجی که می‌خواهید از قبل کش شود اینجا اضافه کنید |
| `packages/popular-auto.txt` | با `make popular N=3000` ساخته می‌شود (در گیت نادیده گرفته می‌شود) |

قالب: هر خط یک نام، `#` برای کامنت، و امکان قفل نسخه (`react@18.3.1`). نام‌های ناموجود رد می‌شوند و در `warmup-failed.txt` ثبت می‌شوند.

## چک‌لیست قبل از آفلاین شدن

1. `make up && make warmup` (و برای پکیج‌های بیشتر: `make popular && make warmup`)
2. برای هر پروژه‌ای که رویش کار می‌کنید: `make warm-project P=../my-app` تا **دقیقاً** نسخه‌های lockfile کش شوند.
3. اگر استفاده می‌کنید: `make binaries` (فایل‌های Playwright، Puppeteer، Cypress و Prisma – بخش [محدودیت‌ها](#محدودیتها))
4. `EXTRA_IMAGES="node:22-alpine postgres:16" make export` – ایمیج رجیستری، کش و ایمیج‌های پایه را در `dist/` ذخیره می‌کند.
5. اختیاری: `make offline` برای حالت کاملاً آفلاین (بدون معطلی روی شبکه قطع‌شده)

## انتقال به سیستم دیگر / بازیابی

```bash
# روی سیستم جدید (بدون نیاز به اینترنت)
bash scripts/import.sh           # ایمیج‌ها را لود و کش را بازیابی می‌کند
docker compose up -d --no-build  # یا: make offline
```

پوشه `dist/` چند گیگابایت است و در گیت نادیده گرفته می‌شود. با فلش، S3/MinIO یا Release گیت‌هاب (حداکثر ۲ گیگ برای هر فایل؛ با `split -b 1900m` تکه کنید) منتقلش کنید.

## استفاده از رجیستری در build داکر پروژه‌ها

```dockerfile
# Dockerfile پروژه شما
RUN npm config set registry http://host.docker.internal:4873/
```

```bash
docker build --add-host=host.docker.internal:host-gateway .   # روی لینوکس لازم است
```

یا کامپوز پروژه‌تان را به شبکه همین رجیستری وصل کنید و از `http://npm-registry:4873/` استفاده کنید.

## pnpm و Yarn

* **pnpm و Yarn 1**: همان `.npmrc` (یعنی `registry=http://localhost:4873/`) کار می‌کند.
* **Yarn Berry**: در `.yarnrc.yml` مقدار `npmRegistryServer: "http://localhost:4873"` و `unsafeHttpWhitelist: ["localhost"]` را بگذارید.

## دستورها

| دستور | کار |
|---|---|
| `make up` / `make down` | روشن / خاموش کردن رجیستری (کش می‌ماند) |
| `make warmup` | کش همه `packages/*.txt` |
| `make popular N=3000` | ساخت لیست N پکیج پرمصرف |
| `make warm-project P=<dir>` | کش نسخه‌های lockfile یک پروژه |
| `make binaries` | کش باینری‌های Playwright / Puppeteer / Cypress / Prisma |
| `make offline` / `make online` | تعویض تنظیمات (بدون اینترنت / با اینترنت) |
| `make export` / `make import` | بکاپ / بازیابی کامل از طریق `dist/` |
| `make size` | حجم کش |
| `make client P=<dir>` | نوشتن `.npmrc` در پروژه |

## محدودیت‌ها

* **باینری‌هایی که بیرون از npm دانلود می‌شوند** در رجیستری کش نمی‌شوند: مرورگرهای Puppeteer/Playwright، Cypress، Electron، موتورهای Prisma، هدرهای `node-gyp` و ماژول‌های native که prebuild را از GitHub می‌گیرند (`sqlite3`، `better-sqlite3` و بعضی نسخه‌های `bcrypt`). از `make binaries` استفاده کنید، پوشه‌های کش را بکاپ بگیرید، یا جایگزین‌های pure-JS (مثل `bcryptjs`) به‌کار ببرید.
* `warmup` فقط **آخرین نسخه** هر پکیج را می‌گیرد. نسخه‌های قدیمی‌تر وقتی کش می‌شوند که از طریق رجیستری نصبشان کنید (یا با `make warm-project`).
* `warmup` با `--ignore-scripts --force` کار می‌کند: اسکریپت‌ها اجرا نمی‌شوند و پکیج‌های وابسته به پلتفرم برای همه سیستم‌عامل‌ها (مک، ویندوز، لینوکس) دانلود می‌شوند.
* apt/apk/pip و مانند آن‌ها پوشش داده نمی‌شوند (فقط npm).

## سؤالات متداول

**می‌شود دو رجیستری جدا (فرانت / بک‌اند) داشت؟**
بله، ولی وابستگی‌های مشترک دو بار ذخیره می‌شوند. اگر می‌خواهید، نمونه دوم را با پورت و volume دیگر اجرا کنید:

```yaml
services:
  npm-registry-backend:
    image: npm-offline-mirror:latest
    ports: ["4874:4873"]
    volumes: ["npm-mirror-backend:/verdaccio/storage"]
volumes:
  npm-mirror-backend:
```
سپس: `REGISTRY=http://localhost:4874 bash scripts/warmup.sh packages/backend.txt`

**چرا کش داخل ایمیج نیست؟**
با اضافه شدن هر پکیج باید ایمیجِ چند گیگابایتی دوباره ساخته شود. volume تدریجی است و `make export` برای انتقال همه را یک‌جا بسته‌بندی می‌کند.

**آفلاین نصب کند است یا گیر می‌کند.**
`make offline` را اجرا کنید؛ آپ‌لینک حذف می‌شود و Verdaccio فوراً از کش جواب می‌دهد.

## مشارکت

افزودن پکیج‌های معروف به `packages/*.txt` با Pull Request خوشحال‌کننده است. قبلش `bash scripts/check-lists.sh` را اجرا کنید.

## لایسنس

[MIT](LICENSE)

</div>
