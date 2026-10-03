# MamboPoint POS — Firestore Data Model & Security

> Phase 1 deliverable for the Product Management module.
> Implements `docs/PRODUCT_MANAGMENT.md` sections 4, 5, 21, 22, 23, 24, 25 and 33.

---

## 1. Multi-tenant layout

MamboPoint is multi-tenant from day one. Every business-owned document lives
under a `businesses/{businessId}` path; there are no top-level `products` or
`categories` collections.

```text
users/{uid}
businesses/{businessId}
businesses/{businessId}/members/{uid}
businesses/{businessId}/categories/{categoryId}
businesses/{businessId}/products/{productId}
businesses/{businessId}/counters/sku
businesses/{businessId}/skuIndex/{skuKey}
businesses/{businessId}/barcodeIndex/{barcodeKey}
```

Because the `businessId` is part of the document address, the security rules
always have a tenant to authorise against. The client never gets to pass a
`businessId` as an ordinary field and have it trusted (spec section 22).

---

## 2. `users/{uid}`

The bridge between Firebase Authentication and the tenant model.

| Field         | Type      | Notes                                      |
| ------------- | --------- | ------------------------------------------ |
| `uid`         | string    | Must equal the document id.                |
| `email`       | string    | ≤ 320 chars, copied from the auth account. |
| `displayName` | string    | ≤ 120 chars.                               |
| `businessId`  | string    | Primary business for this user.            |
| `role`        | string    | `owner` \| `admin` \| `manager` \| `staff` |
| `isActive`    | bool      | Soft disable without deleting the account. |
| `createdAt`   | timestamp | Server timestamp.                          |
| `updatedAt`   | timestamp | Server timestamp.                          |

**Immutability:** a user may edit only `displayName`, `email`, `isActive` and
`updatedAt` on their own document. `role`, `businessId` and `createdAt` are
frozen for self-edits — only an owner/admin may change another member's role.
This prevents privilege escalation through a profile write.

---

## 3. `businesses/{businessId}`

| Field       | Type      | Notes                                          |
| ----------- | --------- | ---------------------------------------------- |
| `id`        | string    | Must equal the document id (`firestore.rules`). |
| `name`      | string    | 1–120 chars, trimmed.                          |
| `ownerId`   | string    | uid of the registering user. Immutable.        |
| `currency`  | string    | 3 uppercase letters; `KES` at launch.          |
| `isActive`  | bool      |                                                |
| `createdAt` | timestamp |                                                |
| `updatedAt` | timestamp |                                                |
| `createdBy` | string    | Immutable.                                     |

---

## 4. `businesses/{businessId}/members/{uid}`

Optional secondary memberships, so a user can later belong to more than one
business without a schema change. When this document exists it takes
precedence over `users/{uid}` when resolving a role.

| Field       | Type      | Notes                                       |
| ----------- | --------- | ------------------------------------------- |
| `uid`       | string    | Must equal the document id.                 |
| `role`      | string    | `owner` \| `admin` \| `manager` \| `staff`  |
| `isActive`  | bool      |                                             |
| `createdAt` | timestamp | Immutable.                                  |
| `updatedAt` | timestamp |                                             |

---

## 5. `businesses/{businessId}/categories/{categoryId}`

| Field         | Type           | Notes                                     |
| ------------- | -------------- | ----------------------------------------- |
| `id`          | string         | Must equal the document id.               |
| `name`        | string         | 1–120 chars, trimmed.                     |
| `nameLower`   | string         | `name.lower()`, validated by the rules.   |
| `description` | string \| null | ≤ 1000 chars.                             |
| `isActive`    | bool           | Soft delete; documents are never removed. |
| `createdAt`   | timestamp      |                                           |
| `updatedAt`   | timestamp      |                                           |
| `createdBy`   | string         | Immutable.                                |
| `updatedBy`   | string         | Must equal the caller on every write.     |

---

## 6. `businesses/{businessId}/products/{productId}`

| Field               | Type           | Notes                                                             |
| ------------------- | -------------- | ----------------------------------------------------------------- |
| `id`                | string         | Must equal the document id.                                       |
| `name`              | string         | Required, 1–120 chars, trimmed (spec 5.1).                        |
| `nameLower`         | string         | `name.lower()`.                                                   |
| `nameTokens`        | array<string>  | ≤ 24 lowercase word prefixes for `array-contains` search.          |
| `sku`               | string         | 1–64 chars, trimmed, unique per business (spec 5.2).              |
| `skuLower`          | string         | `sku.lower()` for prefix search and uniqueness claims.            |
| `barcode`           | string \| null | ≤ 64 chars, trimmed, unique per business when present (spec 5.3). |
| `categoryId`        | string \| null | Primary relationship to a category document.                      |
| `categoryName`      | string \| null | Denormalised snapshot for list rendering (spec 4).                |
| `description`       | string \| null | ≤ 1000 chars.                                                     |
| `unit`              | string         | 1–32 chars; see `ProductUnits` (spec 6).                          |
| `purchasePrice`     | number         | ≥ 0, ≤ 1,000,000,000.                                             |
| `sellingPrice`      | number         | ≥ 0, ≤ 1,000,000,000.                                             |
| `stockQuantity`     | int            | ≥ 0, ≤ 1,000,000,000. Integers avoid float drift.                 |
| `lowStockThreshold` | int            | ≥ 0, ≤ 1,000,000,000.                                             |
| `imageUrl`          | string \| null | Firebase Storage download URL, ≤ 2048 chars.                      |
| `isActive`          | bool           | Soft delete / POS availability (spec 9).                          |
| `createdAt`         | timestamp      | Immutable after create.                                           |
| `createdBy`         | string         | Immutable after create.                                           |
| `updatedAt`         | timestamp      |                                                                   |
| `updatedBy`         | string         | Must equal the caller on every write.                             |

### Why `nameTokens` exists

Firestore has no "contains" search. Persisting the lowercase prefixes of each
name word lets the list screen run a single indexed `array-contains` query, so
"tom" still finds "Fresh Tomatoes" without downloading the whole collection.
Tokens are generated by `buildNameTokens()` in
`lib/core/utils/search_tokens.dart` and capped by
`ProductLimits.maxNameTokens`.

### Why nullable fields are written explicitly as `null`

Writing every key on every create gives documents a stable shape. That makes
the rule validators total (no missing-key errors) and keeps later schema
additions backwards compatible. Barcode uniqueness is only enforced when a
value is present, which is why `barcode` is `null` rather than `""`.

---

## 7. Counters and uniqueness claims

Firestore has no unique constraint and no auto-increment, so two supporting
structures are used. Both live inside the tenant.

### 7.1 `businesses/{businessId}/counters/sku`

| Field     | Type | Notes                                        |
| --------- | ---- | -------------------------------------------- |
| `current` | int  | Last issued sequence number. Starts at `0`. |

A `runTransaction` reads the counter, increments it, and writes
`Product.skuForSequence(current)` (`PRD-000001`, `PRD-000002`, …). Because the
sequence comes from a server-side transaction on a shared document, generated
SKUs are gapless per business and never depend on client time — the concern
raised in spec section 5.2.

### 7.2 `businesses/{businessId}/skuIndex/{skuKey}` and `barcodeIndex/{barcodeKey}`

| Field       | Type   | Notes                                            |
| ----------- | ------ | ------------------------------------------------ |
| `productId` | string | The product that currently owns this value.       |

The document **id** is the normalised value (`normalizeSku()` /
`normalizeBarcode()`), so "TOMATO-1" and "tomato-1" collide as intended.

A create or SKU/barcode change runs in a transaction:

1. read the claim document for the new key;
2. abort with `DuplicateSkuException` / `DuplicateBarcodeException` if it
   exists and points at a *different* product;
3. write the product, then create the new claim and delete the old one.

This gives the "This SKU is already in use." / "This barcode is already
registered." behaviour from spec section 15 at the data layer, independently
of any client-side check.

---

## 8. Role model and authorisation

`firestore.rules` resolves the caller's role for a `businessId` in this order:

1. `businesses/{businessId}/members/{uid}` if it exists (explicit membership);
2. otherwise `users/{uid}.businessId == businessId` → `users/{uid}.role`.

If neither matches, the caller has no role and every product/category rule
denies. This is what makes "never trust a `businessId` supplied by the client"
(spec section 22) enforceable.

### Permission matrix (implemented in the rules)

| Action                          | Owner | Admin | Manager | Staff |
| ------------------------------- | :---: | :---: | :-----: | :---: |
| View products / categories      |  ✓    |  ✓    |   ✓     |  ✓    |
| Create product                  |  ✓    |  ✓    |   ✓     |  ✗    |
| Edit product                    |  ✓    |  ✓    |   ✓     |  ✗    |
| Activate / deactivate product   |  ✓    |  ✓    |   ✓     |  ✗    |
| Manage categories               |  ✓    |  ✓    |   ✓     |  ✗    |
| Manage business, team, members  |  ✓    |  ✓    |   ✗     |  ✗    |
| Hard delete products/categories |  ✗    |  ✗    |   ✗     |  ✗    |

Spec section 23 marks Staff create/edit as "Optional". This implementation
takes the safe default: **Staff is read-only** until an explicit per-user
permission model exists. Changing that later only requires relaxing specific
role lists in `firestore.rules` and `UserRole`.

### Additional rule guarantees

* **No hard deletes.** `allow delete: if false` on products and categories, so
  historic sales can never lose their product record (spec section 9).
* **Audit fields are server-trusted.** `createdBy` must equal the caller on
  create, `updatedBy` must equal the caller on every write, and
  `createdAt`/`createdBy` are frozen on update (spec section 25).
* **Bounds are enforced server-side.** Lengths, numeric ranges, integer types,
  trimmed strings and `nameLower == name.lower()` are all validated, so client
  validation is a UX nicety rather than the security boundary (spec 15).
* **Tenant bootstrapping is not a hole.** A user may create
  `users/{uid}` with `role: owner` only for a business whose `ownerId` is their
  own uid. They cannot self-assign into someone else's business.
* **Storage mirrors Firestore.** `storage.rules` resolves the same role and
  restricts product images to members of that business, ≤ 5 MB and
  `image/*` content types (spec section 20).

---

## 9. Indexes

`firestore.indexes.json` is intentionally empty, per spec section 33
("Do not create indexes unnecessarily").

The only composite index the list query is expected to need is:

```text
products: categoryId ASC, isActive ASC, updatedAt DESC
```

plus single-field indexes, which Firestore creates automatically for
`isActive`, `categoryId`, `nameLower`, `skuLower`, `barcode`, `updatedAt` and
`nameTokens` (`nameTokens` needs the implicit array index for
`array-contains`).

**Do not hand-write indexes.** Run the query against the emulator or a real
project, follow the console link Firestore returns, and commit the generated
entry into `firestore.indexes.json`. This keeps the file limited to indexes an
actual query requires.

---

## 10. First-run bootstrap

There is no sign-up screen yet, so a fresh project needs one owner. Order
matters because the rules validate each step against the previous one.

1. Create the user in Firebase Authentication (console or emulator UI).
2. Create `businesses/{businessId}` with:
   `id = businessId`, `ownerId = <uid>`, `currency = 'KES'`, `isActive = true`,
   `createdAt`/`updatedAt` = server timestamp, `createdBy = <uid>`.
   The rules allow this because `ownerId` equals the caller.
3. Create `users/{uid}` with `uid`, `businessId`, the auth `email`,
   `displayName`, `role = 'owner'`, `isActive = true` and timestamps.
   The rules allow this because the business's `ownerId` is the caller.
4. Optionally seed `businesses/{businessId}/categories/*` and
   `businesses/{businessId}/products/*`.

Additional team members are provisioned by an owner/admin writing
`businesses/{businessId}/members/{uid}` and the matching `users/{uid}`.
Self-service joining is deliberately **not** possible in this phase.

---

## 11. Deliberate deviations from the spec text

| Spec wording                                   | Implemented as                                        | Why                                                                                          |
| ---------------------------------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `createdAt: Timestamp`, `id: string` on product | Same, plus `nameLower`, `nameTokens`, `skuLower`      | Firestore cannot search case-insensitively or on substrings; these fields make it possible.   |
| `categoryName: string \| null`                 | Kept, as an explicit denormalised snapshot            | Spec section 4 permits it "for convenience/performance if the implementation requires it".    |
| Staff may create/edit ("Optional")             | Staff is read-only                                    | Safe default until a per-user permission model exists; trivially relaxed later.               |
| "Efficient React state management" (spec 32)   | Flutter/Riverpod equivalent                           | The repository is a Flutter app, not a React app (spec section 34: adapt, do not replace).    |

---

## 12. Known limitations

* **Token list contents are not type-validated.** Rules can bound
  `nameTokens.size()` but cannot iterate it to assert every element is a
  string. Tokens are only ever generated by `buildNameTokens()`, and a
  malformed entry can at worst make a product unfindable — it cannot leak data.
* **Uniqueness claims are soft.** A caller with manage rights could delete a
  claim document directly. They already have full write access to the tenant's
  products, so this grants no extra privilege; it is noted for completeness.
* **`categoryName` is denormalised.** Renaming a category must fan out to its
  products. The category rename path owns that update; until it runs, list
  rendering falls back to `categoryId`.
* **Emulator rule coverage.** Rules are authored but not yet verified against
  the Firestore emulator; that verification lands with the Phase 6 test pass.
