# LMS — Phase 2: Requirements & Use Cases
## Final Document — Phase 2 COMPLETE (Updated by subsequent confirmed decisions)

**Status:** Phase 2 baseline finalized after the 30-question review; updated where later explicit product decisions supersede earlier answers. This document records requirements and behavior, not schema or implementation. Later confirmed decisions in the current decision sections take precedence over historical review answers.

## Current Decisions

### Actors
- Admin: platform owner; full control; manages Assistants and educational stages.
- Assistant: multiple Assistants under the same Admin/platform; same operational permissions; cannot manage Assistants.
- Student: registers, requires manual approval, and accesses courses according to account/enrollment rules.

### Student lifecycle
Statuses: `PENDING`, `APPROVED`, `REJECTED`, `BANNED`.
- PENDING: no normal access; awaiting review.
- APPROVED: full access; student cannot edit registration data directly.
- REJECTED: latest rejection reason shown; student can edit all registration data and resubmit; one registration record; rejection reason mandatory; latest reason only.
- BANNED: no new student operations until explicit unban; an already-started operation may finish; existing enrollments/progress/history remain; unban returns to APPROVED; old JWT remains invalid and student must log in again; banned identity cannot register again.
- Unique student fields: email, phone, National ID.
- Login: phone + password; invalid credentials are generic.
- Registration includes full name, National ID, DOB, address, phone, email, password, guardian phone, educational stage, and private ID-card image.

### Educational stages
- Admin only creates/updates stages; names are unique.
- Stages are archived/soft-deleted, not hard-deleted in normal workflows.
- Students select a stage during registration and cannot change it themselves.
- Admin/Assistant may correct a student's stage when the registration stage was wrong.
- A stage archive prevents discovery and new purchases through that stage; existing active enrollments keep access, progress, and history.
- Restoring a stage makes it available again. Each associated course's own status still applies: PUBLISHED may be visible and DRAFT remains hidden. Courses have no ARCHIVED state.
- A course-stage association may be added while the stage is archived, but it does not make the course discoverable through that archived stage until the stage is restored.
- Removing a course's association with one stage removes discovery/new purchase through that stage but does not revoke existing active enrollments. A course must always have at least one stage association; removing its last association is prohibited.

### Courses
- Courses belong to the Admin/platform and may be associated with multiple educational stages.
- Lifecycle: `DRAFT` / `PUBLISHED`.
- DRAFT is hidden from students; PUBLISHED is visible to matching-stage students.
- Visibility != access.
- Student content access requires APPROVED account + ACTIVE Enrollment.
- Admin/Assistant can access/manage courses without enrollment.
- `PUBLISHED -> DRAFT` is allowed.
- If students have ACTIVE enrollments, they keep access after the course becomes DRAFT; enrollment/progress/history are unchanged.
- Courses cannot be archived, restored, or deleted, regardless of whether they have active enrollments or historical records.
- `PUBLISHED -> DRAFT` hides the course from discovery and new purchases but preserves access, progress, and history for existing ACTIVE Enrollments.
- A course may be published with zero Required Learning Items. If no Required items exist, enrolled students retain access but Course Completion is undefined until at least one Required item exists.
- Course records and their related academic/payment history remain in the system.

### Enrollment and payment
- No wallet.
- Student pays directly for a course.
- Successful payment/confirmation results in ACTIVE Enrollment and access.
- Failed payment gives no access.
- ACTIVE enrollment blocks repurchase.
- Payment provider and provider-specific refund lifecycle are deferred.
- A pending Payment Attempt for the same student/course blocks creating another pending attempt.
- Payment confirmation must be idempotent; verify provider confirmation and match student, course, and amount.
- Successful payment and Enrollment creation/state change must be handled consistently. If the provider reports success but the backend fails transiently, retry/recovery must safely complete the flow without asking the student to pay again.
- At most one ACTIVE Enrollment exists for the same student/course. Even if two distinct successful charges occur, do not create duplicate active enrollments; duplicate-charge/refund handling is provider-dependent and deferred.
- Enrollment is not manually edited; business flows change its state.
- After cancellation, re-enrollment creates a new independent enrollment with progress starting at 0; old enrollment/history remains.

### Cancellation
Statuses: `PENDING`, `APPROVED`, `REJECTED`.
- Student creates a cancellation request; the student cannot directly cancel an Enrollment.
- Student may withdraw/delete their own request only while it is `PENDING`. Withdrawal physically deletes the request record; no `WITHDRAWN` status or history is retained for a student-withdrawn request.
- After deleting a pending request, the student may create a new cancellation request for the same Enrollment.
- Admin/Assistant can approve or reject a pending request.
- Approval is not itself cancellation; refund/cancellation processing follows.
- Direct Assistant cancellation is allowed without a request and requires a mandatory reason.
- At most one pending request per Enrollment.
- After rejection, another request may be created. A deleted pending request also permits a new request.
- After approval, no new request while cancellation is in progress.
- Approval is not actual cancellation. The intended flow is: request APPROVED → refund decision/processing → Enrollment becomes CANCELLED → access is revoked.
- While a request is APPROVED and cancellation is still in progress, new cancellation requests and repurchase remain blocked until the Enrollment is actually CANCELLED.
- An Assistant's direct cancellation takes effect by cancelling the Enrollment/revoking access; a mandatory reason is recorded. Refund handling is separate and provider-dependent, and is deferred.
- If two Assistants act on the same request concurrently, only one valid state transition succeeds; the other must observe the current state rather than overwrite it.

### Learning Items
Types: Video, File, Assignment, Exam.
- Lecture is a container, not a Learning Item.
- Item can be inside a Lecture or directly under Course.
- Location does not affect progress/behavior.
- At most one prerequisite per item.
- Prerequisite must be another item in the same Course.
- Self-prerequisites and cycles are prohibited.
- Prerequisite locks interaction/start but does not hide the item.

### Learning Item creation, immutability, and deletion
**Creation**
- Learning Items may be created even when a course has active students/progress.
- Required items enter current progress/completion requirements for every ACTIVE Enrollment, including students who previously completed the course; this can make the course incomplete again.
- Optional items are excluded from progress and completion requirements and cannot be prerequisites.
- Required/Optional, title, description, position, location, and prerequisite are set at creation. Learning Item configuration is immutable after creation.

**Modification**
- No Learning Item type can be edited after creation.
- This applies to common metadata/configuration and type-specific content. If a correction is needed, create a new Learning Item.
- Assignment and Exam content/settings are immutable immediately after creation, not only after student usage. No Assignment or Exam versioning exists.

**Deletion**
- There is no Learning Item archival or restoration.
- Video and File items may be hard-deleted. Deletion is blocked while another item depends on the target as a prerequisite; remove the prerequisite relationship first.
- When a Video or File is deleted, its associated progress records are deleted. The item is removed from current progress/completion calculations.
- Assignment and Exam items cannot be deleted, preserving their submissions, attempts, and academic history.
- No Learning Item is transferred between courses; create a separate item in the destination course.

### Progress
- System-controlled.
- Video complete at >=80% watched; remains complete.
- Assignment complete when ACCEPTED; ACCEPTED is final.
- Exam complete when final score >=50%; failed exam is not complete.
- Failed attempt consumes an attempt; Admin/Assistant can reset with mandatory reason; old attempt remains and reset creates a new opportunity.
- Progress is `Completed Required Learning Items / Total Required Learning Items`; Optional items are excluded. Locked Required items remain in the denominator. Deleted Video/File items are absent from the current denominator.
- Progress and Course Completion are separate. Course Completion requires all current Required items to be completed.
- When there are zero Required items, Course Completion is undefined (not automatically complete); the course remains accessible to enrolled students. When a Required item is added, current progress and completion are recalculated against the current requirements. Deleted Video/File progress rows are removed rather than retained as historical completion records.
- No certificates currently.

### Assignments
States: `SUBMITTED`, `UNDER_REVIEW`, `ACCEPTED`, `REJECTED`.
- REJECTED requires reason.
- Student may resubmit while under review or after rejection.
- ACCEPTED is final; no resubmission after ACCEPTED.
- Resubmission replaces the current submission; no submission version history is retained.
- Late submissions are allowed and marked by timestamp; late does not automatically reject.
- Admin/Assistant decides accept/reject.
- No grades.

### Exams
- Admin/Assistant manage exams.
- Academic changes include exam questions/options, points, correct answers, passing score, and time limit.
- An Exam and all its settings, questions, options, correct answers, marks, and metadata are immutable immediately after creation.
- No Exam Versioning exists. If there is a mistake, create a new Exam; the original remains.
- One attempt by default.
- Admin/Assistant may reset attempts; reason required and action audited.
- Old attempts remain.
- MCQ/TF auto-graded; Essay manually graded.
- Essay may be GRADING_PENDING until final grading.
- Time limit; server is source of truth; expiry auto-submits.
- Questions/options are randomized; per-attempt display order is not persisted.
- Connection/device failure resumes same attempt; answers persist.
- Unanswered and wrong answers are distinct records but both score 0.
- Passing score: 50%.

### Academic history
Student can view academic records.
Retain exam attempts, current scores, question-level results, and the latest Essay grader/time where applicable. Regrading updates the current result; previous grading results are not retained.
Courses are not deleted or soft-deleted; academic history remains attached to the retained Course and Enrollment records.
Cancellation does not erase academic history/progress/attempts.
Re-enrollment creates new progress while old history remains.
Assignment history retains only the latest submission.
Assignments are immutable immediately after creation, including task/requirements, allowed file types, maximum submission size, due date, late-submission policy, and metadata. No Assignment Versioning exists. If there is a mistake, create a new Assignment; the original remains.

### Assistants
Lifecycle: `ACTIVE` / `DEACTIVATED`.
- Admin only creates/deactivates/reactivates.
- Deactivated Assistant loses permissions; historical data/content/audits remain.
- Reactivation restores permissions.
- Admin cannot deactivate own account.
- Assistant-created content remains.

### Access, bans, and concurrent actions
- A ban prevents new student requests/operations. An operation that already started and passed authorization may finish; a ban does not cancel the Enrollment or erase progress/history.
- A banned student with an ACTIVE Enrollment cannot start a new operation. Existing Enrollment/progress/history remain intact.
- If an Assistant data edit already passed validation/authorization before a concurrent ban, that edit may complete; new requests after the ban takes effect are denied.
- A student whose stage is corrected keeps existing enrollments/access/progress/history. Future discovery and purchases use the corrected stage only.
- A student may continue an existing active Enrollment after the course becomes DRAFT, but cannot discover/purchase that course as a new enrollment.
- Concurrent state changes use guarded transitions: only one valid decision succeeds; no last-write-wins overwrite for cancellation decisions.

### Assistant review reservations
- Review work may be temporarily reserved in a shared pool/batch; reservation is not a lifecycle status.
- Leaving normally releases unprocessed reserved items immediately; expiry is a fallback for crash/disconnect.
- Deactivating an Assistant immediately releases unprocessed reservations. Already completed decisions remain unchanged.

### Security and audit
- Only Assistant actions are audited; Admin actions are not audited under the current scope.
- Audit events include actor, action, target, timestamp, reason, and selective before/after values. Reasons are mandatory for audited sensitive operations, direct Enrollment cancellation, exam-attempt reset, and relevant course/content management operations.
- All Assistant modifications to an APPROVED student's registration/profile fields are audited.
- Audit is append-only; Assistants cannot edit/delete records; only Admin can view them.
- Sensitive before/after values must be selectively masked/redacted. The ID-card image itself is never copied into the Audit Log.
- For required audited operations, the business change and audit event must succeed atomically.
- Audit lists need pagination and backend filtering for actor, action, target type/ID, date range, reason, and relevant domain targets.
- Student ID card remains private; its retention policy is deferred.

### Collections and filtering
- Any API returning a potentially growing collection must support pagination.
- Management lists provide search/filter options where useful.
- Frontend-local filtering is acceptable when the loaded dataset is sufficient; backend search/filter is required when matching the full dataset or other pages is necessary.
- Audit filtering is performed on the backend and supports combined filters.

### Notifications and video protection
- Notifications are fully deferred until the core platform is complete. Phase 2 does not define notification events, schema, delivery, or infrastructure; future architecture should not unnecessarily prevent adding them.
- Only authorized students with an active Enrollment may access course videos. Protection should reduce unauthorized access/downloads and leaked-URL reuse, but cannot guarantee prevention of screen recording. Private storage, signed URLs, streaming format, encryption, and DRM remain implementation/design decisions for later phases.

## Final Review Record (30 Questions)

The original 30-question review is retained as a historical record. Later explicit decisions supersede its archival and versioning answers where noted below.

| Question | Final decision |
|---|---|
| Q1 | Ban blocks new student operations; an already-started operation may finish. Enrollment/history remain. |
| Q2 | Stage correction affects future discovery/purchases only; existing enrollments remain unchanged. |
| Q3 | Course-stage association may be added to an archived stage, but remains undiscoverable while the stage is archived. |
| Q4 | An already-authorized/validated Assistant edit may finish if a ban occurs concurrently; later requests are denied. |
| Q5 | Publishing with zero active Required items is allowed; completion remains undefined until a Required item exists. |
| Q6 | PUBLISHED → DRAFT hides course from discovery/new purchases but preserves existing enrolled-student access. |
| Q7 | Historical review answer: a prerequisite item could not be archived/deleted while dependents existed. Later decision: no item archival; Video/File hard-delete is blocked until dependencies are removed. |
| Q8 | Historical review answer about archived items is superseded: there is no Learning Item archival. Deleted Video/File items leave current calculations and their progress rows are deleted. |
| Q9 | Superseded: Learning Items cannot be archived/restored. |
| Q10 | New Required items apply to all active enrollments and can reverse prior course completion. |
| Q11 | Superseded: Learning Items cannot be archived. If there are zero Required items, completion is undefined. |
| Q12 | Recover transient post-payment failures safely and idempotently; do not ask for another payment solely because backend processing failed. |
| Q13 | Duplicate successful charges must not create duplicate active enrollments; provider-specific refund handling is deferred. |
| Q14 | Direct Assistant cancellation cancels the Enrollment/revokes access; refund handling is separate. Mandatory reason. |
| Q15 | Approval of a cancellation request does not revoke access immediately; cancellation/access revocation follows the refund/cancellation flow. |
| Q16 | No new cancellation request or repurchase while approved cancellation is in progress; wait until Enrollment is CANCELLED. |
| Q17 | Hide final score/pass/fail and do not count exam completion/prerequisite while essay grading is pending. |
| Q18 | Superseded: Exam is immutable immediately after creation; no Exam Versioning. |
| Q19 | Superseded: Assignment is immutable immediately after creation; no Assignment Versioning. |
| Q20 | ACCEPTED is final; no resubmission after acceptance. |
| Q21 | Server controls exam timing and auto-submits saved answers at expiry, including if the student disconnects. |
| Q22 | Each reset creates a separate opportunity; duplicate requests for the same reset must not create multiple opportunities. |
| Q23 | Audit Assistant actions only; require reasons for specified sensitive/admin/content operations. |
| Q24 | Assistant deactivation immediately releases unprocessed review reservations; completed decisions remain. |
| Q25 | Only one concurrent decision/state transition succeeds; no last-write-wins. |
| Q26 | Audit before/after data is selective and redacted; never store the ID-card image in Audit. |
| Q27 | Use local filtering when loaded data suffices; backend filtering when complete data/additional pages are needed. |
| Q28 | Audit logs use pagination and combined backend filters. |
| Q29 | Notifications are fully deferred until the core platform is complete. |
| Q30 | Close Phase 2; defer schema, API, provider, JWT invalidation, storage/video implementation details to their appropriate phases. |

## Deferred to Later Phases
- Database schema, constraints, indexes, and migration design.
- API contracts, request/response shapes, and endpoint details.
- Payment provider integration, provider-specific webhook/recovery mechanics, and refund lifecycle.
- Exact JWT invalidation mechanism (business rule remains: banned students cannot perform new operations; old JWT must not restore access after unban).
- Exact database constraints/triggers and storage cleanup mechanics for permitted Video/File hard deletion.
- Assessment table structure and attempt/order/grading-history persistence; Assignment/Exam versioning is not part of the product.
- Video storage, signed URL/streaming/encryption/DRM choices and actual protection implementation.
- Notification use cases/infrastructure, queues/workers, Redis, email delivery, and other optional infrastructure.
- Audit schema and exact implementation details; audit behavioral requirements above are finalized.
- Hosting, deployment, monitoring, and operational details.

## Phase 2 Exit Criteria
- Core actors and use cases are documented.
- Main workflows and failure/edge cases have been reviewed.
- Access, enrollment/payment, cancellation, content, progress, assignment/exam immutability and attempt behavior, assistant lifecycle, audit, and pagination behavior are defined at the requirements level.
- Remaining implementation-specific choices are explicitly deferred rather than silently assumed.
- No database schema or code implementation is required to close this phase.

**Phase 2 Status: COMPLETE — original review retained; later confirmed decisions supersede the historical answers identified above.**



## Subsequent Confirmed Decisions (Authoritative Overrides)

The following decisions were confirmed after the original Phase 2 review and take precedence over conflicting historical answers above:

- Courses have no archive/restore/delete workflow. `PUBLISHED -> DRAFT` is the only lifecycle transition used to stop discovery and new purchases; existing ACTIVE Enrollments retain access.
- Learning Item types are `VIDEO`, `FILE`, `ASSIGNMENT`, and `EXAM`. No Learning Item can be edited after creation, including common metadata/configuration.
- Video and File items may be hard-deleted only after all dependent prerequisite relationships are removed. Their progress records are deleted as part of the same database operation.
- Assignment and Exam items cannot be edited or deleted. No Assignment or Exam versioning exists; create a new item to correct a mistake.
- A verified successful payment for a valid Payment Attempt creates/reconciles an Enrollment even if the Course has changed from PUBLISHED to DRAFT after the attempt was created. A Payment Attempt may only be initiated while the course is PUBLISHED.
- A student withdrawing a cancellation request while it is `PENDING` causes the request record to be physically deleted. There is no `WITHDRAWN` status, and student-withdrawn requests are not retained for traceability. Deletion is not allowed after the request has moved to `APPROVED` or `REJECTED`.


---

## Latest Confirmed Decisions — 2026-11-17

This section supersedes any conflicting earlier wording in this document. It records decisions confirmed after the original phase review.

- **Project status:** Product definition, requirements, business rules, domain/database design, and architecture are complete enough to begin implementation. The project is now in **Implementation**. There is no separate API Design phase/gate. API contracts and endpoint details will be designed incrementally as each feature is implemented, after reviewing that feature's requirements and business rules.
- **Exam randomization:** Questions and options are randomized, but their per-attempt display order is **not persisted**. Do not create `exam_attempt_questions` or `exam_attempt_options` tables. The database does not promise that the same randomized order will be restored after reconnect.
- **Essay grading:** Keep only the current grading result. Regrading updates the current result; do not create `exam_answer_grading_history` or retain previous grading snapshots. The latest grader/time may be stored with the current answer if required by the implementation, but no grading-history timeline is maintained.
- **Exam answers:** Create one `exam_answers` row for every question when an attempt starts. Initially the answer fields may be NULL. This makes unanswered questions distinguishable from answered-but-wrong questions.
- **Exam pass rule:** Passing score is fixed at 50% of the exam's total marks. It is not a configurable per-exam field in the current schema.
- **Question schema:** The current table names are `assessment_questions` and `assessment_options`, not `exam_questions` and `exam_options`.
- **Assignment submissions:** Keep one current submission per (`assignment_id`, `enrollment_id`). Resubmission replaces/updates that row; no submission-version history. `is_late` is derived from `submitted_at` and the assignment's immutable `due_at`, not stored as an independent fact.
- **Cancellation request withdrawal:** A Student may withdraw only a `PENDING` request; withdrawal physically deletes that request. There is no `WITHDRAWN` status. The stored statuses are `PENDING`, `APPROVED`, and `REJECTED`.
- **Current database baseline:** The available migration set contains 22 migrations, ending with `022_create_exam_answers.sql`. The migrations are the source of truth for what is currently implemented in PostgreSQL; conceptual requirements in these documents remain the source of truth for intended behavior. Any gap between them must be tracked explicitly rather than assumed implemented.

