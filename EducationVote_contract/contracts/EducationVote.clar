
;; title: EducationVote
;; version: 1.0.0
;; summary: Academic democracy platform for curriculum development and teaching methodology approval
;; description: A smart contract that enables academic institutions to create and vote on
;;              curriculum proposals and teaching methodologies in a decentralized manner.

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u101))
(define-constant ERR-VOTING-ENDED (err u102))
(define-constant ERR-ALREADY-VOTED (err u103))
(define-constant ERR-INVALID-PROPOSAL (err u104))
(define-constant ERR-INSUFFICIENT-BALANCE (err u105))

;; Proposal status constants
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-PASSED u2)
(define-constant STATUS-REJECTED u3)

;; Minimum voting period (blocks)
(define-constant MIN-VOTING-PERIOD u144) ;; ~1 day

;; data vars
(define-data-var proposal-counter uint u0)
(define-data-var authorized-voters-count uint u0)

;; data maps
;; Proposals map: proposal-id -> proposal data
(define-map proposals uint {
    title: (string-utf8 256),
    description: (string-utf8 1024),
    proposer: principal,
    proposal-type: (string-utf8 64), ;; "curriculum" or "methodology"
    voting-start: uint,
    voting-end: uint,
    votes-for: uint,
    votes-against: uint,
    status: uint
})

;; Authorized voters map
(define-map authorized-voters principal bool)

;; Vote tracking: proposal-id + voter -> vote choice
(define-map votes { proposal-id: uint, voter: principal } bool)

;; User profiles for academic credentials
(define-map user-profiles principal {
    institution: (string-utf8 256),
    department: (string-utf8 128),
    role: (string-utf8 64), ;; "professor", "admin", "student", etc.
    verified: bool
})

;; public functions

;; Initialize contract owner as authorized voter and admin
(define-public (initialize)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (map-set authorized-voters CONTRACT-OWNER true)
        (var-set authorized-voters-count u1)
        (map-set user-profiles CONTRACT-OWNER {
            institution: u"System Admin",
            department: u"Administration",
            role: u"admin",
            verified: true
        })
        (ok true)
    )
)

;; Add authorized voter (only contract owner)
(define-public (add-authorized-voter (voter principal) (institution (string-utf8 256))
                                   (department (string-utf8 128)) (role (string-utf8 64)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (map-set authorized-voters voter true)
        (map-set user-profiles voter {
            institution: institution,
            department: department,
            role: role,
            verified: true
        })
        (var-set authorized-voters-count (+ (var-get authorized-voters-count) u1))
        (ok true)
    )
)

;; Remove authorized voter (only contract owner)
(define-public (remove-authorized-voter (voter principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (> (var-get authorized-voters-count) u1) ERR-NOT-AUTHORIZED) ;; Keep at least one voter
        (map-delete authorized-voters voter)
        (map-delete user-profiles voter)
        (var-set authorized-voters-count (- (var-get authorized-voters-count) u1))
        (ok true)
    )
)

;; Create a new proposal
(define-public (create-proposal (title (string-utf8 256)) (description (string-utf8 1024))
                              (proposal-type (string-utf8 64)) (voting-duration uint))
    (let
        (
            (proposal-id (+ (var-get proposal-counter) u1))
            (current-block block-height)
            (end-block (+ current-block (if (> voting-duration MIN-VOTING-PERIOD) voting-duration MIN-VOTING-PERIOD)))
        )
        (asserts! (default-to false (map-get? authorized-voters tx-sender)) ERR-NOT-AUTHORIZED)
        (asserts! (or (is-eq proposal-type u"curriculum") (is-eq proposal-type u"methodology")) ERR-INVALID-PROPOSAL)

        (map-set proposals proposal-id {
            title: title,
            description: description,
            proposer: tx-sender,
            proposal-type: proposal-type,
            voting-start: current-block,
            voting-end: end-block,
            votes-for: u0,
            votes-against: u0,
            status: STATUS-ACTIVE
        })

        (var-set proposal-counter proposal-id)
        (ok proposal-id)
    )
)

;; Vote on a proposal
(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
            (vote-key { proposal-id: proposal-id, voter: tx-sender })
        )
        (asserts! (default-to false (map-get? authorized-voters tx-sender)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status proposal) STATUS-ACTIVE) ERR-VOTING-ENDED)
        (asserts! (<= block-height (get voting-end proposal)) ERR-VOTING-ENDED)
        (asserts! (is-none (map-get? votes vote-key)) ERR-ALREADY-VOTED)

        ;; Record the vote
        (map-set votes vote-key vote-for)

        ;; Update vote counts
        (if vote-for
            (map-set proposals proposal-id
                (merge proposal { votes-for: (+ (get votes-for proposal) u1) }))
            (map-set proposals proposal-id
                (merge proposal { votes-against: (+ (get votes-against proposal) u1) }))
        )

        (ok true)
    )
)

;; Finalize a proposal (can be called by anyone after voting period ends)
(define-public (finalize-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
            (votes-for (get votes-for proposal))
            (votes-against (get votes-against proposal))
            (total-votes (+ votes-for votes-against))
            (required-majority (/ (var-get authorized-voters-count) u2))
        )
        (asserts! (is-eq (get status proposal) STATUS-ACTIVE) ERR-VOTING-ENDED)
        (asserts! (> block-height (get voting-end proposal)) ERR-VOTING-ENDED)

        ;; Determine result: proposal passes if more than 50% of authorized voters vote for it
        (let ((new-status (if (and (> votes-for votes-against) (> votes-for required-majority))
                              STATUS-PASSED
                              STATUS-REJECTED)))
            (map-set proposals proposal-id (merge proposal { status: new-status }))
            (ok new-status)
        )
    )
)

;; read only functions

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id)
)

;; Get vote by voter for specific proposal
(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes { proposal-id: proposal-id, voter: voter })
)

;; Check if user is authorized voter
(define-read-only (is-authorized-voter (user principal))
    (default-to false (map-get? authorized-voters user))
)

;; Get user profile
(define-read-only (get-user-profile (user principal))
    (map-get? user-profiles user)
)

;; Get current proposal counter
(define-read-only (get-proposal-counter)
    (var-get proposal-counter)
)

;; Get total authorized voters count
(define-read-only (get-authorized-voters-count)
    (var-get authorized-voters-count)
)

;; Get proposal status name
(define-read-only (get-status-name (status uint))
    (if (is-eq status STATUS-ACTIVE)
        "Active"
        (if (is-eq status STATUS-PASSED)
            "Passed"
            "Rejected"
        )
    )
)

;; Check if voting is still active for a proposal
(define-read-only (is-voting-active (proposal-id uint))
    (match (map-get? proposals proposal-id)
        proposal (and
            (is-eq (get status proposal) STATUS-ACTIVE)
            (<= block-height (get voting-end proposal))
        )
        false
    )
)

;; private functions
;;
