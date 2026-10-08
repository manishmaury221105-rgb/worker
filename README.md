# 👷 Worker Hub — Professional Worker & Attendance Management System

A **simple, professional, and easy-to-use Worker Management Application** built with **Flutter (Mobile & Web)**, **Node.js**, **TypeScript**, **PostgreSQL**, and **Prisma ORM**.

---

## 🌟 Key Features

### 👑 Admin Portal
- **Dashboard & KPIs**: Real-time worker counters, attendance rate %, active tasks, pending approvals summary.
- **Worker Management**: Add, Edit, Search, Filter by Department, Deactivate/Activate workers, View complete history.
- **GPS Attendance Register**: Daily logs, Check-in/out timestamps, working hours, geocoded GPS locations, Manual Attendance adjustments.
- **Task Management**: Create tasks, set priorities (`URGENT`, `HIGH`, `MEDIUM`, `LOW`), assign to workers with due dates & locations, track completion progress.
- **Leave Approvals**: One-click Approve / Reject with custom remarks.
- **Salary & Advances**: Auto-calculate monthly payslips based on attendance, mark paid with payment methods (Bank Transfer, UPI, Cash), approve/reject salary advances.
- **Expense Claims**: Review worker travel, food, material, fuel, tools claims & reimburse.
- **Broadcast Announcements**: Send instant in-app announcements to all or specific department workers.
- **Analytics & Reports**: Visual department distributions, attendance breakdown charts, efficiency metrics.

### 👷 Worker Mobile & Web App
- **One-Tap Quick Login**: Email or Phone number login with demo account presets.
- **GPS Attendance Card**:
  - Live clock and today's status badge (`PRESENT`, `LATE`, `HALF_DAY`, `ON_LEAVE`).
  - Large touch button for GPS Check-in and Check-out.
  - Live running working hours counter.
  - 30-Day Attendance history log.
- **My Tasks**: View assigned tasks, filter by status, one-tap "Mark Complete" with completion notes.
- **Apply for Leave**: Fast leave application with date picker, leave types (Casual, Sick, Emergency), live status tracking.
- **Salary & Payslips**: View base salary, monthly net payslips breakdown, request advance salary.
- **Submit Expenses**: File claims with categories, amounts, receipts, and track approval status.
- **In-App Notifications**: Real-time alerts for check-ins, tasks assigned, leave reviews, and salary disbursements.
- **Worker Profile**: Personal info, emergency contacts, bank details, UPI ID.
- **Bilingual Support**: Instant toggle between **English** and **हिन्दी (Hindi)**.
- **Theme Modes**: Modern **Light Mode** and sleek **Dark Mode**.

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter 3.47+, Dart 3.13+, Provider (State Management), Google Fonts (Inter/Poppins) |
| **Backend** | Node.js (v24), TypeScript, Express.js REST API |
| **Database** | PostgreSQL 15/18 with Prisma ORM |
| **Security** | JWT Authentication, Role-based Access Control (`ADMIN`, `WORKER`), Bcryptjs hashing |
| **Localization** | Built-in Hindi (`hi`) and English (`en`) dictionary & switchers |

---

## 🚀 Quick Start Guide

### 1. Database & Backend Setup

```bash
cd backend

# 1. Initialize local PostgreSQL database
npm run db:init # or ./scripts/setup_postgres.sh

# 2. Push Prisma schema & generate client
npm run db:push

# 3. Seed sample data (Admin + 5 Workers + Tasks + Attendance)
npm run db:seed

# 4. Start Development Server (runs on port 5050)
npm run dev
```

Backend will be active at: `http://localhost:5050`  
Health Check: `http://localhost:5050/api/health`

---

### 2. Frontend Setup (Flutter)

```bash
cd frontend

# 1. Install Flutter dependencies
flutter pub get

# 2. Run on Chrome Web
flutter run -d chrome

# OR run on macOS Desktop
flutter run -d macos

# OR run on Android Emulator
flutter run -d emulator-5554
```

---

## 🔑 Demo Login Accounts

| Role | Email / Phone | Password | Name / Details |
|---|---|---|---|
| 👑 **Admin** | `admin@workerapp.com` / `9876543210` | `admin123` | Rajesh Sharma (Operations Director) |
| 👷 **Worker 1** | `rahul@workerapp.com` / `9876543201` | `worker123` | Rahul Verma (Senior Electrician - Electrical) |
| 👷 **Worker 2** | `amit@workerapp.com` / `9876543202` | `worker123` | Amit Kumar (Site Supervisor - Construction) |
| 🚛 **Worker 3** | `vikram@workerapp.com` / `9876543203` | `worker123` | Vikram Singh (Heavy Driver - Logistics) |
| 🔧 **Worker 4** | `suresh@workerapp.com` / `9876543204` | `worker123` | Suresh Yadav (Lead Plumber - Plumbing) |
| 📋 **Worker 5** | `priya@workerapp.com` / `9876543205` | `worker123` | Priya Kumari (Inspector - Maintenance) |

*(Quick demo buttons are also provided on the login screen for instant 1-click testing!)*

---

## 📡 REST API Documentation

### Auth Endpoints
- `POST /api/auth/login`: Authenticate with email/phone & password -> returns JWT token + user profile.
- `POST /api/auth/register`: Create new user account.
- `GET /api/auth/me`: Get current authenticated user profile & counters.
- `PUT /api/auth/profile`: Update user contact, bank info, UPI ID, avatar.
- `POST /api/auth/change-password`: Change account password.

### Attendance Endpoints
- `POST /api/attendance/check-in`: Record GPS check-in (with lat, lng, address).
- `POST /api/attendance/check-out`: Record GPS check-out & compute total working hours.
- `GET /api/attendance/today`: Fetch today's attendance for current user.
- `GET /api/attendance/my-history`: Fetch 30-day attendance history.
- `GET /api/attendance/all` *(Admin)*: Filter attendance by date, status, department.
- `GET /api/attendance/summary` *(Admin)*: Today's present, late, absent, rate stats.
- `POST /api/attendance/manual` *(Admin)*: Manually create/adjust attendance.

### Task Endpoints
- `GET /api/tasks`: List all tasks (with status/priority filters).
- `GET /api/tasks/my-tasks`: Worker gets their assigned tasks.
- `POST /api/tasks` *(Admin)*: Create and assign task with priority & due date.
- `PATCH /api/tasks/:id/status`: Update task status (`IN_PROGRESS`, `COMPLETED`) + notes.
- `PUT /api/tasks/:id` *(Admin)*: Edit task details.
- `DELETE /api/tasks/:id` *(Admin)*: Remove task.

### Leave Endpoints
- `POST /api/leaves/apply`: Worker submits leave request (dates, type, reason).
- `GET /api/leaves/my-leaves`: Worker gets list of their leave requests.
- `GET /api/leaves/all` *(Admin)*: Admin lists all leave requests.
- `PATCH /api/leaves/:id/review` *(Admin)*: Approve or Reject leave with comment.

### Salary & Advance Endpoints
- `GET /api/salary/my-records`: Worker gets monthly payslips.
- `GET /api/salary/all-records` *(Admin)*: Admin views all payslips.
- `POST /api/salary/generate-payslip` *(Admin)*: Calculate and generate payslip.
- `PATCH /api/salary/records/:id/status` *(Admin)*: Mark payslip as `PAID`.
- `POST /api/salary/advance/request`: Worker requests salary advance.
- `GET /api/salary/advance/my`: Worker views advance requests.
- `GET /api/salary/advance/all` *(Admin)*: Admin views advance requests.
- `PATCH /api/salary/advance/:id/review` *(Admin)*: Approve or reject advance.

### Expense Endpoints
- `POST /api/expenses/submit`: Submit expense with category, amount, description, receipt.
- `GET /api/expenses/my`: Worker gets submitted expenses.
- `GET /api/expenses/all` *(Admin)*: Admin gets all submitted expenses.
- `PATCH /api/expenses/:id/review` *(Admin)*: Approve, reject, or mark reimbursed.

### Notifications & Reports
- `GET /api/notifications/my`: Get notifications list with unread badge count.
- `PATCH /api/notifications/:id/read`: Mark notification as read.
- `PATCH /api/notifications/read-all`: Mark all notifications as read.
- `POST /api/notifications/broadcast` *(Admin)*: Broadcast notification to workers.
- `GET /api/reports/dashboard` *(Admin)*: Get executive KPI stats & metrics.

---

## 🧪 Automated Testing

To run the automated backend test suite:

```bash
cd backend
npx ts-node scripts/test_all_endpoints.ts
```

All 19 end-to-end integration tests run and validate authentication, role permissions, GPS attendance calculation, task workflows, leaves, salary generation, advances, expenses, and announcements!
