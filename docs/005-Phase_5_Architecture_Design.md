# Phase 5 – Architecture Design

## 1. Purpose and Scope

This document defines the high-level architecture of the Learning Management System (LMS).

The goal of this phase is to establish the architectural boundaries, responsibilities, and technical decisions that will guide implementation.

This phase focuses on:

- Architectural style and module boundaries.
- Authentication and authorization strategy.
- Database access and transaction management.
- Cross-module communication.
- File storage strategy.
- Validation and error handling.
- Configuration and secrets management.
- Testing strategy.
- Local development setup.

Feature-specific implementation details will be decided during the implementation of each feature.

---

## 2. Technology Stack

| Component         | Technology         |
| ----------------- | ------------------ |
| Backend Runtime   | Node.js            |
| Backend Language  | TypeScript         |
| Backend Framework | Express.js         |
| Database          | PostgreSQL         |
| Database Driver   | pg (node-postgres) |
| Frontend          | React              |
| Frontend Language | TypeScript         |
| Architecture      | Modular Monolith   |

The backend and frontend will be maintained in separate GitHub repositories.

### Database Access

The backend uses `pg` (node-postgres) with parameterized Raw SQL. No ORM (Prisma or otherwise) is part of the current stack.

Repositories own SQL queries and database access. PostgreSQL constraints, indexes, and transactions remain first-class parts of the design; application validation does not replace database integrity.

---

## 3. Architectural Style

### 3.1 Modular Monolith

The application will follow a Modular Monolith architecture.

The backend will be deployed as one application, but internally organized into independent business modules.

Each module will own its relevant business responsibilities and expose operations needed by other modules through clear interfaces.

### Why Modular Monolith?

- Simpler deployment and development than microservices.
- Clear separation of business domains.
- Easier transaction management within one application and database.
- Less infrastructure and operational complexity.
- Allows future extraction of modules if a real need emerges.

Microservices are not part of the current architecture.

### 3.2 Module Structure

The proposed modules are:

| Module            | Responsibility                                                               |
| ----------------- | ---------------------------------------------------------------------------- |
| Identity & Access | Authentication, user accounts, roles, and account status                     |
| Course Catalog    | Educational stages, courses, lectures, Learning Items, and course publishing |
| Payments          | Payment attempts, payment provider integration, and webhook processing       |
| Enrollments       | Student enrollment and enrollment-related business rules                     |
| Learning          | Learning access, lesson progress, and completion                             |
| Assessment        | Exams, questions, attempts, assignments, submissions, and grading            |
| Audit             | Required business audit records                                              |

These boundaries represent the current logical design. They can be adjusted if implementation reveals a genuine domain-boundary problem.

### 3.3 Module Internal Structure

Use the following structure where it provides value:

**Controller / Handler → Service → Repository**

- **Controller:** Handles HTTP requests, extracts input, and returns responses.
- **Service:** Owns business logic and coordinates operations.
- **Repository:** Handles database access.

Not every operation needs all three layers.

Avoid introducing unnecessary abstractions or layers for simple operations.

### 3.4 Cross-Module Communication

Modules should communicate through their public services or clearly defined interfaces.

A module should not directly manipulate another module's internal implementation or database access logic.

For example:

- Payments coordinates successful payment processing.
- Enrollments owns enrollment creation rules.
- Learning handles learning access and progress.
- Assessment owns exam and assignment rules.

---

## 4. Shared Infrastructure

Shared infrastructure should start simple.

Common functionality may be shared when there is a real need, such as:

- Database client.
- Configuration.
- Authentication utilities.
- Common error handling.
- File storage interface.

Do not create a large shared infrastructure layer in advance.

Split or extend shared components when repeated needs or clear architectural benefits emerge.

---

## 5. Authentication and Authorization

### 5.1 Authentication Model

The application uses short-lived JWT Access Tokens and opaque Refresh Tokens.

| Concern                      | Decision                                                    |
| ---------------------------- | ----------------------------------------------------------- |
| Access token                 | Signed JWT                                                  |
| Access token lifetime        | 15 minutes                                                  |
| Refresh token                | Cryptographically random opaque token                       |
| Refresh token lifetime       | 7 days, absolute from session creation                      |
| Refresh token storage        | Hash only; never persist the raw token                      |
| Refresh token rotation       | Rotate after every successful refresh                       |
| Active sessions              | One active session per user account                         |
| New login                    | Revoke the existing session and create a new one            |
| Access token client storage  | In-memory on the frontend                                   |
| Refresh token client storage | HttpOnly, Secure cookie with an appropriate SameSite policy |

The Access Token contains only the claims needed by the backend, including:

- `sub`: user ID.
- `role`: current role at token issuance (authorization still checks current account state and applicable permissions).
- `sid`: session ID.
- `iat` and `exp`: issued-at and expiration timestamps.

Do not include passwords, national IDs, phone numbers, or other unnecessary personal data in JWT claims.

### 5.2 Session Management

A user may have at most one active session at a time.

When a user successfully logs in from another device/browser:

1. Revoke the user's previous active session, if one exists.
2. Create a new session.
3. Issue a new Access Token and Refresh Token for the new session.
4. The previous device is no longer authorized, even if its Access Token has not reached its `exp` time.

The database must enforce the one-active-session invariant, and the login operation must use a transaction and appropriate row-level locking to serialize concurrent login attempts for the same user.

A session has an absolute seven-day expiry. Refreshing tokens does not extend the session's absolute expiry. After expiry, the user must log in again.

### 5.3 Refresh Token Rotation (Single-Hash Strategy)

Each session stores only the hash of its **currently valid** Refresh Token. The database does not retain consumed-token history, and the application does not attempt to detect reuse of an old token.

On every successful refresh:

1. Hash the presented opaque token using SHA-256.
2. Find and lock the session row matching that hash.
3. Verify that the session is not revoked and has not expired.
4. Generate a new cryptographically random Refresh Token.
5. Replace `refresh_token_hash` with the hash of the new token and update `last_used_at`.
6. Commit the transaction, then return the new raw token to the client in the HttpOnly cookie.

After rotation, the previous token no longer matches the stored hash and cannot be used again. If an old token is presented, authentication fails; the system does not identify it as a replay event and does not revoke the session solely for that attempt.

The read/lock/validate/update sequence must run in one database transaction. Concurrent refresh requests using the same token must not both succeed. A request that waits for another refresh to commit will no longer find a row matching the old hash and must fail authentication.

The Refresh Token lifetime is absolute: rotation does not change the session's `expires_at`.

### 5.4 Session Database Schema

The MVP uses **one table only: `user_sessions`**. There is no `refresh_tokens` table and no token-history table.

| Column | PostgreSQL type | Null? | Rules / purpose |
|---|---|---:|---|
| `id` | `UUID` | NO | Primary key; generated by the backend when a session is created. Also used as the JWT `sid` claim. |
| `user_id` | Same type as `users.id` | NO | FK to `users(id)`; identifies the owner. Use the exact existing `users.id` type in the migration. |
| `refresh_token_hash` | `VARCHAR(64)` | NO | SHA-256 hash encoded as 64 lowercase hexadecimal characters; only the current token hash is stored. |
| `expires_at` | `TIMESTAMPTZ` | NO | Absolute session expiry, set to creation time + 7 days and never extended by refresh. |
| `revoked_at` | `TIMESTAMPTZ` | YES | NULL while not revoked; set when logout, replacement login, ban, or assistant deactivation revokes the session. |
| `created_at` | `TIMESTAMPTZ` | NO | Defaults to `CURRENT_TIMESTAMP`. |
| `last_used_at` | `TIMESTAMPTZ` | YES | Updated after each successful refresh; NULL until the first refresh. |

Required database constraints and indexes:

- Primary key on `id`.
- Foreign key `user_id -> users(id)`; do not cascade-delete users because the current product has no account-deletion workflow.
- Unique constraint on `refresh_token_hash`, so one token hash cannot identify multiple sessions.
- Check that `refresh_token_hash` contains exactly 64 lowercase hexadecimal characters.
- Check that `expires_at > created_at`.
- Partial unique index on `user_id WHERE revoked_at IS NULL`, enforcing at most one non-revoked session per user.

The partial unique index intentionally does not consider `expires_at`. Therefore, Login must revoke any existing non-revoked session for that user, including an expired one, before inserting the new session. Protected-request and refresh validation must check both `revoked_at IS NULL` and `expires_at > CURRENT_TIMESTAMP`.

No separate index on `expires_at` is required for the initial MVP. Add one only if session cleanup/operations later demonstrate a query-performance need.

### 5.5 Protected Request Validation

JWT signature and expiry validation are necessary but not sufficient.

For each protected request, the backend must:

1. Verify the Access Token signature, allowed algorithm, and expiry.
2. Read the user ID (`sub`) and session ID (`sid`) from the verified claims.
3. Verify that the referenced session belongs to that user, is not revoked, and has not expired.
4. Verify the current account status from PostgreSQL.
5. Continue to authorization checks only after authentication succeeds.

This makes a previous device's Access Token unusable immediately after its session is revoked, rather than waiting up to 15 minutes for token expiry.

### 5.6 Account Status Enforcement

The application must not rely on JWT validity alone to determine whether an account may access protected resources.

The current account status will be checked against PostgreSQL on protected requests.

Examples:

- A banned student must lose access even if their Access Token has not expired.
- A deactivated assistant must not perform new actions.
- When a banned student is unbanned, the student must log in again; the old session remains revoked.

### 5.7 Logout and Session Revocation

- `Logout`: revoke the current session and clear the Refresh Token cookie.
- `Logout All`: revoke all sessions for the user (retained as an administrative/security operation even though the MVP permits only one active session).
- New login: revoke the previous session before creating the new one.
- Ban/deactivation: revoke the affected user's active session as part of the status-changing operation where applicable.

A revoked session invalidates all Access Tokens carrying its session ID.

### 5.8 Cookie and CSRF Security

The Refresh Token cookie must be `HttpOnly` and `Secure` in production, with a deliberate `SameSite` setting and a narrow path/domain scope where practical.

Because browsers attach cookies automatically, cookie-authenticated endpoints (especially refresh and logout) must have CSRF protection appropriate to the deployment topology. CORS configuration alone is not a CSRF defense. The exact cookie domain, SameSite mode, and CSRF mechanism will be finalized when frontend/backend origins and deployment are configured.

The frontend keeps the Access Token in memory and sends it in the `Authorization: Bearer` header. Do not store the Refresh Token in `localStorage` or expose it to JavaScript.

### 5.9 Password Handling and Login Responses

Passwords must be stored using a suitable password-hashing algorithm (Argon2id preferred; bcrypt is an acceptable alternative when configured appropriately). Never store plaintext passwords or reversible password encryption.

Login failures must not reveal whether a phone number/account exists. Return a generic invalid-credentials response for unknown users and incorrect passwords. Account-state failures must not disclose sensitive internal details.

### 5.10 Authorization

Authorization uses two levels.

**Level 1: HTTP middleware**

Middleware handles:

- Authentication and token/session verification.
- Coarse role-based access checks.

The main roles are:

- `ADMIN`
- `ASSISTANT`
- `STUDENT`

**Level 2: Service-level authorization**

Services handle contextual and resource-level authorization, including:

- Checking whether a student is enrolled in a course.
- Checking whether a user may access a lesson.
- Checking whether an assistant may perform an operation under the current account state.
- Checking resource ownership and business conditions.

A valid role does not automatically grant access to every resource. This separation helps prevent IDOR/BOLA vulnerabilities.

### 5.11 Deferred Authentication Details

The following are implementation/API-level details, not reasons to delay the core design:

- Exact response/error contract and endpoint payloads.
- Cookie domain, path, SameSite mode, and CSRF mechanism based on deployment origins.
- Password reset flow and its token lifecycle.
- Rate limits and operational thresholds for login/refresh attempts.
- Device metadata collection, if a real product requirement emerges. Device fingerprinting is not part of the MVP.

The single-session rule prevents simultaneous sessions, but cannot prevent a student from sharing credentials and taking turns using the account. Additional abuse detection is deferred unless product evidence justifies it.

## 6. Database Access, Transactions, and Consistency

### 6.1 Database Access

The `pg` Pool from node-postgres will be the database access layer. Repositories use parameterized SQL; no ORM is used.

Database integrity must still be enforced through PostgreSQL where appropriate:

- Foreign keys.
- Unique constraints.
- Check constraints.
- Indexes.
- Transactions.

Business rules should not depend exclusively on application-level validation when a database constraint can protect the data against concurrent or unexpected operations.

### 6.2 Transactions

Transactions will be used when multiple database operations must succeed or fail together.

Examples include:

- Successful payment processing and enrollment creation.
- Updating business state and inserting its required audit record.
- Operations that modify multiple related records.

Transactions should be kept short.

Do not perform external HTTP requests, payment-provider calls, or email delivery inside a database transaction.

External systems cannot be rolled back by a PostgreSQL transaction.

### 6.3 Cross-Module Transaction Example: Payments and Enrollments

A successful payment may require:

1. Validating the payment attempt.
2. Verifying the payment information.
3. Updating the payment attempt state.
4. Creating the student's enrollment.
5. Inserting required audit records.

The database changes that must remain consistent will execute within the same PostgreSQL transaction, using a checked-out `pg` client.

Responsibilities:

- **PaymentsService:** Orchestrates payment processing.
- **EnrollmentsService:** Owns enrollment business rules and creation.

The checked-out `pg` client (transaction context) will be passed to the required repository operations so that all related SQL statements participate in the same transaction.

If a required operation fails, the transaction must roll back.

The payment provider's external transaction is separate and cannot be rolled back by this database transaction.

### 6.4 Concurrency

Important operations must be designed to handle concurrent requests.

The application will use appropriate combinations of:

- Database constraints.
- Transactions.
- Atomic updates.
- Row-level locking when necessary.

Examples include:

- Preventing duplicate active enrollments.
- Handling multiple webhook deliveries.
- Preventing conflicting state transitions.
- Maintaining consistent payment and enrollment data.

The exact mechanism will depend on the specific operation.

---

## 7. Audit Records

Audit records are part of the business requirements.

Required audit records must be written to the database as part of the same transaction as their corresponding business operation.

For example:

If an operation changes an important business state, its required audit record must be committed with that state change.

If inserting a required audit record fails, the corresponding business transaction must roll back.

Audit records are append-only.

They must not be casually updated or deleted through normal application operations.

### Important Distinction

Audit records are included in the project.

Operational logging is explicitly excluded from the current project scope.

---

## 8. File and Video Storage

### 8.1 File Storage

Files such as student identity images must be stored in private object storage.

The backend is responsible for authorization before allowing access to private files.

Signed URLs may be used when appropriate.

The application should not expose private files through unrestricted public URLs.

### 8.2 Storage Abstraction

A simple storage interface will separate business logic from the storage provider.

This makes it possible to change the storage provider without spreading provider-specific logic throughout the business modules.

The abstraction should remain small and should only expose operations the application actually needs.

### 8.3 Video/File Deletion

Video and File Learning Items may be hard-deleted only after prerequisite dependents are removed. Their progress rows, detail records, Learning Item row, and a storage-cleanup outbox record are handled in one PostgreSQL transaction. The outbox record preserves the storage provider/key after the Learning Item metadata is deleted.

A lightweight cleanup processor handles pending outbox records, deletes the physical object, and marks the task complete. Failures remain retryable. This does not require a third-party queue service; a simple database-backed processor is sufficient initially.

Assignment and Exam Learning Items are immutable and cannot be deleted.

### 8.4 Video Delivery

Video security is an important product requirement.

The architecture will allow video delivery to be handled separately from ordinary application data.

However, the following decisions are deferred until the video feature is implemented:

- Video hosting provider.
- Delivery mechanism.
- Access-token or signed-URL strategy.
- Available protection mechanisms.

No implementation should claim that a video can be made completely impossible to record or copy.

The objective is to control authorized access and apply reasonable protection mechanisms.

---

## 9. Validation and Error Handling

### 9.1 Request Validation

Request validation will use an explicit validation library/schema at the Express boundary. The exact library can be selected during implementation; validation middleware will validate shape/types/formats before controllers call services.

Examples include:

- Required fields.
- Data types.
- String lengths.
- Valid formats.
- Allowed input values.

### 9.2 Business Validation

Business rules belong in Services.

A request can pass DTO validation and still violate a business rule.

For example:

- A student may provide a valid course ID but may not be eligible to enroll.
- An assistant may provide valid input but may not be allowed to perform the operation because their account is deactivated.

### 9.3 Error Handling

The application will use centralized exception handling.

Controllers should not duplicate error-response formatting.

Errors should be represented consistently without exposing sensitive internal implementation details.

---

## 10. Configuration and Secrets Management

Environment variables will be used for environment-specific configuration and secrets.

The application should validate required configuration during startup.

An `.env.example` file will document the required environment variables without containing actual secrets.

The real `.env` file must not be committed to Git.

Examples of configuration include:

- Database connection string.
- JWT secrets.
- Payment provider credentials.
- Storage provider credentials.
- Other environment-specific settings.

---

## 11. Testing Strategy

Testing will focus on important business behavior rather than achieving an arbitrary coverage percentage.

### 11.1 Unit Tests

Unit tests will focus on business logic.

Examples:

- Enrollment eligibility.
- Course access rules.
- Exam passing conditions.
- Assignment submission rules.
- Account status restrictions.

### 11.2 Integration Tests

Integration tests will verify interactions with PostgreSQL and important database behavior.

Examples:

- Transaction rollback.
- Unique constraints.
- Enrollment creation.
- Payment state transitions.
- Audit record consistency.

### 11.3 Authentication and Authorization Tests

Tests must cover:

- Unauthenticated requests.
- Role restrictions.
- Banned or deactivated accounts.
- Resource ownership.
- Student enrollment access.
- Unauthorized access to other users' resources.

### 11.4 Failure and Retry Scenarios

Important flows must also be tested under failure conditions.

Examples:

- Duplicate webhook delivery.
- Payment processing failure.
- Database transaction failure.
- Required audit insertion failure.
- Concurrent requests attempting the same operation.

Testing will be introduced alongside feature implementation.

---

## 12. Local Development Setup

The initial development environment will use:

- Node.js.
- PostgreSQL installed and running locally.
- `pg` (node-postgres) with parameterized Raw SQL.
- Express.js.
- React and TypeScript.

Docker will not be used initially.

PostgreSQL will be installed and configured directly on the development machine.

The setup instructions will be documented so the environment can be reproduced.

Docker can be reconsidered later if a real development or deployment need appears.

---

## 13. Deferred Decisions and Explicit Non-Goals

The following technologies or features will not be introduced without a real requirement.

| Item                                        | Decision                                                                            |
| ------------------------------------------- | ----------------------------------------------------------------------------------- |
| Redis                                       | Deferred until a real use case exists                                               |
| General Background Jobs / Workers           | Deferred; a lightweight processor is required only for storage-cleanup outbox tasks |
| WebSockets                                  | Not included initially                                                              |
| Microservices                               | Not included                                                                        |
| Docker                                      | Not used initially                                                                  |
| Operational Logging                         | Explicitly excluded from current scope                                              |
| Multi-tenancy                               | Deferred                                                                            |
| Wallet                                      | Not included in the current payment design                                          |
| Certificates                                | Deferred                                                                            |
| Notifications                               | Deferred                                                                            |
| Course-specific assistant permission matrix | Not included initially                                                              |

The project should remain focused on its actual business requirements.

Technologies should solve real problems rather than being added only to increase the size of the technology stack.

---

## 14. Architecture Risks and Guardrails

| Risk                                      | Architectural Guardrail                                     |
| ----------------------------------------- | ----------------------------------------------------------- |
| Business logic leaking into Controllers   | Keep business rules in Services                             |
| Modules becoming tightly coupled          | Communicate through module services/interfaces              |
| Unauthorized resource access              | Perform resource-level authorization in Services            |
| Invalid account retaining access          | Check current account status in PostgreSQL                  |
| Duplicate payment processing              | Webhook idempotency and safe state transitions              |
| Inconsistent payment and enrollment data  | Use a shared PostgreSQL transaction through one `pg` client |
| Missing required audit records            | Insert audit records atomically with business operations    |
| Concurrent requests causing invalid state | Use constraints, transactions, and atomic operations        |
| Storage provider lock-in                  | Keep a small storage abstraction                            |
| Unnecessary infrastructure complexity     | Introduce technologies only when justified                  |

---

## 15. Phase 5 Exit Criteria

Phase 5 is considered complete when:

- The architectural style is agreed upon.
- Module boundaries and responsibilities are defined.
- Authentication and authorization responsibilities are clear.
- Database access and transaction strategy are defined.
- Cross-module transaction ownership is understood.
- Audit record consistency requirements are defined.
- File storage direction is established.
- Validation and error handling strategy is established.
- Configuration and secrets approach is established.
- Testing strategy is established.
- Deferred technologies and non-goals are documented.

**Status: READY TO CLOSE**, subject to a final consistency review against the previous phases.

---

## Next Phase: Implementation

Implementation will proceed feature by feature.

For each feature, we will:

1. Review its requirements and business rules.
2. Identify edge cases and failure scenarios.
3. Design its API.
4. Implement the required backend behavior.
5. Implement database interactions and transactions.
6. Write meaningful tests.
7. Review the implementation and its tradeoffs.

Architecture decisions may be revisited when implementation reveals a genuine issue, but changes must be intentional and documented.
