# Library Management API

A RESTful, JSON:API-based application for managing a library's books, readers, and borrowing history. Built with Ruby on Rails as a recruitment assignment.

Library staff can register and remove books, check availability, view a book's complete borrowing history, and record loans and returns. Readers receive return reminders three days before the due date and on the due date (previewed locally rather than sent to real email addresses).

## Tech stack

- **Ruby:** 3.4.8
- **Framework:** Ruby on Rails 8.1 (API-only)
- **Database:** PostgreSQL 17
- **Background jobs:** Sidekiq, Redis 7, and Sidekiq-Cron
- **API responses:** JSON:API (`jsonapi-serializer`)
- **Email previews:** Action Mailer and Letter Opener Web
- **Testing and quality:** RSpec, FactoryBot, RuboCop, Brakeman, and Bundler Audit
- **Development environment:** Docker Compose

## Getting started

**Prerequisites:** Docker with Docker Compose.

1. Clone the repository and create your local environment file:

   ```bash
   git clone https://github.com/nika-piotrowska/library_management_api.git
   cd library_management_api
   cp .env.example .env
   ```

2. **Align the database credentials in `.env` before starting.** The sample file currently has `DATABASE_USERNAME=username` but `POSTGRES_USER=user`. These must match; for the provided development values, set:

   ```dotenv
   DATABASE_USERNAME=user
   DATABASE_PASSWORD=password
   POSTGRES_USER=user
   POSTGRES_PASSWORD=password
   ```

   Keep the remaining settings from `.env.example`. The `.env` file is for local development and should not be committed.

3. Build and start the application:

   ```bash
   docker compose up --build
   ```

   Docker Compose starts the Rails API, PostgreSQL, Redis, and Sidekiq. The web container runs `bin/rails db:prepare` automatically.

4. Open the services:

   - **API base URL:** `http://localhost:3000/api/v1`
   - **Email preview:** `http://localhost:3000/letter_opener`

To stop the application, run `docker compose down`. Docker volumes preserve the database and Redis data between runs.

## API endpoints

All API endpoints are under `/api/v1` and use the [JSON:API](https://jsonapi.org/) document format. For requests with a body, send `Content-Type: application/vnd.api+json`. Set `Accept: application/vnd.api+json` when consuming the API.

| Method | Endpoint | Description |
| --- | --- | --- |
| `GET` | `/books` | List non-archived books and their current availability (`available` or `borrowed`). |
| `GET` | `/books/:id` | Get a book, its full borrowing history, and associated reader data. |
| `POST` | `/books` | Create a book. |
| `DELETE` | `/books/:id` | Remove a book, preserving any borrowing history by archiving it. |
| `POST` | `/readers` | Register a reader. |
| `GET` | `/readers/:id` | Get a reader's details. |
| `POST` | `/borrowings` | Borrow an available book for a reader. |
| `POST` | `/borrowings/:id/return` | Return a borrowed book. |

The `:id` parameters refer to database resource IDs returned in JSON:API responses, not the formatted six-digit serial or library card number.

### Example requests

**Create a book**

```bash
curl -X POST http://localhost:3000/api/v1/books \
  -H 'Content-Type: application/vnd.api+json' \
  -H 'Accept: application/vnd.api+json' \
  -d '{
    "data": {
      "type": "books",
      "attributes": {
        "title": "Dune",
        "author": "Frank Herbert"
      }
    }
  }'
```

**Register a reader**

```bash
curl -X POST http://localhost:3000/api/v1/readers \
  -H 'Content-Type: application/vnd.api+json' \
  -H 'Accept: application/vnd.api+json' \
  -d '{
    "data": {
      "type": "readers",
      "attributes": {
        "full_name": "Anna Kowalska",
        "email": "anna@example.com"
      }
    }
  }'
```

**Borrow a book** (replace the sample IDs with IDs returned by the API)

```bash
curl -X POST http://localhost:3000/api/v1/borrowings \
  -H 'Content-Type: application/vnd.api+json' \
  -H 'Accept: application/vnd.api+json' \
  -d '{
    "data": {
      "type": "borrowings",
      "relationships": {
        "book": { "data": { "type": "books", "id": "1" } },
        "reader": { "data": { "type": "readers", "id": "1" } }
      }
    }
  }'
```

**Return a book** (use the borrowing ID, not the book ID)

```bash
curl -X POST http://localhost:3000/api/v1/borrowings/1/return \
  -H 'Accept: application/vnd.api+json'
```

A successful create returns `201 Created`; a successful return returns `200 OK`; deletion returns `204 No Content`. Invalid resources or requests produce JSON:API `errors` objects (for example, `400`, `404`, `409`, or `422`).

### Postman collection

[View the Postman API collection (Google Drive)](https://drive.google.com/drive/folders/1kCaBO059iGJJqTdgprRFD_nG2sJ4b5No?usp=sharing)

## Domain rules and design decisions

- **Identifiers:** Each book receives an automatically generated, unique, six-digit serial number; each reader receives a unique, six-digit library card number. Both are based on PostgreSQL sequences and are validated at the application and database levels. Clients do not supply these numbers through the API.
- **Readers:** Full name and email are required. Email addresses must be valid and unique regardless of case.
- **Borrowing period:** Every loan lasts **30 days** from `borrowed_at`. Borrowing records store `borrowed_at`, `due_at`, and `returned_at` to preserve history.
- **Availability:** Only one active borrowing is allowed per book. The API prevents borrowing an already borrowed or archived book; a partial unique PostgreSQL index also enforces this invariant.
- **Concurrent requests:** Loan creation and returns use database row locks to protect status changes against concurrent requests.
- **Book removal:** Books with no borrowing records are deleted permanently. Books with borrowing history are archived instead, preserving the existing records and reader associations. Archived books are excluded from the book list but can still be retrieved individually.
- **Status:** Book responses expose `available`, `borrowed`, or `archived`; borrowing responses expose `active`, `overdue`, or `returned`.
- **API structure:** Versioned controllers handle HTTP concerns, services encapsulate borrow/return operations, and serializers produce JSON:API resources and relationships. Authentication is intentionally omitted as permitted by the assignment.

## Borrowing reminders

`BorrowingRemindersJob` runs according to `config/schedule.yml` via Sidekiq-Cron, **daily at 09:00 Europe/Warsaw time**, while Sidekiq is running. It processes active borrowings and generates two emails:

1. **Three days before** the due date.
2. **On** the due date.

The job skips returned books and uses separate reminder timestamps to avoid resending an already recorded reminder. Reminders are not backfilled for overdue loans.

In development, messages are available through [Letter Opener Web](http://localhost:3000/letter_opener); no external email service is required. To run the reminder job manually for eligible records:

```bash
docker compose exec web bin/rails runner 'BorrowingRemindersJob.perform_now'
```

The manual invocation uses the same eligibility rules, so it only generates previews when active loans are due today or in three days.

## Tests and code quality

Prepare the test database and run the RSpec suite:

```bash
docker compose exec -e RAILS_ENV=test web bin/rails db:prepare
docker compose exec -e RAILS_ENV=test web bundle exec rspec
```

Run the code quality and security checks:

```bash
docker compose exec web bin/rubocop
docker compose exec web bin/brakeman --no-pager
docker compose exec web bin/bundler-audit
```

Specs cover models, API requests, borrowing rules, the reminder job, and mailer content. The current GitHub Actions workflow runs lint and security checks; the RSpec suite can be run with the commands above.

## Scope and possible improvements

This project intentionally focuses on the recruitment requirements. Production SMTP delivery and staff authentication/authorization are not configured. Natural next steps would include pagination and search for book listings, additional observability around reminder processing, and executing the RSpec suite in GitHub Actions.
