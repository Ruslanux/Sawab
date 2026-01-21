# Sawab

Mutual aid platform connecting people for good deeds. Users can create help requests and offer support to others.

**Live:** [sawabapp.org](https://sawabapp.org)

## About

**Sawab** (Arabic: "good deed") is a web application for organizing mutual assistance. The platform allows:

- Creating help requests with detailed descriptions
- Offering help to other users
- Real-time communication via built-in chat
- Earning virtual points (Sawab) for provided assistance
- Leaving reviews and ratings
- Earning achievement badges

### Key Features

- **Institutional Requests** — Verified organizations (orphanages, nursing homes, charitable foundations) can create requests on behalf of their beneficiaries
- **Moderation System** — Reports, warnings, and bans to maintain community quality
- **Multi-language** — Support for Russian, Kazakh, and English
- **Geolocation** — Filter requests by regions of Kazakhstan

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Backend** | Ruby 3.4.4, Rails 8.0.3 |
| **Database** | PostgreSQL 14+ |
| **Frontend** | Hotwire (Turbo + Stimulus), Tailwind CSS |
| **Real-time** | Action Cable (WebSocket) |
| **Authentication** | Devise |
| **Authorization** | Pundit |
| **Pagination** | Kaminari |
| **Code Quality** | RuboCop, Brakeman |
| **Deployment** | Kamal 2.x, Docker |

## Project Structure

```
app/
├── channels/          # Action Cable channels (chat, notifications)
├── controllers/
│   ├── admin/         # Admin panel
│   └── concerns/      # Shared modules (Filterable, Admin::Filtering)
├── models/
│   └── concerns/      # Shared modules (TimeFilterable, Statusable, Reportable)
├── policies/          # Pundit authorization policies
├── services/          # Service objects (Offers::*, Requests::*, NotificationService)
├── views/
│   ├── layouts/       # application, admin
│   └── shared/        # Reusable components
└── javascript/
    └── controllers/   # Stimulus controllers

config/
├── locales/           # Translations (ru.yml, en.yml, kk.yml)
└── routes.rb          # Routes with locale scope
```

## Core Entities

### User
- Roles: `user`, `moderator`, `admin`
- Sawab balance (virtual currency)
- Achievement badges

### Request
- Statuses: `open` → `in_progress` → `pending_completion` → `completed`
- Alternative: `disputed`, `cancelled`
- Linked to category and location

### Offer
- Statuses: `pending` → `accepted` / `rejected`
- On acceptance, creates a Conversation for chat

### Institution
- Types: orphanage, nursing home, rehabilitation center, charitable foundation
- Requires admin verification

## Setup

### Requirements

- Ruby 3.4.4
- PostgreSQL 14+
- Node.js 18+
- Bundler

### Installation

```bash
# Clone repository
git clone https://github.com/Ruslanux/sawab.git
cd sawab

# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate db:seed

# Start server
bin/dev
```

### Environment Variables

```bash
# .env (development)
DATABASE_URL=postgresql://user:password@localhost/sawab_development
DEVISE_SECRET_KEY=your-secret-key

# Production
REDIS_URL=redis://localhost:6379/1
```

## Development

```bash
# Start development server (Rails + Tailwind watcher)
bin/dev

# Or separately
bin/rails server
bin/rails tailwindcss:watch

# Rails console
bin/rails console
```

## Testing

```bash
bin/rails test                    # All tests
bin/rails test test/models        # Model tests
bin/rails test test/controllers   # Controller tests
```

## Code Quality

```bash
bin/rubocop        # Style check
bin/rubocop -a     # Auto-fix
bin/brakeman       # Security analysis
```

## Admin Panel

Available at `/admin` for users with `admin` or `moderator` roles.

Features:
- User management (ban, roles)
- Request and offer moderation
- Report handling
- Institution verification
- Category and badge management
- Statistics dashboard

## Localization

The application supports three languages:
- Russian (`ru`) — default
- Kazakh (`kk`)
- English (`en`)

Language is selected via URL: `/ru/requests`, `/kk/requests`, `/en/requests`

## Deployment

Deployed with [Kamal](https://kamal-deploy.org/):

```bash
kamal setup    # Initial setup
kamal deploy   # Deploy
```

### Production Database

Multi-database setup in production:
- `sawab_production` — main database
- `sawab_production_cache` — Solid Cache
- `sawab_production_queue` — Solid Queue
- `sawab_production_cable` — Solid Cable

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

MIT License. See [LICENSE](LICENSE) for details.

---

Built with Ruby on Rails by [Ruslan Zhubanov](https://github.com/Ruslanux)
