<div align="center">

<img src="https://github.com/amnezia-vpn.png" alt="Amnezia" width="120" />

# Amnezia Web Panel Installer

**نصب خودکار و امن Amnezia Web Panel روی سرور شخصی شما**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Caddy](https://img.shields.io/badge/Caddy-1F88C0?logo=caddy&logoColor=white)](https://caddyserver.com/)

یک اسکریپت کامل و idempotent برای نصب Amnezia Web Panel روی VPS شخصی، با SSL خودکار و دسترسی امن HTTPS.

</div>

---

## ✨ ویژگی‌ها

<table>
<tr>
<td width="50%">

### 🐳 استقرار خودکار
- نصب خودکار **Docker** و **Docker Compose**
- دریافت ایمیج رسمی از `ghcr.io` یا build از سورس
- وب‌سرور سبک **Caddy** به عنوان Reverse Proxy
- نصب idempotent (اجرای مجدد خراب نمی‌شه)

</td>
<td width="50%">

### 🔐 امنیت پیشرفته
- **SSL خودکار** با Let's Encrypt
- Bind داخلی پنل روی `127.0.0.1:5000`
- `SECRET_KEY` ثابت برای حفظ نشست‌ها بعد از ری‌استارت
- `credentials.txt` با دسترسی `0600`

</td>
</tr>
<tr>
<td width="50%">

### 🎯 سادگی استفاده
- نصب با **یک دستور**
- فقط یک سؤال: دامنه
- دریافت اطلاعات ورود در پایان نصب
- بررسی خودکار DNS قبل از نصب

</td>
<td width="50%">

### 📊 مدیریت آسان
- مشاهده وضعیت سرویس‌ها با یک دستور
- لاگ‌های Caddy و Panel در دسترس
- پنل مدیریتی سبک و سریع
- بدون نیاز به تنظیمات پیچیده

</td>
</tr>
</table>

---

## ⚡ نصب سریع

فقط کافیه این یه دستور رو روی VPS تازه و تمیز (Ubuntu 22.04 یا 24.04) اجرا کنی:

```bash
curl -fsSL https://raw.githubusercontent.com/forouzanexchange-sys/amnezia-panel-installer/main/install.sh -o install.sh && bash -n install.sh && sudo bash install.sh
```

### 📝 در هنگام نصب، اسکریپت فقط یک سؤال می‌پرسه:

| # | سؤال | توضیح |
|---|------|-------|
| ۱ | 🌐 **دامنه** | مثل `panel.yourdomain.com` |

**نمونه‌ی اجرا:**

```
Enter your domain (e.g. panel.example.com): panel.qforo.xyz

[INFO] DNS: panel.qforo.xyz -> 203.0.113.5
[INFO] Pulled prebuilt image from ghcr.io
[INFO] Panel is up after 12s.
[INFO] UFW enabled. Open ports: 22, 80, 443
[INFO] Installation complete!
```

پسورد پیش‌فرض ادمین **`admin`** است. بعد از اولین ورود، از بخش **Users** آن را تغییر دهید.

---

## 📋 پیش‌نیازها

<div align="center">

| مورد | حداقل | توصیه‌شده |
|:---:|:---:|:---:|
| 🐧 **سیستم‌عامل** | Ubuntu 22.04 | Ubuntu 24.04 |
| 💾 **رم** | 1 GB | 2 GB |
| 💿 **فضا** | 5 GB | 10 GB |
| 🌐 **دامنه** | A Record به IPv4 | A + AAAA |
| 🔓 **پورت‌ها** | 22, 80, 443 | 22, 80, 443 |

</div>

### 🌐 تنظیم DNS

قبل از اجرا، مطمئن شو رکورد DNS دامنه‌ت به IP سرور اشاره می‌کنه:

```
نوع: A (یا AAAA برای IPv6)
نام: panel
مقدار: IP سرور VPS
TTL: خودکار
```

> ⚠️ **نکته:** این اسکریپت **خود Amnezia Server را نصب نمی‌کند**. بعد از نصب پنل، باید سرورهای Amnezia خود را از داخل پنل اضافه کنی.

---

## 🚪 ورود به پنل

در پایان نصب، **آدرس پنل** نمایش داده می‌شه.

| فیلد | مقدار |
|---|---|
| **Username** | `admin` |
| **Password** | `admin` |

> ⚠️ **مهم:** بعد از اولین ورود، فوراً از بخش **Users** پسورد را تغییر دهید.

برای مشاهده اطلاعات ورود ذخیره‌شده هنگام نصب:

```bash
sudo cat /opt/amnezia-panel/credentials.txt
```

> 🔒 رمز و فایل اطلاعات ورود را منتشر نکنید.

---

## 🔑 تغییر پسورد ادمین

پنل Amnezia Web Panel دستور CLI رسمی برای تغییر پسورد ندارد. **تغییر از داخل خود پنل انجام می‌شود:**

1. با `admin / admin` وارد شوید
2. به بخش **Users** بروید
3. روی کاربر `admin` کلیک کنید
4. گزینه **Change password** را بزنید
5. پسورد جدید را وارد و ذخیره کنید

> ℹ️ فایل `credentials.txt` به‌طور خودکار با تغییر پسورد از داخل پنل به‌روز نمی‌شود. اگر پسورد را عوض کردید، این فایل را دستی به‌روز کنید یا حذف کنید.

---

## 🛡️ لایه‌های امنیتی خودکار

اسکریپت این کارها را **به صورت خودکار** انجام می‌ده:

- ✅ **UFW Firewall**: فقط پورت‌های 22 (یا پورت SSH شما)، 80، 443 باز می‌شن
- ✅ **SSL خودکار**: Caddy گواهی Let's Encrypt را خودکار مدیریت می‌کند
- ✅ **Bind داخلی**: پنل فقط از `127.0.0.1:5000` در دسترسه (از بیرون فقط از طریق HTTPS در Caddy)
- ✅ **`SECRET_KEY` ثابت**: با `openssl rand -hex 32` تولید می‌شه تا نشست‌ها با ری‌استارت از دست نرن
- ✅ **فایل credentials**: با `chmod 0600` محافظت می‌شه
- ✅ **بررسی DNS**: قبل از شروع نصب، تطابق دامنه با IP سرور چک می‌شه (اطلاعاتی، نصب را متوقف نمی‌کند)

---

## 🛠️ دستورات مفید

بعد از نصب، می‌تونی از این دستورات استفاده کنی:

```bash
# بررسی وضعیت سرویس‌ها
cd /opt/amnezia-panel && sudo docker compose ps

# مشاهده لاگ پنل
cd /opt/amnezia-panel && sudo docker compose logs --tail=80

# مشاهده لاگ Caddy
sudo journalctl -u caddy --tail=80

# ری‌استارت سرویس‌ها
cd /opt/amnezia-panel && sudo docker compose restart

# توقف سرویس‌ها
cd /opt/amnezia-panel && sudo docker compose down

# مشاهده اطلاعات ورود
sudo cat /opt/amnezia-panel/credentials.txt

# وضعیت فایروال
sudo ufw status numbered

# تست SSL (بعد از اولین درخواست)
curl -I https://panel.yourdomain.com

# بکاپ از داده‌ها
sudo tar czf /root/amnezia-backup-$(date +%F).tar.gz -C /opt/amnezia-panel data
```

---

## 📁 ساختار پروژه

```
/opt/amnezia-panel/
├── docker-compose.yml     # تعریف سرویس پنل
├── credentials.txt        # اطلاعات ورود (محرمانه)
├── data/                  # داده‌های پنل (سرورها، کاربران، توکن‌ها)
│   └── data.json          # فایل اصلی داده‌ها
└── src/                   # (فقط اگر از سورس build شده باشه)
```

### 🔒 داده‌ها کجا ذخیره می‌شن؟

- تمام سرورها، کاربران، اتصال‌ها و توکن‌های API در `data/data.json` ذخیره می‌شن.
- این فایل روی volume کانتینر (`./data:/app/data`) mount شده، پس با حذف و بازسازی کانتینر از دست نمی‌ره.
- **بکاپ‌گیری منظم توصیه می‌شه** (دستور بالا را در cron بذارید).

---

## 🔧 پس از نصب

1. پنل را در مرورگر باز کن: `https://panel.yourdomain.com`
2. با `admin / admin` وارد شو
3. **فوراً از بخش Users پسورد را عوض کن**
4. در بخش **Servers** روی دکمه **Add Server** بزن
5. اطلاعات SSH سرور Amnezia خود را وارد کن (IP، یوزرنیم، پسورد یا کلید خصوصی)
6. صبر کن تا تأیید خودکار سرور انجام بشه — پنل پروتکل‌های نصب‌شده و کاربران موجود را تشخیص می‌ده
7. از همان پنل می‌تونی پروتکل نصب کنی، کاربر اضافه کنی، و اتصال‌ها را مدیریت کنی

---

## ❓ عیب‌یابی

<details>
<summary><b>🔴 صفحه پنل باز نمی‌شه</b></summary>

- مطمئن شو دامنه به IP سرور اشاره می‌کنه:
  ```bash
  dig +short A your-domain.com
  ```
- لاگ Caddy را ببین:
  ```bash
  sudo journalctl -u caddy --tail=80
  ```
- مطمئن شو پورت‌های 80 و 443 از بیرون قابل دسترسن:
  ```bash
  sudo ufw status
  ```

</details>

<details>
<summary><b>🟡 خطای 502 Bad Gateway</b></summary>

- مطمئن شو سرویس پنل در حال اجراست:
  ```bash
  cd /opt/amnezia-panel && sudo docker compose ps
  ```
- اگر تازه راه افتاده، ۳۰ ثانیه صبر کن
- اگر مشکل ادامه داشت:
  ```bash
  cd /opt/amnezia-panel && sudo docker compose logs --tail=80
  ```

</details>

<details>
<summary><b>🟠 SSL دریافت نشد</b></summary>

- مطمئن شو دامنه به IP سرور اشاره می‌کنه
- اگر دامنه در Cloudflare هست، موقتاً پروکسی (ابر نارنجی) را خاموش کن
- مطمئن شو پورت 80 از بیرون قابل دسترسه
- لاگ Caddy:
  ```bash
  sudo journalctl -u caddy -n 100 | grep -i "acme\|certificate"
  ```

</details>

<details>
<summary><b>🟣 مشکل در pull از ghcr.io</b></summary>

اگر سرورت به `ghcr.io` دسترسی نداره (مثلاً از ایران)، اسکریپت خودکار به build از سورس برمی‌گرده:
```
[WARN] ghcr.io pull failed - building from source instead (this may take a few minutes).
```
این حالت ۳ تا ۵ دقیقه بیشتر طول می‌کشه، ولی نتیجه یکی است. مطمئن شو سرورت به `github.com` و `pypi.org` دسترسی داره.

</details>

<details>
<summary><b>🔴 خطای Permission یا Docker</b></summary>

اگر دستور `docker compose` خطای permission داد:
```bash
sudo usermod -aG docker $USER
newgrp docker
```
و یا به جای `docker compose` از `sudo docker compose` استفاده کن.

</details>

<details>
<summary><b>⚫ پنل بالا نمیاد و لاگ خطای پایتون می‌ده</b></summary>

```bash
cd /opt/amnezia-panel && sudo docker compose logs --tail=200
```
خروجی خطا را بگیر و در Issues همین مخزن گزارش بده. به‌طور معمول مشکل از نسخه پکیج یا `SECRET_KEY` است.

</details>

<details>
<summary><b>🟤 ری‌استارت سرور، همه چیز از دست رفت</b></summary>

اگر بعد از ری‌استارت، سرورها یا کاربران پنل خالی شدن، یعنی volume درست mount نشده. چک کن:
```bash
ls -la /opt/amnezia-panel/data/
```
باید فایل `data.json` موجود باشه. اگر نیست، یعنی mount انجام نشده و باید `docker-compose.yml` را دوباره چک کنی.

</details>

---

## 🔄 آپدیت پنل

برای آپدیت به آخرین نسخه:

```bash
cd /opt/amnezia-panel
sudo docker compose pull
sudo docker compose up -d
```

داده‌های شما در `data/` باقی می‌مونن و از دست نمی‌رن.

---

## 🗑️ حذف کامل

اگر خواستی همه چیز را پاک کنی:

```bash
cd /opt/amnezia-panel
sudo docker compose down
sudo rm -rf /opt/amnezia-panel
sudo rm /etc/caddy/Caddyfile
sudo systemctl restart caddy
```

> ⚠️ قبل از حذف، از `data/` بکاپ بگیر. بعد از حذف، داده‌ها قابل بازیابی نیستن.

---

## 📜 مجوز

این پروژه تحت مجوز **GNU General Public License v3.0** منتشر شده است.

پنل اصلی [Amnezia Web Panel](https://github.com/PRVTPRO/Amnezia-Web-Panel) نیز تحت GPL-3.0 منتشر شده و این اسکریپت فقط لایه نصب خودکار برای آن فراهم می‌کند.

---

<div align="center">

### ✦ نویسنده اسکریپت ✦

**forouzanexchange-sys**

<br>

⭐ اگه این پروژه به کارت اومد، یه ستاره بده

</div>
