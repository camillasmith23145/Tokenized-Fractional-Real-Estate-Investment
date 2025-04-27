;; Property Verification Contract
;; Validates legitimate real estate assets

(define-data-var admin principal tx-sender)

;; Property data structure
(define-map properties
  { property-id: uint }
  {
    owner: principal,
    address: (string-ascii 256),
    verified: bool,
    value: uint,
    creation-time: uint
  }
)

;; Property verification requests
(define-map verification-requests
  { property-id: uint }
  {
    owner: principal,
    address: (string-ascii 256),
    documents-hash: (buff 32),
    status: (string-ascii 20),
    request-time: uint
  }
)

;; Get admin
(define-read-only (get-admin)
  (var-get admin)
)

;; Change admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)

;; Submit property for verification
(define-public (submit-property
    (property-id uint)
    (address (string-ascii 256))
    (documents-hash (buff 32)))
  (begin
    (asserts! (is-none (map-get? properties { property-id: property-id })) (err u100))
    (asserts! (is-none (map-get? verification-requests { property-id: property-id })) (err u101))

    (map-set verification-requests
      { property-id: property-id }
      {
        owner: tx-sender,
        address: address,
        documents-hash: documents-hash,
        status: "pending",
        request-time: block-height
      }
    )
    (ok true)
  )
)

;; Verify property (admin only)
(define-public (verify-property
    (property-id uint)
    (value uint)
    (approve bool))
  (let (
    (request (unwrap! (map-get? verification-requests { property-id: property-id }) (err u102)))
  )
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (if approve
      (begin
        (map-set properties
          { property-id: property-id }
          {
            owner: (get owner request),
            address: (get address request),
            verified: true,
            value: value,
            creation-time: block-height
          }
        )
        (map-delete verification-requests { property-id: property-id })
        (ok true)
      )
      (begin
        (map-delete verification-requests { property-id: property-id })
        (ok false)
      )
    )
  )
)

;; Check if property is verified
(define-read-only (is-property-verified (property-id uint))
  (match (map-get? properties { property-id: property-id })
    property (get verified property)
    false
  )
)

;; Get property details
(define-read-only (get-property (property-id uint))
  (map-get? properties { property-id: property-id })
)

;; Get verification request
(define-read-only (get-verification-request (property-id uint))
  (map-get? verification-requests { property-id: property-id })
)
