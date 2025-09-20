;; Collaborative Comic Creation Contract
;; Multi-creator comic series with shared ownership and revenue distribution


;; Define constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_COMIC_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_CREATOR (err u102))
(define-constant ERR_NOT_CREATOR (err u103))
(define-constant ERR_INVALID_SHARE (err u104))
(define-constant ERR_INSUFFICIENT_BALANCE (err u105))
(define-constant ERR_COMIC_FINALIZED (err u106))
(define-constant ERR_INVALID_PRICE (err u107))
(define-constant ERR_TRANSFER_FAILED (err u108))

;; Define data variables
(define-data-var next-comic-id uint u1)
(define-data-var platform-fee-percentage uint u5) ;; 5% platform fee

;; Define data maps
(define-map comics
  { comic-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    total-issues: uint,
    current-issue: uint,
    price-per-issue: uint,
    is-finalized: bool,
    total-revenue: uint,
    created-at: uint,
    metadata-uri: (string-ascii 200)
  }
)

(define-map comic-creators
  { comic-id: uint, creator: principal }
  {
    ownership-share: uint, ;; percentage out of 10000 (basis points)
    contributed-issues: uint,
    role: (string-ascii 50),
    joined-at: uint
  }
)

(define-map creator-comics
  { creator: principal, comic-id: uint }
  { is-creator: bool }
)

(define-map issue-purchases
  { comic-id: uint, issue: uint, buyer: principal }
  { purchased-at: uint, price-paid: uint }
)

(define-map comic-issues
  { comic-id: uint, issue: uint }
  {
    title: (string-ascii 100),
    content-uri: (string-ascii 200),
    creator: principal,
    published-at: uint,
    is-published: bool
  }
)

;; Read-only functions
(define-read-only (get-comic (comic-id uint))
  (map-get? comics { comic-id: comic-id })
)

(define-read-only (get-comic-creator (comic-id uint) (creator principal))
  (map-get? comic-creators { comic-id: comic-id, creator: creator })
)

(define-read-only (get-comic-issue (comic-id uint) (issue uint))
  (map-get? comic-issues { comic-id: comic-id, issue: issue })
)

(define-read-only (has-purchased-issue (comic-id uint) (issue uint) (buyer principal))
  (is-some (map-get? issue-purchases { comic-id: comic-id, issue: issue, buyer: buyer }))
)

(define-read-only (get-next-comic-id)
  (var-get next-comic-id)
)

(define-read-only (get-platform-fee)
  (var-get platform-fee-percentage)
)

(define-read-only (is-creator (comic-id uint) (creator principal))
  (is-some (map-get? comic-creators { comic-id: comic-id, creator: creator }))
)

;; Private functions
(define-private (calculate-creator-share (revenue uint) (share uint))
  (/ (* revenue share) u10000)
)

(define-private (calculate-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-percentage)) u100)
)

;; Public functions
(define-public (create-comic 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (total-issues uint)
  (price-per-issue uint)
  (metadata-uri (string-ascii 200))
  (initial-share uint))
  (let ((comic-id (var-get next-comic-id)))
    (asserts! (> total-issues u0) ERR_INVALID_PRICE)
    (asserts! (> price-per-issue u0) ERR_INVALID_PRICE)
    (asserts! (and (> initial-share u0) (<= initial-share u10000)) ERR_INVALID_SHARE)
    
    ;; Create comic
    (map-set comics
      { comic-id: comic-id }
      {
        title: title,
        description: description,
        total-issues: total-issues,
        current-issue: u0,
        price-per-issue: price-per-issue,
        is-finalized: false,
        total-revenue: u0,
        created-at: block-height,
        metadata-uri: metadata-uri
      }
    )
    
    ;; Add creator
    (map-set comic-creators
      { comic-id: comic-id, creator: tx-sender }
      {
        ownership-share: initial-share,
        contributed-issues: u0,
        role: "founder",
        joined-at: block-height
      }
    )
    
    (map-set creator-comics
      { creator: tx-sender, comic-id: comic-id }
      { is-creator: true }
    )
    
    ;; Increment next comic ID
    (var-set next-comic-id (+ comic-id u1))
    
    (ok comic-id)
  )
)

(define-public (add-creator 
  (comic-id uint)
  (new-creator principal)
  (ownership-share uint)
  (role (string-ascii 50)))
  (let ((comic (unwrap! (get-comic comic-id) ERR_COMIC_NOT_FOUND)))
    (asserts! (is-creator comic-id tx-sender) ERR_NOT_CREATOR)
    (asserts! (not (is-creator comic-id new-creator)) ERR_ALREADY_CREATOR)
    (asserts! (and (> ownership-share u0) (<= ownership-share u10000)) ERR_INVALID_SHARE)
    (asserts! (not (get is-finalized comic)) ERR_COMIC_FINALIZED)
    
    (map-set comic-creators
      { comic-id: comic-id, creator: new-creator }
      {
        ownership-share: ownership-share,
        contributed-issues: u0,
        role: role,
        joined-at: block-height
      }
    )
    
    (map-set creator-comics
      { creator: new-creator, comic-id: comic-id }
      { is-creator: true }
    )
    
    (ok true)
  )
)

(define-public (publish-issue
  (comic-id uint)
  (issue-title (string-ascii 100))
  (content-uri (string-ascii 200)))
  (let (
    (comic (unwrap! (get-comic comic-id) ERR_COMIC_NOT_FOUND))
    (current-issue (get current-issue comic))
    (next-issue (+ current-issue u1))
  )
    (asserts! (is-creator comic-id tx-sender) ERR_NOT_CREATOR)
    (asserts! (not (get is-finalized comic)) ERR_COMIC_FINALIZED)
    (asserts! (<= next-issue (get total-issues comic)) ERR_COMIC_FINALIZED)
    
    ;; Create issue
    (map-set comic-issues
      { comic-id: comic-id, issue: next-issue }
      {
        title: issue-title,
        content-uri: content-uri,
        creator: tx-sender,
        published-at: block-height,
        is-published: true
      }
    )
    
    ;; Update comic current issue
    (map-set comics
      { comic-id: comic-id }
      (merge comic { current-issue: next-issue })
    )
    
    ;; Update creator contribution
    (let ((creator-info (unwrap! (get-comic-creator comic-id tx-sender) ERR_NOT_CREATOR)))
      (map-set comic-creators
        { comic-id: comic-id, creator: tx-sender }
        (merge creator-info { contributed-issues: (+ (get contributed-issues creator-info) u1) })
      )
    )
    
    (ok next-issue)
  )
)

(define-public (purchase-issue (comic-id uint) (issue uint))
  (let (
    (comic (unwrap! (get-comic comic-id) ERR_COMIC_NOT_FOUND))
    (comic-issue (unwrap! (get-comic-issue comic-id issue) ERR_COMIC_NOT_FOUND))
    (price (get price-per-issue comic))
    (platform-fee (calculate-platform-fee price))
    (creator-revenue (- price platform-fee))
  )
    (asserts! (get is-published comic-issue) ERR_COMIC_NOT_FOUND)
    (asserts! (not (has-purchased-issue comic-id issue tx-sender)) ERR_ALREADY_CREATOR)
    
    ;; Transfer STX for purchase
    (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
    
    ;; Record purchase
    (map-set issue-purchases
      { comic-id: comic-id, issue: issue, buyer: tx-sender }
      { purchased-at: block-height, price-paid: price }
    )
    
    ;; Update comic revenue
    (map-set comics
      { comic-id: comic-id }
      (merge comic { total-revenue: (+ (get total-revenue comic) creator-revenue) })
    )
    
    (ok true)
  )
)

(define-public (distribute-revenue (comic-id uint))
  (let ((comic (unwrap! (get-comic comic-id) ERR_COMIC_NOT_FOUND)))
    (asserts! (is-creator comic-id tx-sender) ERR_NOT_CREATOR)
    (asserts! (> (get total-revenue comic) u0) ERR_INSUFFICIENT_BALANCE)
    
    ;; Reset revenue to 0 after distribution
    (map-set comics
      { comic-id: comic-id }
      (merge comic { total-revenue: u0 })
    )
    
    (ok (get total-revenue comic))
  )
)

(define-public (finalize-comic (comic-id uint))
  (let ((comic (unwrap! (get-comic comic-id) ERR_COMIC_NOT_FOUND)))
    (asserts! (is-creator comic-id tx-sender) ERR_NOT_CREATOR)
    (asserts! (not (get is-finalized comic)) ERR_COMIC_FINALIZED)
    (asserts! (>= (get current-issue comic) (get total-issues comic)) ERR_COMIC_FINALIZED)
    
    (map-set comics
      { comic-id: comic-id }
      (merge comic { is-finalized: true })
    )
    
    (ok true)
  )
)

(define-public (update-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= new-fee u10) ERR_INVALID_SHARE) ;; Max 10%
    (var-set platform-fee-percentage new-fee)
    (ok true)
  )
)

(define-public (withdraw-platform-fees (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (try! (as-contract (stx-transfer? amount tx-sender CONTRACT_OWNER)))
    (ok true)
  )
)
