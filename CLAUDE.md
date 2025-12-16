# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Sawab** is a Ruby on Rails 8.0.3 mutual aid/help exchange platform where users can post requests for help and offer assistance to others. The platform includes a virtual currency system ("sawab" points), real-time messaging, notifications, reviews, badges, and an admin panel for moderation.

Ruby version: 3.4.4
Database: PostgreSQL
Asset pipeline: Propshaft
Frontend: Hotwire (Turbo + Stimulus) + Tailwind CSS
Authentication: Devise (with :confirmable and :trackable modules)
Authorization: Pundit
Real-time: Action Cable

## Core Domain Models & Architecture

### Request-Offer Workflow
The application centers around a request-offer lifecycle:

1. **Request** (app/models/request.rb) - Users create help requests with:
   - Status flow: `open` → `in_progress` → `pending_completion` → `completed`
   - Alternative flows: `disputed`, `cancelled`
   - Associated with Category, User (requester)
   - Location fields: region and city for filtering

2. **Offer** (app/models/offer.rb) - Helpers respond to requests:
   - Status: `pending` → `accepted` or `rejected`
   - When accepted: Request transitions to `in_progress` and all other pending offers are auto-rejected
   - Validation: Users cannot offer help on their own requests

3. **Conversation** (app/models/conversation.rb) - Created when an offer is accepted:
   - Links asker (request creator) and helper (offer creator)
   - Has many Messages for real-time chat via Action Cable
   - Unique per request (one conversation per request)

### User System
**User** model (app/models/user.rb) with roles:
- `user` (default), `admin`, `moderator`
- Helper methods: `admin?`, `moderator?`, `staff?`
- Features: sawab_balance (virtual currency), profile_picture (Active Storage), banned_at/banned_reason, phone
- Has multiple association types: requests, offers, conversations_as_asker, conversations_as_helper, reviews_written, reviews_received, notifications, admin_messages, institutions (through institution_members)
- Devise modules: :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :trackable, :confirmable, :lockable
- Lockable config: 5 max attempts, 1 hour unlock, email unlock link
- Profile picture validation: JPEG/PNG/GIF/WebP only, max 5MB
- Scopes: `admins`, `moderators`, `regular_users`, `staff`, `active`, `inactive`
- Cached counters: `unread_notifications_count`, `unread_admin_messages_count` (with 5-minute TTL)

**User Profile Management** (UsersController):
- `GET /profile/edit` - edit own profile form
- `PATCH /profile` - update profile (username, email, phone, password, avatar)
- `DELETE /profile/avatar` - remove profile picture
- `DELETE /profile` - delete own account (with protection: last admin cannot delete themselves)

### Authorization Pattern
Uses Pundit policies (app/policies/):
- ApplicationPolicy as base
- Specific policies for Request, Offer, Notification, Review, AdminMessage, Message, Institution, InstitutionMember
- Admin namespace uses `Admin::BaseController` with `authorize_admin!` checking `current_user.staff?`

### Notification System
**Notification** model (app/models/notification.rb):
- Polymorphic `notifiable` association (can reference Request, Offer, etc.)
- Fields: recipient, actor, action, read_at
- Real-time delivery via NotificationsChannel (Action Cable)
- Cached unread counts: `User#unread_notifications_count`

### Institution System
**Institution** model (app/models/institution.rb) - Verified organizations that can create requests:
- Types: orphanage, nursing_home, rehabilitation_center, charity, other
- Verification workflow: pending → verified (by admin)
- Fields: name, institution_type, description, region, city, address, phone, email, website, director_name
- Has many requests (institutional requests on behalf of beneficiaries)
- Has many institution_members (users associated with the institution)
- Location display: `full_address` method translates regions via I18n

**InstitutionMember** model (app/models/institution_member.rb) - Join table for User-Institution:
- Roles: `member` (basic), `representative` (can create requests), `admin` (full management)
- Fields: user_id, institution_id, role, position (job title)
- Permission methods: `can_create_requests?`, `can_manage_institution?`
- Scopes: `admins`, `representatives`, `can_create_requests`

**Institution Routes**:
- `GET /institutions` - list verified institutions (public)
- `GET /institutions/:id` - institution profile with requests and members
- `GET /institutions/my_institutions` - current user's institutions
- `POST /institutions` - create institution (becomes admin, pending verification)
- Institution admins notified when new institution is created

**InstitutionMembersController** - Manage institution members (nested under institutions):
- `GET /institutions/:id/institution_members` - list members (admin only)
- `POST /institutions/:id/institution_members` - add member by user_id
- `PATCH /institutions/:id/institution_members/:id` - update member role
- `DELETE /institutions/:id/institution_members/:id` - remove member (cannot remove last admin)

### Additional Features
- **Report** system for content moderation (status: pending → investigating → resolved/dismissed)
  - Polymorphic `reportable` association (Request, Offer, User)
  - Fields: reporter, reported_user, report_type, reason, status, resolver, resolution_note, resolved_at
- **Review** system for rating users after completed requests
- **AdminMessage** for user-admin private messaging (separate from Conversation)
- **Badge** system with UserBadge join table for gamification
- **Leaderboards** based on completed requests/offers

## Model Concerns (app/models/concerns/)

The project uses shared concerns for DRY code:

1. **TimeFilterable** - Time-based filtering and sorting scopes:
   - `created_today`, `created_this_week`, `created_this_month`, `all_time`
   - `by_time_period(period)` - accepts 'today', 'week', 'month', 'all'
   - `recent`, `oldest` - sorting scopes

2. **Statusable** - Status filtering and status method generation:
   - `with_status(status)` scope
   - `status_counts` class method
   - `define_status_methods(statuses)` - generates `status?` methods dynamically

3. **Reportable** - Polymorphic reports association:
   - `has_many :reports, as: :reportable`
   - `reported?`, `reports_count`, `pending_reports_count`, `reported_by?(user)`
   - Used by: Request, Offer, User, Institution

4. **Readable** - Read tracking functionality (for messages/notifications)

5. **StatusDisplayable** - Unified status display methods:
   - `define_status_colors(hash)` - class method to configure status-to-color mapping
   - `status_badge_color` - returns color string for current status (blue, yellow, green, red, etc.)
   - `status_label` - returns I18n-translated status label
   - Used by: Request, Offer

6. **CachedCounter** - DSL for cached association counters:
   - `cached_counter :name, association:, scope:, expires_in:` - defines cached counter
   - Generates: `#{name}_count`, `clear_#{name}_cache`, `#{name}_cache_key` methods
   - Used by: User (for unread_notifications, unread_admin_messages)

## Service Objects (app/services/)

Business logic is extracted into service objects, all inheriting from **ApplicationService** base class.

### ApplicationService Base Class
All services inherit from `ApplicationService` (app/services/application_service.rb) which provides:
- `errors` array for collecting error messages
- `success?` / `failure?` - result checking
- `error_message` - returns first error
- `add_error(message)` / `add_errors(messages)` - error collection
- `with_transaction(&block)` - wraps operations in DB transaction with error handling

### Offers Services
- **Offers::AcceptService** - Handles accepting an offer with transaction:
  - Rejects other pending offers
  - Updates offer and request status
  - Sends notifications outside transaction
- **Offers::CreateService** - Creates new offer with notification
- **Offers::RejectService** - Rejects an offer

### Requests Services
- **Requests::CompleteService** - Completes a request:
  - Locks request for thread safety
  - Increments helper's sawab_balance
  - Awards badges via BadgeService
  - Sends completion notification
- **Requests::CancelService** - Cancels a request
- **Requests::MarkPendingService** - Marks request as pending completion

### Other Services
- **NotificationService** - Centralized notification creation and broadcasting:
  - `notify_offer_accepted`, `notify_offer_rejected`, `notify_new_offer`
  - `notify_new_message`, `notify_request_completed`, `notify_pending_completion`
  - `notify_report_resolved`, `notify_report_dismissed`, `notify_user_warned`
  - `notify_badge_unlocked`, `notify_admin_of_dispute`
- **BadgeService** - Awards badges based on user achievements:
  - Sawab milestones (1, 5, 25)
  - Category expertise badges (5 completions in category)

## Controller Concerns (app/controllers/concerns/)

### Public Controllers
- **Filterable** - Provides filtering and sorting for public controllers:
  - `filter_params` - Extracts and normalizes filter parameters
  - `apply_filters(scope)` - Applies all filters and sorting
  - `apply_sorting(scope, sort_param)` - Handles recent/oldest sorting

### Admin Controllers (app/controllers/concerns/admin/)
- **Admin::Filtering** - Pagination and filtering for admin panel:
  - `paginate(scope, per_page: 20)` - Uses Kaminari pagination
  - `filter_by_status`, `filter_by_category`, `filter_by_search`, `filter_by_role`, `filter_by_user_status`
- **Admin::ResourceLoader** - Resource loading helpers for admin controllers

## Localization

The app supports 3 locales configured in config/application.rb:
- English (`:en`)
- Russian (`:ru` - default)
- Kazakh (`:kk`)

Routes are scoped with `(:locale)` parameter. Set via `before_action :set_locale` in ApplicationController.

### Translation Structure (config/locales/)
Key translation namespaces:
- `requests.flash.*` - Flash messages for request actions (completed, pending, dispute_completed, etc.)
- `offers.flash.*` - Flash messages for offer actions (created, accepted, rejected, etc.)
- `notifications.messages.*` - All notification message templates with interpolation
- `regions.*` - Kazakhstan region names (almaty, astana, west_kazakhstan, etc.)
- `activerecord.errors.messages.*` - Validation error messages (too_short, too_long, blank, etc.)
- `institution_types.*` - Institution type labels

### Translation Patterns
- **Flash messages**: Controllers use `t("controller.flash.action")` pattern
- **Notifications**: `Notification#default_message` uses `I18n.t("notifications.messages.#{action}")` with interpolation for actor_name, title, etc.
- **Region display**: Models use `I18n.t("regions.#{region}", default: region)` for translated region names
- **Location display**: `Request#location_display` and `Institution#full_address` translate regions automatically

## Development Commands

### Setup
```bash
bundle install
bin/rails db:create db:migrate
```

### Running the application
```bash
bin/dev  # Starts Rails server + Tailwind CSS watcher (see Procfile.dev)
```

Or separately:
```bash
bin/rails server
bin/rails tailwindcss:watch
```

### Database
```bash
bin/rails db:migrate              # Run migrations
bin/rails db:rollback             # Rollback last migration
bin/rails db:seed                 # Seed database
bin/rails db:reset                # Drop, create, migrate, seed
bin/rails db:schema:load          # Load schema (faster than migrations)
```

### Testing
```bash
bin/rails test                    # Run all tests
bin/rails test test/models        # Run model tests only
bin/rails test test/controllers   # Run controller tests only
bin/rails test test/models/user_test.rb  # Run specific test file
bin/rails test test/models/user_test.rb:15  # Run test at specific line
```

### Linting
```bash
bin/rubocop                       # Check style with RuboCop (using rubocop-rails-omakase)
bin/rubocop -a                    # Auto-correct style violations
```

### Security
```bash
bin/brakeman                      # Run security scanner
```

### Console
```bash
bin/rails console                 # Open Rails console
```

### Asset Management
Tailwind CSS classes are compiled automatically in development via `bin/rails tailwindcss:watch`. For production:
```bash
bin/rails tailwindcss:build       # Build CSS for production
```

## Important Architectural Patterns

### Scopes for Complex Filtering
Both Request and Offer models use concerns (TimeFilterable, Statusable) and model-specific scopes:
- Time-based filtering: `by_time_period` accepts 'today', 'week', 'month', 'all' (from TimeFilterable)
- Status filtering: `with_status` (from Statusable), plus convenience scopes like `open_requests`, `in_progress`
- Location filtering: `by_region`, `by_city` (case-insensitive)
- Search: `Request.search(query)` - searches title and description
- Composite scope: `filter_by(params)` applies all filters
- Eager loading: `with_associations`, `with_full_associations`

Permission check methods in Request: `editable_by?`, `cancellable_by?`, `can_receive_offers?`, `chat_available_for?`
Permission check methods in Offer: `editable_by?`, `acceptable_by?`, `rejectable_by?`, `can_be_deleted_by?`

### Real-time Features via Action Cable
Three channels:
1. **NotificationsChannel** (app/channels/notifications_channel.rb) - Broadcasts to `notifications:user_#{user.id}`
2. **ConversationChannel** (app/channels/conversation_channel.rb) - Streams from specific conversations
3. Connection authentication in app/channels/application_cable/connection.rb uses encrypted cookies

Mount point: `/cable` (see config/routes.rb:95)

### Admin Panel Architecture
Namespace: `admin/` with separate layout ('admin')
- Base controller: Admin::BaseController with `authorize_admin!` before_action
- Controllers: dashboard, users, requests, offers, reports, categories, badges, admin_messages, user_badges, institutions
- Uses concerns: Admin::Filtering, Admin::ResourceLoader
- Routes use `namespace :admin` block
- Dark mode supported with same localStorage-based persistence as main app

### Multi-database Setup (Production)
Uses separate databases for cache, queue, and cable (Solid Cache/Queue/Cable gems):
- Primary: sawab_production
- Cache: sawab_production_cache
- Queue: sawab_production_queue
- Cable: sawab_production_cable

See config/database.yml:81-98

### Database Constraints & Indexes
**NOT NULL constraints** enforced at database level for critical fields:
- `badges`: name, icon_name
- `categories`: name
- `reviews`: rating
- `offers`: message, status
- `requests`: title, description, status, region, city
- `users`: username, sawab_balance

**UNIQUE constraints**:
- `reviews`: (request_id, reviewer_id, reviewee_id) - prevents duplicate reviews
- `offers`: partial unique (user_id, request_id) WHERE status='pending' - prevents duplicate pending offers
- `users`: LOWER(username) - case-insensitive username uniqueness

**Performance indexes** (composite):
- `offers`: (request_id, created_at), (user_id, status)
- `messages`: (user_id, created_at)
- `conversations`: (asker_id, created_at), (helper_id, created_at)
- `reviews`: (reviewee_id, created_at)
- `notifications`: partial index on unread (recipient_id, created_at) WHERE read_at IS NULL
- `requests`: (user_id, status, created_at)

### Production Configuration
**Database timeouts** (config/database.yml):
- `statement_timeout`: 30 seconds (prevents long-running queries)
- `idle_in_transaction_session_timeout`: 60 seconds (prevents connection leaks)

**Docker HEALTHCHECK** (Dockerfile):
- Endpoint: `/up`
- Interval: 30s, Timeout: 3s, Start period: 10s, Retries: 3

**Caching**:
- Admin dashboard stats cached for 5 minutes
- Request cards use fragment caching with keys: [request, user, category, locale, offers_count]

## Key Files & Locations

- **Routes**: config/routes.rb - note the `scope '(:locale)'` wrapper around most routes
- **Favicon**: public/favicon.svg - SVG favicon linked in both layouts
- **ApplicationController**: app/controllers/application_controller.rb
  - Includes Pundit, authentication, ban checking, locale setting
  - `check_if_banned` before_action signs out banned users
- **User model validations**: username uniqueness (case-insensitive), sawab_balance >= 0
- **Request status validation**: Must be one of: open, in_progress, completed, cancelled, pending_completion, disputed
- **Offer accept logic**: Use `Offers::AcceptService` for full workflow with notifications. Direct `offer.accept!` available for basic functionality
- **Request complete logic**: Use `Requests::CompleteService` for full workflow (sawab increment, badges, notifications)
- **Counter cache**: `requests.offers_count` for efficient offer counting

## Common Workflows

### Adding a new model
1. Generate migration: `bin/rails generate model ModelName field:type`
2. Run migration: `bin/rails db:migrate`
3. Add associations in relevant models
4. Create Pundit policy in app/policies/ if authorization needed
5. Add routes in config/routes.rb
6. Generate controller: `bin/rails generate controller ControllerName`
7. Write tests in test/models/ and test/controllers/

### Adding a scope to Request/Offer
Follow the pattern in app/models/request.rb with clear comment sections and add to `filter_by` scope if it's a filterable parameter. Consider using existing concerns (TimeFilterable, Statusable) if applicable.

### Adding a new service object
1. Create service in `app/services/` (use namespace directories for grouping, e.g., `offers/`, `requests/`)
2. Inherit from `ApplicationService` base class
3. Call `super()` in `initialize` to set up `@errors` array
4. Implement `call` method as main entry point
5. Use `with_transaction { }` for multi-model operations (auto-handles exceptions)
6. Use `add_error(message)` to collect errors
7. Keep notifications outside transaction (non-critical operations)
8. Use `NotificationService` for sending notifications

Example:
```ruby
module MyNamespace
  class MyService < ApplicationService
    def initialize(resource)
      super()
      @resource = resource
    end

    def call
      return add_error(I18n.t("errors.invalid")) unless valid?
      with_transaction { perform_action }
      return false unless success?
      send_notifications
      true
    end
  end
end
```

### Adding real-time features
1. Create channel: `bin/rails generate channel ChannelName`
2. Implement streaming logic in app/channels/
3. Add Stimulus controller for frontend in app/javascript/controllers/
4. Broadcast from model callbacks or controller actions using `ActionCable.server.broadcast`

### Adding translations
1. Add keys to all three locale files: `config/locales/ru.yml`, `en.yml`, `kk.yml`
2. Follow existing namespace structure (e.g., `requests.flash.action_name`)
3. Use interpolation for dynamic values: `%{variable_name}`
4. In controllers: `t("namespace.key")` or `t("namespace.key", variable: value)`
5. In views: `<%= t("namespace.key") %>`
6. In models: `I18n.t("namespace.key")`
7. For regions, use pattern: `I18n.t("regions.#{region}", default: region)`

## Frontend Architecture

### Shared View Partials (app/views/shared/)
Reusable view components:
- **_star_rating.html.erb** - Star rating display (1-5 stars)
  - Locals: `rating` (Integer), `size` (optional: "sm", "md", "lg")
- **_form_errors.html.erb** - Form validation errors display
  - Locals: `resource` (ActiveRecord model with errors), `title` (optional)
- **_empty_state.html.erb** - Empty state placeholder with icon
  - Locals: `icon` (requests/offers/messages/notifications/reviews/badges/users), `title`, `description` (optional), `action_path` (optional), `action_text` (optional)
- **_dark_mode_toggle.html.erb** - Theme toggle button
- **_locale_switcher.html.erb** - Language switcher (EN/RU/KZ)
- **_nav_icons.html.erb** - Header notification bell and admin messages icons with dropdowns

### Stimulus Controllers (app/javascript/controllers/)
- **notifications_controller.js** - Real-time notifications via Action Cable
- **conversation_controller.js** - Real-time chat messaging
- **flash_message_controller.js** - Auto-dismiss flash messages
- **dark_mode_controller.js** - Theme toggle functionality
- **star_rating_controller.js** - Interactive star rating for reviews
- **badge_controller.js** - Badge display interactions
- **admin_sidebar_controller.js** - Admin panel sidebar toggle
- **mobile_menu_controller.js** - Mobile hamburger menu (slide-in drawer)

### Dark Mode Implementation
- Theme preference stored in `localStorage` under "theme" key
- Both layouts (application.html.erb, admin.html.erb) include inline script in `<head>` that applies dark mode before page renders to prevent flash
- Inline scripts use `nonce="<%= content_security_policy_nonce %>"` for CSP compliance
- Dark mode toggle button in header uses `dark_mode_controller.js`
- Tailwind CSS `dark:` variants used throughout for dark mode styling

### Mobile Responsive Design
The application is fully responsive with mobile-first approach using Tailwind CSS breakpoints:
- `sm:` (640px+), `md:` (768px+), `lg:` (1024px+)

**Mobile Navigation** (screens < 768px):
- Hamburger button triggers slide-in drawer from right
- Drawer includes: user info, navigation links, language switcher, sign out
- Controlled by `mobile_menu_controller.js` Stimulus controller
- Overlay backdrop closes menu on click
- Escape key closes menu

**Desktop Navigation** (screens >= 768px):
- Standard horizontal navigation bar
- Notification dropdown positioned absolutely

**Responsive Patterns Used**:
- `hidden md:flex` / `flex md:hidden` - show/hide elements by breakpoint
- `flex-col md:flex-row` - stack on mobile, row on desktop
- `fixed left-4 right-4 md:absolute md:right-0` - full-width dropdowns on mobile

### Pagination
- Uses Kaminari gem for pagination
- Manual pagination HTML implemented in views (no Kaminari theme partials)
- Pattern: Check `@collection.total_pages > 1`, render prev/next links with `first_page?`/`last_page?` checks
- Styled with Tailwind classes for consistent appearance

## Deployment

Kamal is configured for deployment (see .kamal/ directory and Gemfile).

```bash
kamal setup     # Initial setup
kamal deploy    # Deploy application
```

Thruster gem provides HTTP caching and X-Sendfile for production.
