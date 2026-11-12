# LMS — Phase 1: Product Definition

**Version:** 1.2  
**Status:** Completed — Updated after Phase 2/3 and subsequent product decisions  
**Project Type:** Learning Management System (LMS)  
**Architecture:** To be defined in later phases

---

## 1. Product Goal

The platform is a Learning Management System for a single platform owner/teacher.

The platform allows students to:

- Create an account and verify their identity.
- Select an Educational Stage during registration.
- Browse courses available for their stage.
- Purchase courses.
- Access course content after successful enrollment.
- Study video lessons.
- Submit assignments.
- Take exams.
- Track their academic record.

The platform is managed by:

- **Admin** — the platform owner/teacher.
- **Assistants** — assistants working for the same Admin.
- **Students** — learners using the platform.

---

# 2. Actors

## 2.1 Admin

There is **one Admin** for the platform.

The Admin is the platform owner and has full control over the platform.

The Admin can manage:

- Educational Stages
- Students
- Assistants
- Courses

The Admin is the only actor who can create a new Assistant.

The Admin can also manage course content, including Lectures, Videos, Files, Assignments, Exams, Questions, and publishing operations.

---

## 2.2 Assistant

There can be multiple Assistants working for the same Admin.

All Assistants currently have the **same permissions**.

Assistants can perform administrative/teaching operations such as:

- Review student registrations.
- Approve or reject students.
- Ban and unban students.
- Modify student information when necessary.
- Create and edit courses.
- Publish courses.
- Manage course content.
- Grade assignments.
- Grade essay questions.
- Perform other defined Assistant operations.

Sensitive administrative actions performed by Assistants must be recorded in the Audit Log.

---

## 2.3 Student

Students can:

- Register.
- Select an Educational Stage.
- Upload an ID Card.
- Wait for account verification.
- Browse available courses for their stage.
- Purchase courses.
- Access enrolled courses.
- Study lessons.
- Submit assignments.
- Take exams.
- View their academic record.

---

# 3. Student Registration & Verification

A student does not become active immediately after submitting registration data.

During registration, the student provides:

- Personal information
- Email
- Phone number
- Parent/Guardian phone number
- Educational Stage
- ID Card image

The registration flow is:

```text
Registration
    ↓
Select Educational Stage
    ↓
Upload ID Card
    ↓
PENDING
    ↓
Assistant Review
    ├── APPROVED
    └── REJECTED
```

The Educational Stage is selected **during registration**, not after account approval.

---

# 4. Student Account States

The system currently has the following conceptual account states:

```text
PENDING
APPROVED
REJECTED
BANNED
```

## 4.1 Pending

The account has been created but has not yet been approved.

The student cannot use the platform normally until the verification process is completed.

---

## 4.2 Approved

The student's registration and identity verification have been accepted.

The student can use the platform according to their permissions.

---

## 4.3 Rejected

The registration was rejected during review.

A rejected student can register again with corrected information.

Rejected is different from being banned.

---

## 4.4 Banned

A banned student is prohibited from accessing the platform.

The ban is permanent until an Assistant explicitly removes it.

A banned student cannot register again using the same identity/information while the ban is active.

When the ban is removed:

- The same account becomes usable again.
- Existing enrollments remain.
- Existing academic history remains.
- Existing progress/history remains.
- The student regains the same course access and progress state they had before the ban.

Ban and Unban actions must be recorded in the Audit Log.

---

# 5. Student Information

Student information is treated as verified information after the registration review.

Students cannot directly modify their account information themselves.

If information needs to be changed:

```text
Student
   ↓
Requests Change
   ↓
Assistant / Admin
   ↓
Reviews / Updates Information
```

The exact distinction between identity-critical information and contact information will be refined during the Requirements and Business Rules phases.

Current information includes:

- Name
- National ID / identity information
- Email
- Phone number
- Parent/Guardian phone number
- Educational Stage
- ID Card

---

# 6. ID Card Verification

The student uploads an ID Card during registration.

The ID Card is reviewed by an authorized Assistant/Admin as part of account verification.

The ID Card should be treated as private information.

The system should not expose the ID Card publicly.

The exact retention policy is intentionally left for later design decisions, including whether the image should be retained after verification or deleted while keeping the verification record.

---

# 7. Educational Stages

Educational Stages are created and managed by the Admin.

The Admin is free to choose the stage names.

Example:

```text
Primary 1
Primary 2
Secondary 1
Secondary 2
...
```

Rules:

- Stage names must be unique.
- Admin can create stages.
- Admin can edit stage names.
- Students select a stage during registration.
- Educational Stages are not hard-deleted in the normal business flow.
- Educational Stages use Soft Delete.

---

# 8. Course Catalog

Courses belong to an Educational Stage.

Example:

```text
Secondary 1
├── Course - Month 1
├── Course - Month 2
├── Course - Month 3
└── Course - Month 4
```

A student should only see courses available for their selected Educational Stage.

---

# 9. Course Management

Both Admin and Assistants can:

- Create courses.
- Edit courses.
- Publish courses.

A course can remain in Draft state for an unlimited period.

Current conceptual lifecycle:

```text
DRAFT
   ↓
PUBLISHED
```

Courses are never archived, restored, or deleted.

- `PUBLISHED -> DRAFT` hides the course from discovery and prevents new purchases/enrollments.
- Students with an existing ACTIVE Enrollment retain access, progress, and academic history while the course is DRAFT.
- Course and enrollment/payment/academic records remain available; the product does not provide a course deletion workflow.

---

# 10. Course Structure

Courses contain Lectures.

A Lecture can contain these Learning Item types:

- Videos
- Files (for example, PDF or other learning materials)
- Assignments
- Exams

Any Learning Item can also exist directly under the Course without belonging to a specific Lecture.

Conceptually:

```text
Course
│
├── Lecture 1
│   ├── Video
│   ├── Video
│   ├── Assignment
│   └── Exam
│
├── Lecture 2
│   ├── Video
│   └── Assignment
│
├── Assignment
│
└── Exam
```

Course content can include:

- Lectures
- Videos
- Files
- Assignments
- Exams

---

# 11. Course Purchase & Enrollment

The platform will not use a Wallet for the current design.

Students pay for courses directly.

High-level flow:

```text
Student
   ↓
View Course
   ↓
Buy Course
   ↓
Checkout
   ↓
Payment
   ↓
Successful Payment
   ↓
Enrollment
   ↓
Course Access
```

The student pays for the selected course rather than maintaining extra balance on the platform.

The following business behavior is established:

- Successful payment creates the student's Enrollment.
- Course access is granted after successful enrollment.
- Failed payment does not create an Enrollment and does not grant course access.
- A student who is already enrolled in a course cannot purchase the same course again.
- The platform does not use a Wallet.

The following remain intentionally deferred:

- Payment provider selection
- Exact payment implementation
- Detailed refund calculation/processing rules

---

# 12. Unenrollment

A student cannot directly cancel an Enrollment.

If a student wants to leave a course:

```text
Student
   ↓
Cancellation Request
   ↓
PENDING
   ↓
Assistant
   ├── REJECTED
   │
   └── APPROVED
          ↓
     Refund Decision
          ↓
     Refund Processing
          ↓
     Cancel Enrollment
          ↓
     Revoke Course Access
```

Cancellation Request approval and actual Enrollment cancellation are separate steps.

An Assistant can also cancel an Enrollment directly without a student request.

Cancellation requests are retained for traceability so the system can determine whether a cancellation originated from a student request or was initiated directly by an Assistant.

Detailed refund calculation and processing rules are deferred to the Business Rules phase.

---

# 13. Course Completion

Course completion rules are intentionally deferred.

The MVP will not yet define exactly when a student is considered to have completed an entire course.

This will be designed later together with the Certificate feature.

---

# 14. Course Certificates

Certificates are deferred.

Certificate eligibility will be defined together with Course Completion rules in a later feature phase.

---

# 15. Learning Item & Content Unlocking

Learning content can be either:

```text
UNLOCKED
```

or:

```text
LOCKED
```

A locked item can have **one prerequisite**.

Examples:

```text
Learning Item 3
requires → Learning Item 2 completed
```

```text
Exam 2
requires → Lesson 5 completed
```

```text
Learning Item 7
requires → Assignment 1 completed
```

The Admin/Assistant should be able to specify whether a learning item has a prerequisite and which item it depends on.

---

# 16. Prerequisite Completion Rules

Current rules:

| Prerequisite Type | Completion Condition |
|---|---|
| Video Lesson | Student watches at least 80% |
| Exam | Student achieves at least 50% |
| Assignment | Student's submission is ACCEPTED by an Assistant |

Only one prerequisite is required for a locked item under the current product definition.

Additional dependency rules may be introduced later if the product requires them.

---

# 17. Assignments

Assignments have:

- A submission.
- A Due Date.
- Late submission support.
- Resubmission support.

Students may resubmit while the submission is `UNDER_REVIEW` or after it is `REJECTED`. Resubmission is not allowed after `ACCEPTED`.

A submission or resubmission made after the deadline is allowed but must be marked as **Late**.

The Assistant is responsible for reviewing assignments.

Assignment review has two conceptual outcomes:

```text
SUBMITTED
   ↓
UNDER_REVIEW
   ├── ACCEPTED (final)
   └── REJECTED
          ↓
       Resubmit
          ↓
       UNDER_REVIEW
```

- `UNDER_REVIEW` means an Assistant is reviewing the current submission.
- `ACCEPTED` means the assignment is considered completed and is final; no resubmission is allowed.
- `REJECTED` means the assignment is not considered completed. An Assistant rejection must include a reason.
- A student can resubmit while the submission is under review or after rejection.
- Resubmission replaces the current submission object; the system does not keep a full version history.
- Assignments currently have **no grade**.

---

## 17.1 Assignment Resubmission

The system keeps only the latest submitted version.

Example:

```text
Submission 1
    ↓
Resubmit
    ↓
Replace previous submission
```

The system does not currently maintain a full version history of assignment submissions.

At minimum, submission timing/status information must remain available so the system can determine whether the latest submission was late.

---

# 18. Exams

The platform supports three question types.

## 18.1 MCQ

Contains:

- Question
- Multiple options
- Correct answer

The answer is automatically graded.

---

## 18.2 True / False

Contains:

- Question
- True/False options
- Correct answer

The answer is automatically graded.

---

## 18.3 Essay

Contains:

- Question
- Student answer
- Manual grading by Assistant

Essay answers are not automatically graded.

An Exam and its questions, options, correct answers, marks, passing score, time limit, and metadata are immutable immediately after creation. Exams cannot be edited or deleted. If there is a mistake, create a new Exam; the original remains.

---

# 19. Exam Attempts

A student can take each exam **one time only**.

There is no second attempt under the current product definition.

An exam is considered passed when the final score reaches at least 50% of the exam's total score.

For exams containing Essay questions, the attempt may be submitted while manual grading is still pending. The final pass/fail result is determined after the required essay grading is completed.

The exam can have a time limit.

When the time limit expires:

```text
Auto Submit
```

The server is the source of truth for exam timing.

The browser/client must not be trusted to determine whether the exam has expired.

---

# 20. Exam Randomization

Exam questions are randomized.

Answer options are also randomized.

However, once an attempt starts, the student must continue seeing the same:

- Questions
- Question order
- Options
- Option order

for that specific attempt.

This is especially important when an exam attempt is resumed after a connection failure.

---

# 21. Exam Connection Failure

A connection/device failure must not create a second attempt.

The same attempt should be resumed.

Conceptually:

```text
IN_PROGRESS
    ↓
Connection Lost
    ↓
Student Returns
    ↓
Resume Same Attempt
```

Student answers should be persisted during the exam rather than waiting until final submission.

The exact save strategy will be designed during the Architecture and Implementation phases.

---

# 22. Academic Record

The platform maintains a complete academic record for each student.

Example:

```text
Student
│
├── Course A
│   ├── Exam 1
│   │   ├── Attempt
│   │   ├── Score
│   │   └── Question Results
│   │
│   ├── Assignment 1
│   │   ├── Submission
│   │   ├── Grader
│   │   └── Graded At
│   │
│   └── Exam 2
│       └── ...
│
└── Course B
    └── ...
```

The academic history should allow the system to determine:

- All exam attempts.
- Exam scores.
- Question-level answers/results.
- Essay grader.
- Grading time.
- Grade changes/regrading history where applicable.

The academic record remains available because Courses are not deleted or archived in the product.

---

# 23. Audit Log

The system does not need to record every API request.

Instead, it records **sensitive administrative actions**.

This is especially important for actions performed by Assistants.

Examples:

```text
APPROVE_STUDENT
REJECT_STUDENT
BAN_STUDENT
UNBAN_STUDENT

CREATE_COURSE
UPDATE_COURSE
PUBLISH_COURSE

UPDATE_STUDENT
CREATE_LEARNING_ITEM
DELETE_VIDEO
DELETE_FILE

GRADE_ASSIGNMENT
GRADE_ESSAY
```

The Audit Log should answer:

> Who did what, to what, and when?

For operations where it matters, the system may also store relevant old/new values.

Audit logging requirements will be refined during the Business Rules and Architecture phases.

---

# 24. Video Protection

The product requirement is:

> Only students who are authorized/enrolled in a course can access its videos.

The platform should also prevent or significantly reduce:

- Direct unauthorized downloading.
- Access through leaked/public URLs.
- Unauthorized video retrieval.

The platform cannot guarantee prevention of every possible form of screen recording.

The exact technical solution will be decided later.

Potential technologies/approaches may include:

- Private object storage.
- Signed URLs.
- Protected streaming.
- HLS/DASH.
- Encryption.
- DRM if the required protection level justifies it.

No specific technology is selected yet.

---

# 25. Deletion Policy

## Educational Stages

Educational Stages use Soft Delete (archive/restore). Archiving a stage prevents discovery and new purchases through that stage; existing active enrollments keep their access, progress, and history. Restoring the stage makes it available again.

## Courses

Courses cannot be archived, restored, or deleted. `PUBLISHED -> DRAFT` is the supported way to stop discovery and new purchases while preserving access for existing active enrollments.

## Learning Items

Learning Items are Video, File, Assignment, or Exam. Their common definition and configuration are immutable after creation.

- Video and File items may be permanently deleted (Hard Delete), subject to prerequisite restrictions. They cannot be deleted while another Learning Item depends on them. The dependency must be removed first.
- When a Video or File is deleted, its related progress records are deleted and it is removed from current progress/completion calculations.
- Assignment and Exam items cannot be edited or deleted. If a mistake is made, create a new item; the original remains to preserve submissions, attempts, and academic history.
- A deleted Video/File is not retained as an archived item.

---

# 26. MVP Scope

The current MVP includes:

```text
Authentication / Registration
        ↓
Student Verification
        ↓
Educational Stages
        ↓
Courses
        ↓
Lectures
        ↓
Videos / Files
        ↓
Assignments
        ↓
Exams
        ↓
Learning Unlocking
        ↓
Automatic / Manual Grading
        ↓
Academic Record
        ↓
Audit Log
```

The MVP should focus on correctness, data consistency, authorization, and the core learning workflow rather than adding unnecessary technologies/features.

---

# 27. Deferred Features

The following are intentionally deferred:

- Course completion rules.
- Certificates.
- Final payment provider selection.
- Detailed refund calculation and processing rules.
- Advanced payment failure handling.
- Final video protection architecture.
- Video/file hosting and delivery implementation details (the business deletion policy is defined above).
- Other features that have not yet been defined as MVP requirements.

---

# 28. Important Product Decisions

The following decisions are currently established:

1. There is one Admin per platform.
2. There can be multiple Assistants under the same Admin.
3. All Assistants currently have the same operational permissions.
4. Only the Admin can create a new Assistant.
5. Students select their Educational Stage during registration.
6. Student accounts require manual review before approval.
7. Rejected students can register again with corrected information.
8. Banned students cannot register again using the same identity while banned.
9. Bans are permanent until explicitly removed by an Assistant.
10. After Unban, the student regains the same course access and progress state as before the ban.
11. Ban/Unban actions are auditable.
12. Students cannot directly modify verified account information.
13. Educational Stage names are unique.
14. Educational Stages are soft-deleted.
15. Courses belong to an Educational Stage.
16. Courses contain Lectures.
17. A Lecture can contain Videos, Files, Assignments, and Exams.
18. Any Learning Item can also exist directly under a Course without belonging to a Lecture.
19. Courses can remain Draft indefinitely.
20. Admin and Assistants can create, edit, and publish courses.
21. Courses are never archived, restored, or deleted; `PUBLISHED -> DRAFT` stops discovery/new purchases while preserving existing enrolled-student access.
22. All Learning Item types (Video, File, Assignment, Exam) are immutable after creation; Video/File may be hard-deleted only after prerequisite dependencies are removed, and their progress records are deleted.
23. Assignment and Exam Learning Items cannot be deleted; their submissions, attempts, and academic history remain.
24. There is no Wallet in the current design.
25. Students pay directly for courses.
26. A Payment Attempt can start only while a Course is PUBLISHED; if the Course later becomes DRAFT, a verified successful payment for that attempt still creates an Enrollment.
27. Successful payment creates an Enrollment and grants course access.
28. Failed payment creates no Enrollment and grants no course access.
29. A student cannot purchase a course they are already enrolled in.
30. Students cannot directly cancel an Enrollment.
31. Cancellation Requests have a separate lifecycle from actual Enrollment cancellation.
32. An Assistant can cancel an Enrollment directly without a student request.
33. Cancellation requests are retained for traceability.
34. Assignments support resubmission.
35. Only the latest assignment submission is retained.
36. Late assignment submissions are allowed and recorded as Late.
37. Assignment review uses ACCEPTED / REJECTED status.
38. Assignment rejection requires a reason.
39. An ACCEPTED assignment is final and cannot be resubmitted.
40. Assignments currently have no grades.
41. Students get one exam attempt.
42. Exams can auto-submit when their time expires.
43. Exam questions and options are randomized.
44. Randomization remains fixed for an active attempt.
45. Exam attempts can be resumed after connection/device failure.
46. An exam is passed at a final score of at least 50% of the total exam score.
47. Exams containing essays can remain pending manual grading after submission.
48. Video completion requires at least 80% watched.
49. Assignment prerequisite completion requires an ACCEPTED submission.
50. Exam prerequisite completion requires a final score of at least 50%.
51. A learning item currently has at most one prerequisite.
52. Academic history is retained.
53. Sensitive administrative actions are audited.



# 29. Phase 1 Exit Criteria

Phase 1 is considered complete when:

- The target users are defined.
- The core product purpose is defined.
- The main product boundaries are defined.
- The major workflows are identified.
- Important MVP/deferred features are separated.
- Major product assumptions are documented.
- No database schema or implementation decisions are required to understand the product.

**Phase 1 Status: COMPLETE — Version 1.2**

---

# Next Phase

## Phase 2 — Requirements & Use Cases

The next phase will transform this product definition into precise workflows.

For each important use case, we will define:

- Actor
- Goal
- Preconditions
- Main Flow
- Alternative Flows
- Failure Cases
- Authorization Requirements
- Expected Result

Examples:

```text
Student Registration
Student Approval
Student Rejection
Student Ban / Unban
Create Course
Publish Course
Purchase Course
Enrollment
Submit Assignment
Resubmit Assignment
Start Exam
Answer Exam Questions
Resume Exam
Auto Submit Exam
Grade Essay
Manage Student
```

Only after Phase 2 is complete will we move to:

```text
Phase 3 — Business Rules
```

Phase 3 will be used to formally define the rules, invariants, edge cases, and consistency requirements that will later drive the Domain and Database design.

---

## Development Process

The complete project process is:

```text
Phase 1 — Product Definition
        ↓
Phase 2 — Requirements & Use Cases
        ↓
Phase 3 — Business Rules
        ↓
Phase 4 — Domain + Database Design
        ↓
Phase 5 — Architecture
        ↓
Phase 6 — API Design
        ↓
Phase 7 — Implementation
        ├── Unit Testing
        ├── Integration Testing
        └── Feature Review
        ↓
Phase 8 — Testing + Deployment
```

Testing is not postponed until the end.

**Unit testing will be performed during Implementation alongside the business logic being developed.**
