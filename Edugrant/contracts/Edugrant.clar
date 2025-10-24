;; Scholarship Grant Distribution Smart Contract

;; Constants
(define-constant foundation-admin tx-sender)
(define-constant err-admin-only (err u100))
(define-constant err-grant-received (err u101))
(define-constant err-not-approved (err u102))
(define-constant err-no-scholarship (err u103))
(define-constant err-grants-paused (err u104))
(define-constant err-invalid-applicant (err u105))
(define-constant err-invalid-grant-amount (err u106))

;; Data Variables
(define-data-var total-scholarship-fund uint u5000000)
(define-data-var grants-enabled bool false)

;; Data Maps
(define-map scholarship-amounts principal uint)      ;; Maps students to scholarship amount
(define-map grant-disbursed principal bool)          ;; Tracks disbursement status
(define-map academic-credentials principal bool)     ;; Academic qualification check
(define-map approved-applicants principal bool)      ;; Pre-approved students

;; Private Functions
(define-private (is-foundation-admin)
    (is-eq tx-sender foundation-admin))

(define-private (is-approved-student (student principal))
    (and 
        (is-some (map-get? approved-applicants student))
        (is-some (map-get? academic-credentials student))))

(define-private (validate-applicant (student principal))
    (and
        (is-some (some student))
        (not (is-eq student foundation-admin))))

;; Public Functions

;; Approve applicant (admin only)
(define-public (approve-applicant (student principal))
    (begin
        (asserts! (is-foundation-admin) err-admin-only)
        (asserts! (validate-applicant student) err-invalid-applicant)
        (ok (map-set approved-applicants student true))))

;; Revoke approval (admin only)
(define-public (revoke-approval (student principal))
    (begin
        (asserts! (is-foundation-admin) err-admin-only)
        (asserts! (validate-applicant student) err-invalid-applicant)
        (ok (map-set approved-applicants student false))))

;; Set academic credentials (admin only)
(define-public (set-credentials (student principal) (qualified bool))
    (begin
        (asserts! (is-foundation-admin) err-admin-only)
        (asserts! (validate-applicant student) err-invalid-applicant)
        (ok (map-set academic-credentials student qualified))))

;; Set scholarship amount (admin only)
(define-public (set-scholarship-amount (student principal) (amount uint))
    (begin
        (asserts! (is-foundation-admin) err-admin-only)
        (asserts! (validate-applicant student) err-invalid-applicant)
        (asserts! (> amount u0) err-invalid-grant-amount)
        (asserts! (<= amount (var-get total-scholarship-fund)) err-invalid-grant-amount)
        (ok (map-set scholarship-amounts student amount))))

;; Receive scholarship (public)
(define-public (receive-scholarship)
    (let ((student tx-sender)
          (grant-amount (unwrap! (map-get? scholarship-amounts student) err-no-scholarship)))
        (begin
            (asserts! (var-get grants-enabled) err-grants-paused)
            (asserts! (is-approved-student student) err-not-approved)
            (asserts! (not (default-to false (map-get? grant-disbursed student))) err-grant-received)
            (map-set grant-disbursed student true)
            (ok grant-amount))))

;; Bulk scholarship distribution (admin only)
(define-public (bulk-disburse (students (list 200 principal)) (amounts (list 200 uint)))
    (begin
        (asserts! (is-foundation-admin) err-admin-only)
        (asserts! (is-eq (len students) (len amounts)) err-invalid-grant-amount)
        (asserts! 
            (fold and 
                (map validate-applicant students) 
                true) 
            err-invalid-applicant)
        (asserts! 
            (fold and 
                (map is-positive-amount amounts)
                true) 
            err-invalid-grant-amount)
        (ok true)))

(define-private (is-positive-amount (amount uint))
    (> amount u0))

;; Toggle grant status (admin only)
(define-public (toggle-grants)
    (begin
        (asserts! (is-foundation-admin) err-admin-only)
        (ok (var-set grants-enabled (not (var-get grants-enabled))))))

;; Read-only functions

(define-read-only (get-scholarship-amount (student principal))
    (default-to u0 (map-get? scholarship-amounts student)))

(define-read-only (is-grant-disbursed (student principal))
    (default-to false (map-get? grant-disbursed student)))

(define-read-only (check-approval-status (student principal))
    (is-approved-student student))

(define-read-only (are-grants-enabled)
    (var-get grants-enabled))

(define-read-only (get-total-fund)
    (var-get total-scholarship-fund))

(define-read-only (get-student-info (student principal))
    {
        scholarship: (get-scholarship-amount student),
        disbursed: (is-grant-disbursed student),
        approved: (check-approval-status student),
        is-approved-applicant: (default-to false (map-get? approved-applicants student)),
        has-credentials: (default-to false (map-get? academic-credentials student)),
        can-receive: (and 
            (var-get grants-enabled)
            (check-approval-status student)
            (not (is-grant-disbursed student))
            (> (get-scholarship-amount student) u0)
        )
    }) 