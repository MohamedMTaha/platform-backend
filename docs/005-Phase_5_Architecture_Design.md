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

| Module            | Responsibility                                                         |
| ----------------- | ---------------------------------------------------------------------- |
| Identity & Access | Authentication, user accounts, roles, and account status               |
| Course Catalog    | Educational stages, courses, lectures, Learning Items, and course publishing  |
| Payments          | Payment attempts, payment provider integration, and webhook processing |
| Enrollments       | Student enrollment and enrollment-related business rules               |
| Learning          | Learning access, lesson progress, and completion                       |
| Assessment        | Exams, questions, attempts, assignments, submissions, and grading      |
| Audit             | Required business audit records                                        |

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

### 5.1 Authentication

The application will use:

- Access Tokens.
- Refresh Tokens.

Access Tokens will be short-lived.

Refresh Tokens will allow users to obtain new Access Tokens without repeatedly logging in.

The following details will be finalized during Authentication implementation:

- Token expiration values.
- Refresh Token storage.
- Token rotation.
- Token revocation.
- Logout behavior.

### 5.2 Account Status Validation

The application must not rely on JWT validity alone to determine whether an account is allowed to access protected resources.

The current account status will be checked against PostgreSQL on protected requests.

Examples:

- A banned student must lose access even if their Access Token has not expired.
- A deactivated assistant must not be allowed to perform new actions.

This introduces an additional database lookup, but provides more reliable account-status enforcement.

This approach can be reconsidered later if measured performance requirements justify a different design.

### 5.3 Authorization

Authorization will use two levels.

**Level 1: Express middleware**

Express middleware will handle:

- Authentication/token verification.
- Coarse role-based access checks.

The main roles are:

- ADMIN
- ASSISTANT
- STUDENT

**Level 2: Service-Level Authorization**

Services will handle contextual and resource-level authorization.

Examples:

- Checking whether a student is enrolled in a course.
- Checking whether a user is allowed to access a lesson.
- Checking whether an assistant can perform an operation under the current account state.
- Checking resource ownership and business conditions.

This separation helps prevent IDOR/BOLA vulnerabilities.

A valid role does not automatically mean permission to access every resource.

### 5.4 Course Access

Course access decisions belong to the relevant business services.

If the same access rules are repeated across multiple modules, a small shared access service may be introduced.

Do not move all resource authorization into Guards.

### 5.5 Password Reset

The exact password-reset flow will be designed during Authentication implementation.

It must include:

- Secure, short-lived reset tokens.
- Single-use tokens.
- Protection against account enumeration.

---

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

| Item                                        | Decision                                       |
| ------------------------------------------- | ---------------------------------------------- |
| Redis                                       | Deferred until a real use case exists          |
| General Background Jobs / Workers            | Deferred; a lightweight processor is required only for storage-cleanup outbox tasks |
| WebSockets                                  | Not included initially                         |
| Microservices                               | Not included                                   |
| Docker                                      | Not used initially                             |
| Operational Logging                         | Explicitly excluded from current scope         |
| Multi-tenancy                               | Deferred                                       |
| Wallet                                      | Not included in the current payment design     |
| Certificates                                | Deferred                                       |
| Notifications                               | Deferred                                       |
| Course-specific assistant permission matrix | Not included initially                         |

The project should remain focused on its actual business requirements.

Technologies should solve real problems rather than being added only to increase the size of the technology stack.

---

## 14. Architecture Risks and Guardrails

| Risk                                      | Architectural Guardrail                                  |
| ----------------------------------------- | -------------------------------------------------------- |
| Business logic leaking into Controllers   | Keep business rules in Services                          |
| Modules becoming tightly coupled          | Communicate through module services/interfaces           |
| Unauthorized resource access              | Perform resource-level authorization in Services         |
| Invalid account retaining access          | Check current account status in PostgreSQL               |
| Duplicate payment processing              | Webhook idempotency and safe state transitions           |
| Inconsistent payment and enrollment data  | Use a shared PostgreSQL transaction through one `pg` client |
| Missing required audit records            | Insert audit records atomically with business operations |
| Concurrent requests causing invalid state | Use constraints, transactions, and atomic operations     |
| Storage provider lock-in                  | Keep a small storage abstraction                         |
| Unnecessary infrastructure complexity     | Introduce technologies only when justified               |

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
