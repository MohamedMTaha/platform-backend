# LMS — Phase 3: Business Rules

**Status:** COMPLETE — updated after subsequent explicit product decisions.  
**Source of truth:** Phase 2 plus the later confirmed overrides recorded at the end of Phase 2. This document consolidates the currently active rules; superseded questionnaire answers are historical only.

## A. Confirmed business rules

| ID | Business rule |
|---|---|
| BR-301 | When a REJECTED student corrects registration details and resubmits, the same registration returns to PENDING for review; it does not become APPROVED automatically. |
| BR-302 | An authorized Assistant's edit of an APPROVED student's verified identity data does not itself trigger a new verification cycle. Existing authorization and audit requirements apply. |
| BR-303 | Courses cannot be archived, restored, or deleted. `PUBLISHED -> DRAFT` hides a course from discovery and prevents new purchases while preserving access, progress, and history for existing ACTIVE Enrollments. |
| BR-304 | A Learning Item already used by students cannot be transferred to a different Course; create a separate item in the destination Course. |
| BR-305 | A Required item is included in current progress/completion calculations; an Optional item is excluded and cannot be a prerequisite. Required/Optional is fixed at item creation. |
| BR-306 | The student does not receive a separate view of previous cancelled Enrollment details after re-enrollment; administrative users may inspect them. Student access to the academic record remains as defined in Phase 2. |
| BR-307 | A Payment Attempt uses the course price captured when that attempt was created, even if the catalog price changes before confirmation. Payment confirmation must match the attempt amount. |
| BR-308 | Resetting an in-progress Exam Attempt invalidates/closes the old attempt and retains it in history; the reset creates a distinct new opportunity. Reset authorization, reason, audit, and idempotency remain required. |
| BR-309 | Regrading an Essay result updates the current grading result. Previous grading results are not retained in a separate history table. |
| BR-310 | Deactivating an Assistant does not reverse grading decisions already successfully committed. Subsequent actions require an active Assistant account. |
| BR-311 | Assignment and Exam definitions are immutable immediately after creation. No versions, edits, or deletion; create a new item to correct a mistake. |
| BR-312 | Video and File Learning Items are immutable after creation but may be hard-deleted after all prerequisite dependents are removed. Their Learning Progress records are deleted with the item. |
| BR-313 | Learning Item archival/restoration does not exist. Required/Optional, prerequisite, title, description, position, location, and type-specific content are fixed at creation. |
| BR-314 | A Payment Attempt can be created only while the Course is PUBLISHED. If the Course later changes to DRAFT, a verified successful payment for that already-valid attempt still creates/reconciles an ACTIVE Enrollment. |

## B. Assignment rules

- States: `SUBMITTED`, `UNDER_REVIEW`, `ACCEPTED`, `REJECTED`.
- Exactly one current Submission exists per (`assignment_id`, `enrollment_id`).
- Resubmission updates/replaces that same current Submission; no submission history/version history is retained.
- Student may resubmit while `UNDER_REVIEW` or after `REJECTED`.
- `ACCEPTED` is final; no resubmission after acceptance.
- `REJECTED` requires a reason.
- Late submissions are allowed and marked using the submission timestamp relative to the due date; late does not automatically reject.
- Assignments have no grade.
- Assignment definition is immutable immediately after creation; no editing, deletion, or versioning.

## C. Exam rules

- Exam, questions, options, correct answers, marks, passing score, time limit, and metadata are immutable immediately after creation.
- No Exam Versioning and no Exam deletion. If there is a mistake, create a new Exam; the old one remains.
- One attempt by default. Admin/Assistant may reset with mandatory reason and audit; old attempt is invalidated/closed but retained, and a new distinct opportunity is created. Duplicate reset requests are idempotent.
- MCQ/True-False are auto-graded; Essay is manually graded.
- If Essay grading is pending, final score/pass/fail remains hidden and the Exam Learning Item is not complete.
- Passing score is 50%. Server time is authoritative; expiry auto-submits saved answers, including if the student disconnects.
- Questions and options are randomized, but per-attempt display order is not persisted. The database does not guarantee restoration of the same order after reconnect.
- Essay regrading updates the current result; no previous-result history is retained. The current grader/time may be recorded with the current answer.

## D. Video/File deletion rules

- Video and File Learning Items cannot be edited after creation.
- Hard deletion is allowed only if no other Learning Item currently references the target as its prerequisite.
- The prerequisite relationship must be removed explicitly first; deletion must never silently clear dependent relationships.
- The deletion transaction removes the related Learning Progress rows and the Learning Item/detail records. The deleted item is excluded from current progress/completion calculations.
- Assignment and Exam items are not deletable.
- If a Video/File has a physical object in private storage, the database transaction records a storage-cleanup outbox task before deleting the metadata. A separate processor removes the object and retries failures; no third-party queue service is required by this rule.

## E. Payment and Enrollment rules

- No Wallet. Student pays directly for a Course.
- A Payment Attempt may be initiated only for a PUBLISHED Course and captures the current course price.
- Course status changing from PUBLISHED to DRAFT after a valid attempt was initiated does not invalidate that attempt. Once provider success is verified and student/course/amount match, create or recover the ACTIVE Enrollment idempotently.
- Failed/pending payments do not create Enrollment or grant access. Duplicate webhook delivery and transient backend failure must be safely recoverable.
- At most one ACTIVE Enrollment per student/course. Existing ACTIVE Enrollment blocks repurchase.

## F. Other confirmed rules retained from Phase 2

- Stage archive/restore remains supported; it is distinct from Course lifecycle.
- Stage correction preserves existing enrollments/access/progress/history; future discovery/purchases use the corrected stage.
- Required Learning Items added to a Course apply to all ACTIVE Enrollments and may make a previously completed Course incomplete.
- Progress = completed Required Learning Items / total Required Learning Items. Optional items are excluded; locked Required items remain in the denominator. If there are zero Required items, Course Completion is undefined.
- Video completion requires at least 80% watched; Assignment completion requires `ACCEPTED`; Exam completion requires final score >=50% after all required Essay grading.
- Assistant actions requiring audit and their business changes must commit atomically. Audit records are append-only.
- Concurrent state transitions must be guarded; no last-write-wins for decisions.

## G. Cancellation request rules

- Cancellation request states are `PENDING`, `APPROVED`, and `REJECTED`. There is no `WITHDRAWN` state.
- A Student may withdraw their own request only while it is `PENDING`. Withdrawal physically deletes the request record; no historical row is retained for a student-withdrawn request.
- The deletion must be conditional on the request still being `PENDING`. A request that has already been `APPROVED` or `REJECTED` cannot be deleted through the student withdrawal flow.
- After a pending request is deleted, the Student may create a new cancellation request for the same Enrollment.
- Admin/Assistant may approve or reject a pending request. A rejected request remains in the system; a later request may be created.
- At most one `PENDING` cancellation request may exist per Enrollment.
- An `APPROVED` request blocks new cancellation requests and repurchase while cancellation/refund processing is in progress. Approval alone does not cancel the Enrollment or revoke access. Once the Enrollment becomes `CANCELLED`, access is revoked.
- A direct Assistant cancellation remains a separate flow: it immediately cancels the Enrollment/revokes access and requires a mandatory reason. Refund handling is separate.

## H. Deferred details

| ID | Topic | Current handling |
|---|---|---|
| D-301 | Whether a stage correction affects ongoing exams/assignments | Existing enrollment/access/progress/history remain unchanged; additional nuance deferred. |
| D-303 | Exact permissions and conditions for Essay regrading | Define during Assessment feature design. |
| D-304 | Exact technical schema for price snapshots, attempt reset idempotency, and invalidated attempts | Define during database/implementation design. |
| D-305 | Operational details for object-storage cleanup retries | Define during storage implementation; the database-backed outbox requirement is established. |

## I. Phase 3 exit decision

Phase 3 remains COMPLETE. The active rules in this document are the behavioral baseline for implementation. The latest confirmed decisions at the end of this document supersede any conflicting earlier review notes.


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

