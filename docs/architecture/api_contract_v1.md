# API Contract v1 (Draft)

Use this as a stable contract between all Flutter clients and backend logic.

## Auth

### `POST /auth/login`
- Input: `{ email, password }`
- Output: `{ accessToken, refreshToken, user: { id, role, name } }`

### `POST /auth/logout`
- Input: `{ refreshToken }`
- Output: `{ success: true }`

## Profile

### `GET /me`
- Output: `{ id, role, name, email, profilePhotoUrl }`

## Cashier

### `GET /inventory/products`
- Output: list of active products

### `POST /sales`
- Input: `{ items: [{ productId, qty, price }], paymentMethod, paidAmount }`
- Output: `{ saleId, receiptNo, totalAmount, changeAmount, createdAt }`

### `GET /sales/:saleId`
- Output: receipt details

## Partner Investment

### `GET /investments/offers`
- Output: list of available investment plans

### `POST /investments`
- Input: `{ offerId, amount }`
- Output: created investment details

### `GET /investments/my`
- Output: partner investments and status

### `GET /payouts/my`
- Output: payout history for logged-in partner

## Hog Raiser Mobile

### `GET /hog-raisers/me`
- Output: raiser profile and assigned hog units

### `POST /hog-raisers/logs/feeding`
- Input: `{ hogUnitId, fedAt, feedType, feedAmountKg, notes }`
- Output: created feeding log

### `POST /hog-raisers/logs/health`
- Input: `{ hogUnitId, observedAt, condition, treatment, notes }`
- Output: created health log

### `POST /hog-raisers/logs/growth`
- Input: `{ hogUnitId, measuredAt, weightKg, notes }`
- Output: created growth log

## Admin

### `GET /admin/dashboard`
- Output: KPI summary for sales, inventory, investments, raisers

### `POST /admin/users`
- Input: `{ name, email, role }`
- Output: created user profile

### `PATCH /admin/users/:id/role`
- Input: `{ role }`
- Output: updated role assignment
