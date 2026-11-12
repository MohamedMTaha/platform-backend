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
| BR-309 | Regrading an already finalized Essay result is permitted through an authorized workflow, preserving prior grading results, actor, and time in mandatory regrading history. Exact permissions are deferred. |
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
- Questions and options are randomized at attempt start; the same attempt retains its exact question and option order after reconnect. Persist the per-attempt ordering.
- Essay regrading is allowed through an authorized workflow; prior result, actor, and timestamp must be preserved in grading history.

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

## G. Deferred details

| ID | Topic | Current handling |
|---|---|---|
| D-301 | Whether a stage correction affects ongoing exams/assignments | Existing enrollment/access/progress/history remain unchanged; additional nuance deferred. |
| D-303 | Exact permissions and conditions for Essay regrading | Define during Assessment feature design. |
| D-304 | Exact technical schema for price snapshots, attempt reset idempotency, and invalidated attempts | Define during database/implementation design. |
| D-305 | Operational details for object-storage cleanup retries | Define during storage implementation; the database-backed outbox requirement is established. |

## H. Phase 3 exit decision

Phase 3 remains COMPLETE. The rules above are the active behavioral baseline for Phase 4 database design and implementation. Historical versioning and archival decisions superseded by BR-303 and BR-311 through BR-314 must not be implemented.
