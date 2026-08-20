# Project Name

> Briefly describe the project here in one or two sentences.

## 1. Project Vision & Scope
- **Vision:** What is the ultimate goal of this project?
- **Target Audience:** Who is this for?
- **Core Problem:** What specific problem are we solving?
- **Key Constraints:** (e.g., hard deadlines, specific compliance requirements, budget)

## 2. Tech Stack

### Base Stack
The project follows the ecosystem's opinionated full-stack architecture:
- **Frontend:** Nuxt 4, Vue 3 (Composition API), TailwindCSS v4
- **Backend:** Laravel 13, PHP 8.3
- **Database:** PostgreSQL 16, Redis (Caching, Sessions, Queues)
- **AI / LLMs:** Laravel AI (`laravel/ai`)
- **Quality & Testing:** Pest (Backend), Vitest (Frontend), Playwright (E2E), Larastan L9, Laravel Pint, ESLint

### On-Demand Ecosystem Tools
*If the project requires these specific features, strictly use the following packages:*
- **Admin Panels / Backoffice:** `filament/filament`
- **API Authentication:** `laravel/sanctum`
- **Transactional Email:** `symfony/postmark-mailer`
- **Cloud Storage (S3 / R2):** `league/flysystem-aws-s3-v3`
- **Monitoring & App Health:** `laravel/pulse` & `sentry/sentry-laravel`
- **Feature Flags:** `laravel/pennant`
- **Search Engine:** `laravel/scout`
- **Background Workers:** `laravel/horizon`
- **File & Media Management:** `spatie/laravel-medialibrary`

## 3. Infrastructure & Services
| Service | Environment | Internal Port | External Port | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **App (Laravel)** | Docker / Sail | 80 | 8000 | Main API & backend |
| **Frontend (Nuxt)** | Node / Vite | 3000 | 3000 | SSR / Dev Server |
| **PostgreSQL** | Docker / Sail | 5432 | 5432 | Main Database |
| **Redis** | Docker / Sail | 6379 | 6379 | Cache, Queue, Session |
| **Mailpit** | Docker / Sail | 8025 | 8025 | Local mail catching |

- **Hosting / Compute:** (e.g., AWS EC2, Vercel, Laravel Forge)
- **CI/CD:** (e.g., GitHub Actions pipeline)

## 4. Design System
> [!NOTE]
> All visual tokens, typography, component behaviors, and layout constraints are strictly documented in [`DESIGN.md`](./DESIGN.md). Always refer to `DESIGN.md` before building UI components.

## 5. Environment Variables (Template)
*List required environment variables and their purpose, but NEVER include actual secrets.*
```env
APP_ENV=local
DB_CONNECTION=pgsql
# Add project-specific ENV keys here...
```

## 6. Quick Start
*Commands to spin up the project locally.*
```bash
# Clone the repository
git clone <repo-url>

# Install backend dependencies & boot services
composer install
./vendor/bin/sail up -d

# Install frontend dependencies & run dev server
npm install
npm run dev
```
