# MamboPoint POS — Product Management

## 1. Project Overview

**Product:** MamboPoint POS
**Company:** Mama Mboga Point of Integration
**Feature:** Product Management
**Phase:** MVP / Initial Product Module
**Primary Backend:** Firebase

MamboPoint is a modern Point-of-Sale (POS) system designed to help small and growing businesses manage their daily retail operations efficiently.

The first feature to be developed is **Product Management**.

The Product Management module will provide business owners and authorized staff with a simple, professional, and reliable way to create, view, search, edit, organize, and manage products that will later be used throughout the MamboPoint POS.

The implementation should prioritize:

* Simplicity
* Speed
* Reliability
* Mobile responsiveness
* Clean user experience
* Data consistency
* Security
* Future scalability

The interface should feel like a **professional commercial POS product**, not an internal prototype.

---

# 2. Development Objective

Build a complete Product Management interface that allows an authorized MamboPoint user to manage the products sold by their business.

The module should support:

1. Creating products
2. Viewing products
3. Searching products
4. Filtering products
5. Editing products
6. Activating/deactivating products
7. Managing product categories
8. Managing pricing
9. Managing inventory-related product information
10. Maintaining product metadata
11. Validating product information
12. Persisting all product data securely in Firebase

The implementation should be designed so that the Product Management module can later integrate naturally with:

* Sales/POS
* Inventory
* Purchases
* Suppliers
* Customers
* Reports
* Payments
* Barcode scanning
* Business analytics

---

# 3. Product Management UX

## Design Principles

The interface should be:

* Modern
* Professional
* Trustworthy
* Clean
* Fast
* Easy for non-technical business owners
* Mobile-first/responsive
* Accessible
* Consistent

Avoid unnecessary complexity.

The user should be able to perform common product-management tasks with minimal clicks.

### Visual Direction

Use a professional SaaS/POS aesthetic.

Recommended characteristics:

* Clean dashboard layout
* Clear typography
* Consistent spacing
* Subtle borders
* Rounded cards where appropriate
* Clear primary actions
* Minimal visual clutter
* Professional tables
* Clear status indicators
* Meaningful empty states
* Confirmation dialogs for destructive actions
* Loading states
* Skeleton loaders where appropriate
* Toast notifications for successful operations

Do not make the interface overly colorful or playful.

The product should communicate **trust, stability, and business professionalism**.

---

# 4. Product Data Model

Products should be stored in Firebase Firestore.

Recommended collection:

```text
businesses/{businessId}/products/{productId}
```

This structure is preferred because MamboPoint is expected to support multiple businesses in the future.

Each product should contain fields similar to:

```javascript
{
  id: string,

  name: string,

  sku: string,

  barcode: string | null,

  categoryId: string | null,

  categoryName: string | null,

  description: string | null,

  unit: string,

  purchasePrice: number,

  sellingPrice: number,

  stockQuantity: number,

  lowStockThreshold: number,

  imageUrl: string | null,

  isActive: boolean,

  createdAt: Timestamp,

  updatedAt: Timestamp,

  createdBy: string,

  updatedBy: string
}
```

### Important

Do not duplicate data unnecessarily.

For example, `categoryId` should be the primary relationship to the category.

`categoryName` may be stored as a snapshot for convenience/performance if the implementation requires it, but the system should avoid creating inconsistent category data.

---

# 5. Product Fields

## 5.1 Product Name

Required.

Example:

```text
Tomatoes
```

Requirements:

* Required
* Minimum reasonable length
* Maximum reasonable length
* Trim whitespace
* Should not allow empty values
* Display prominently throughout the POS

---

## 5.2 SKU

SKU means Stock Keeping Unit.

Example:

```text
TOM-001
```

Requirements:

* Optional or automatically generated
* Must be unique within a business
* Should be searchable
* Should not contain unnecessary spaces

The implementation should allow the system to generate a SKU when the user does not provide one.

Example:

```text
PRD-000001
PRD-000002
PRD-000003
```

The exact generation strategy can be implemented cleanly without relying on client-side timestamps alone.

---

## 5.3 Barcode

Optional.

Examples:

```text
616110123456
```

The system should support barcode values because future versions of MamboPoint may support:

* Barcode scanners
* Mobile camera scanning
* Fast POS checkout

Barcode values should be searchable.

If a barcode is provided, it should be unique within the business.

---

## 5.4 Category

Products should belong to a category where appropriate.

Example categories:

```text
Vegetables
Fruits
Groceries
Beverages
Household
Personal Care
```

Categories should be stored separately.

Recommended structure:

```text
businesses/{businessId}/categories/{categoryId}
```

Category structure:

```javascript
{
  id: string,
  name: string,
  description: string | null,
  isActive: boolean,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

The Product Management interface should provide an easy way to select a category.

There should also be an option to create a category without forcing the user to leave the product creation workflow.

---

# 6. Unit of Measurement

Products may be sold using different units.

Examples:

```text
Piece
Kg
Gram
Litre
Bottle
Packet
Box
Dozen
Metre
```

The system should provide a predefined list of common units.

The architecture should allow additional units to be introduced later.

---

# 7. Pricing

Each product should support:

### Purchase Price

The price the business pays to acquire the product.

Example:

```text
KES 80
```

### Selling Price

The price charged to customers.

Example:

```text
KES 120
```

### Basic Validation

Selling price should not normally be lower than purchase price unless the user explicitly confirms or the business configuration allows it.

Do not silently prevent legitimate business scenarios such as:

* Discounts
* Loss leaders
* Clearance
* Promotional sales

The system should therefore warn rather than unnecessarily block the user.

---

# 8. Inventory Information

Although full Inventory Management is outside this phase, products should contain basic stock information.

Fields:

```text
Stock Quantity
Low Stock Threshold
```

Example:

```text
Stock Quantity: 45
Low Stock Threshold: 10
```

The Product Management UI should clearly indicate:

### In Stock

Normal stock level.

### Low Stock

Stock is at or below the configured threshold.

### Out of Stock

Stock is zero.

Inventory movements should **not** be implemented as arbitrary direct edits once the full inventory system exists.

For this initial POC, however, authorized users may be allowed to set an initial stock quantity when creating a product.

The architecture should leave room for future inventory transactions.

---

# 9. Product Status

Products should support:

```text
Active
Inactive
```

Active products are available for use in the POS.

Inactive products should remain in the database but should not normally appear in the active POS product selection.

Do not delete products unnecessarily.

Use deactivation/soft deletion where possible because historical sales may depend on product records.

---

# 10. Product List

The main Product Management page should display products in a professional table.

Recommended columns:

| Column        | Purpose                         |
| ------------- | ------------------------------- |
| Product       | Product name and optional image |
| SKU           | Product identifier              |
| Category      | Product category                |
| Selling Price | Current selling price           |
| Stock         | Current quantity                |
| Status        | Active/Inactive                 |
| Updated       | Last update time                |
| Actions       | Product actions                 |

On smaller screens, the table should become a responsive card/list representation rather than becoming unusable.

---

# 11. Product Search

Provide a prominent search field.

Users should be able to search by:

* Product name
* SKU
* Barcode

Example:

```text
Search products...
```

Search should feel immediate and responsive.

Do not require the user to press Enter for every search if the implementation can support efficient filtering.

For larger datasets, use an appropriate Firestore query strategy rather than loading the entire product collection unnecessarily.

---

# 12. Product Filtering

Provide filters such as:

### Category

```text
All Categories
Vegetables
Fruits
Groceries
...
```

### Status

```text
All
Active
Inactive
```

### Stock

```text
All
In Stock
Low Stock
Out of Stock
```

Filters should be combinable where practical.

Example:

```text
Category: Vegetables
Status: Active
Stock: Low Stock
```

---

# 13. Sorting

Allow users to sort products by useful fields such as:

* Name
* Selling price
* Stock
* Recently updated

Default sorting should be sensible for a POS environment, such as recently updated or product name.

---

# 14. Create Product

The primary action should be clearly visible:

```text
+ Add Product
```

The form should contain:

### Basic Information

* Product name
* SKU
* Barcode
* Category
* Description

### Pricing

* Purchase price
* Selling price

### Inventory

* Unit
* Initial stock quantity
* Low stock threshold

### Product Image

Optional.

### Status

Default:

```text
Active
```

---

# 15. Create Product Validation

Validate data before submission.

Examples:

### Product name

```text
Product name is required.
```

### Selling price

```text
Enter a valid selling price.
```

### Stock

```text
Stock quantity cannot be negative.
```

### SKU

```text
This SKU is already in use.
```

### Barcode

```text
This barcode is already registered.
```

Validation should occur both:

1. Client-side for good UX
2. Server/security layer where appropriate for data integrity

Never rely exclusively on client-side validation.

---

# 16. Edit Product

Users should be able to edit existing products.

Editable fields should include:

* Name
* SKU
* Barcode
* Category
* Description
* Purchase price
* Selling price
* Unit
* Low stock threshold
* Image
* Status

Editing should update:

```text
updatedAt
updatedBy
```

The system should preserve:

```text
createdAt
createdBy
```

---

# 17. Deactivating a Product

When a user attempts to deactivate a product, display a confirmation dialog.

Example:

```text
Deactivate Product?

"Tomatoes" will no longer appear as an active product in the POS.

[Cancel] [Deactivate]
```

Do not permanently delete the product.

Historical records may depend on the product.

---

# 18. Product Details

Clicking a product should open a product details view.

Display:

### Product Information

* Name
* SKU
* Barcode
* Category
* Description

### Pricing

* Purchase price
* Selling price
* Estimated margin

### Inventory

* Current stock
* Unit
* Low-stock threshold
* Stock status

### Metadata

* Created date
* Last updated
* Created by
* Updated by

The page should provide:

```text
Edit Product
Deactivate Product
```

where appropriate.

---

# 19. Estimated Margin

Display a simple estimated margin:

```text
Selling Price - Purchase Price
```

Example:

```text
Purchase Price: KES 80
Selling Price: KES 120

Estimated Margin: KES 40
```

Optionally display margin percentage:

```text
33.3%
```

The implementation must clearly distinguish this from actual profit because operational costs, discounts, taxes, wastage, etc. may affect actual profitability.

---

# 20. Product Images

Product images should be optional.

Firebase Storage can be used for image storage.

Recommended architecture:

```text
Firebase Storage
        ↓
Product image
        ↓
URL stored in Firestore
```

Images should:

* Be compressed/resized where practical
* Have reasonable file-size limits
* Display a default placeholder when unavailable
* Fail gracefully if an image cannot load

Do not make image upload mandatory for the MVP.

---

# 21. Firebase Architecture

Use Firebase as the primary backend.

Recommended services:

### Firebase Authentication

Used to identify the logged-in user.

### Cloud Firestore

Used for:

* Products
* Categories
* Business information
* Product metadata

### Firebase Storage

Used for:

* Product images

### Firebase Security Rules

Used to ensure users cannot access or modify businesses they are not authorized to access.

---

# 22. Multi-Business Data Isolation

The system should be designed with multi-tenancy in mind.

Example:

```text
businesses/
    businessA/
        products/
        categories/

    businessB/
        products/
        categories/
```

A user should only access data belonging to businesses they are authorized to access.

Never trust a `businessId` supplied by the client without validating authorization through Firebase security rules and/or trusted backend logic.

---

# 23. Authentication & Authorization

The Product Management module should assume that the user is authenticated.

At minimum, support roles such as:

```text
Owner
Admin
Manager
Staff
```

Example permissions:

| Action             | Owner | Admin | Manager |    Staff |
| ------------------ | ----: | ----: | ------: | -------: |
| View products      |     ✓ |     ✓ |       ✓ |        ✓ |
| Create product     |     ✓ |     ✓ |       ✓ | Optional |
| Edit product       |     ✓ |     ✓ |       ✓ | Optional |
| Deactivate product |     ✓ |     ✓ |       ✓ |       No |
| Manage categories  |     ✓ |     ✓ |       ✓ |       No |

The exact permission model can evolve later.

Implement authorization in a way that can be extended rather than hardcoding permissions throughout UI components.

---

# 24. Firestore Security

Security rules should prevent unauthorized access.

Conceptually:

```text
Authenticated user
        ↓
Determine business membership
        ↓
Verify role/permission
        ↓
Allow product operation
```

Do not rely only on hidden UI buttons for security.

For example:

```text
Hiding "Delete" from Staff
```

is not sufficient.

Firestore rules must independently prevent unauthorized operations.

---

# 25. Auditability

Product changes should be traceable.

At minimum store:

```text
createdAt
createdBy
updatedAt
updatedBy
```

Future versions may introduce a dedicated audit collection:

```text
businesses/{businessId}/auditLogs/{logId}
```

Potential events:

```text
PRODUCT_CREATED
PRODUCT_UPDATED
PRODUCT_DEACTIVATED
PRODUCT_REACTIVATED
PRICE_CHANGED
```

Do not over-engineer the audit system in this first phase unless it is easy to implement cleanly.

---

# 26. Loading States

The application must clearly communicate when data is loading.

Use:

* Skeleton loaders
* Button loading states
* Disabled submit buttons during requests
* Progress indicators for image uploads

Avoid displaying blank screens while Firebase operations are running.

---

# 27. Error Handling

Errors should be understandable to normal business users.

Avoid exposing raw Firebase errors such as:

```text
FirebaseError: PERMISSION_DENIED
```

Instead display:

```text
We couldn't save this product.
Please check your connection and try again.
```

For permission problems:

```text
You don't have permission to perform this action.
```

Log technical details appropriately for developers.

---

# 28. Empty States

When no products exist:

```text
No products yet

Add your first product to start building your product catalogue.

[+ Add Product]
```

When a search produces no results:

```text
No products found

Try a different product name, SKU, or barcode.
```

Empty states should be intentional and useful.

---

# 29. Confirmation & Feedback

After successfully creating a product:

```text
Product created successfully.
```

After editing:

```text
Product updated successfully.
```

After deactivation:

```text
Product deactivated.
```

Use toast notifications or another consistent feedback mechanism.

Do not rely on browser alerts.

---

# 30. Responsive Design

The application must work well on:

* Desktop
* Laptop
* Tablet
* Android phones
* Small mobile screens

Mobile users should be able to:

* Search products
* Add products
* Edit products
* View stock
* View prices
* Change product status

without needing desktop-only interactions.

---

# 31. Accessibility

Use:

* Proper form labels
* Keyboard navigation
* Adequate contrast
* Visible focus states
* Accessible buttons
* Accessible dialogs
* Meaningful error messages

Do not use color alone to communicate product status.

For example:

```text
Low Stock
```

should have both visual styling and readable text.

---

# 32. Performance

Avoid loading unnecessary data.

The Product Management page should be designed to scale from:

```text
10 products
```

to:

```text
1,000+
```

without requiring a complete architectural rewrite.

Use:

* Pagination where appropriate
* Firestore queries
* Indexed fields where required
* Efficient React state management
* Image optimization
* Debounced search where appropriate

Avoid fetching an entire collection on every UI interaction.

---

# 33. Firestore Indexing

If compound queries are introduced, create the necessary Firestore indexes.

Potential query combinations may include:

```text
businessId + categoryId
businessId + isActive
businessId + categoryId + isActive
```

Do not create indexes unnecessarily.

Let Firebase identify required indexes during development and add only those needed by actual queries.

---

# 34. Suggested Application Structure

Use a modular architecture.

Example:

```text
src/
├── features/
│   └── products/
│       ├── components/
│       │   ├── ProductTable
│       │   ├── ProductForm
│       │   ├── ProductCard
│       │   ├── ProductFilters
│       │   ├── ProductSearch
│       │   ├── ProductDetails
│       │   └── ProductStatusBadge
│       │
│       ├── hooks/
│       │   └── useProducts
│       │
│       ├── services/
│       │   └── productService
│       │
│       ├── types/
│       │   └── product.types
│       │
│       └── validation/
│           └── productSchema
│
├── services/
│   ├── firebase/
│   └── storage/
│
└── shared/
    ├── components/
    ├── hooks/
    └── utils/
```

Adapt the structure to the existing project rather than blindly replacing the current architecture.

---

# 35. Component Reusability

Build reusable components where appropriate.

Examples:

```text
DataTable
SearchInput
FilterDropdown
StatusBadge
ConfirmationDialog
CurrencyInput
ImageUploader
EmptyState
LoadingState
```

Do not create abstractions merely for the sake of abstraction.

Prefer simple, understandable code.

---

# 36. Currency

The primary currency for the initial MamboPoint implementation should be:

```text
KES — Kenyan Shilling
```

Display prices consistently:

```text
KES 1,250
```

or:

```text
KSh 1,250
```

Choose one format and use it consistently throughout the application.

Do not hardcode currency formatting in individual components.

Create a reusable currency formatter.

---

# 37. Product Management MVP Scope

### Must Have

* Product list
* Add product
* Edit product
* View product details
* Search
* Category
* SKU
* Barcode
* Purchase price
* Selling price
* Unit
* Stock quantity
* Low-stock threshold
* Active/inactive status
* Firebase persistence
* Firebase authentication
* Firebase security rules
* Responsive UI
* Validation
* Error handling
* Loading states
* Empty states

### Should Have

* Product image
* Estimated margin
* Filtering
* Sorting
* Automatic SKU generation
* Quick category creation
* Product status management

### Later

* Barcode scanning
* Bulk import
* CSV/Excel import
* Bulk product editing
* Product variants
* Multiple pricing levels
* Discounts
* Tax configuration
* Stock movement history
* Supplier linkage
* Purchase orders
* Inventory adjustments
* Product bundles
* Product expiry dates
* Batch/lot tracking

---

# 38. Out of Scope for This Phase

Do not implement the following unless required to make Product Management functional:

* Full POS checkout
* Customer management
* Supplier management
* Sales management
* Payment processing
* M-Pesa integration
* Expense management
* Accounting
* Full inventory management
* Reports
* Staff payroll
* Loyalty programs
* Tax filing
* Advanced analytics

The goal is to produce a polished and production-quality **Product Management module**, not an entire POS system.

---

# 39. UX Flow

## View Products

```text
Dashboard
   ↓
Products
   ↓
Product Management
   ↓
Product List
```

## Create Product

```text
Product Management
   ↓
+ Add Product
   ↓
Product Form
   ↓
Validate
   ↓
Save to Firestore
   ↓
Success notification
   ↓
Product List
```

## Edit Product

```text
Product List
   ↓
Select Product
   ↓
Edit
   ↓
Update Form
   ↓
Validate
   ↓
Update Firestore
   ↓
Success notification
```

## Deactivate Product

```text
Product List
   ↓
Product Actions
   ↓
Deactivate
   ↓
Confirmation
   ↓
Update isActive = false
   ↓
Success notification
```

---

# 40. Development Requirements for Cline

Cline should act as a senior full-stack engineer when implementing this specification.

Before making major changes:

1. Inspect the existing project structure.
2. Identify the existing framework and conventions.
3. Identify the Firebase configuration.
4. Identify existing authentication.
5. Identify existing UI/component libraries.
6. Identify existing styling conventions.
7. Reuse existing infrastructure where appropriate.
8. Do not unnecessarily rewrite working parts of the application.

Before implementation, provide a short implementation plan.

Then implement incrementally.

---

# 41. Important Development Rules

### Do not over-engineer

The first objective is a working, polished Product Management module.

### Do not create unnecessary dependencies

Prefer existing project dependencies where possible.

### Do not expose secrets

Never place Firebase Admin credentials, service-account keys, API secrets, or other private credentials in client-side code.

### Do not bypass Firebase security

Do not use insecure Firestore rules simply to make development easier.

### Do not hardcode business data

Categories and products must come from Firebase rather than being permanently embedded in the UI.

### Do not destroy existing functionality

If the project already contains working features, integrate with them.

### Maintain type safety

If the project uses TypeScript, use proper types/interfaces for:

* Product
* Category
* User
* Business
* Product form data
* Product filters

---

# 42. Testing Requirements

Test at minimum:

### Product Creation

* Valid product
* Missing product name
* Invalid price
* Negative stock
* Duplicate SKU
* Duplicate barcode

### Product Editing

* Update product name
* Update prices
* Update category
* Update stock threshold
* Activate/deactivate

### Search

* Product name
* SKU
* Barcode
* No results

### Filtering

* Category
* Status
* Stock status

### Permissions

Verify that unauthorized users cannot:

* Create products
* Edit products
* Deactivate products
* Access another business's products

### Responsive Testing

Test:

* Desktop
* Tablet
* Android mobile

---

# 43. Definition of Done

The Product Management feature is considered complete when:

* [ ] Products can be created
* [ ] Products are persisted in Firestore
* [ ] Products can be viewed
* [ ] Products can be searched
* [ ] Products can be filtered
* [ ] Products can be edited
* [ ] Products can be deactivated
* [ ] Categories work correctly
* [ ] SKU validation works
* [ ] Barcode validation works
* [ ] Prices are validated
* [ ] Stock information works
* [ ] Product images work if implemented
* [ ] Loading states exist
* [ ] Empty states exist
* [ ] Error handling exists
* [ ] Success feedback exists
* [ ] Firebase security rules protect business data
* [ ] Authentication is respected
* [ ] UI is responsive
* [ ] No secrets are exposed
* [ ] Existing application functionality remains intact
* [ ] Code is modular and maintainable
* [ ] The implementation is ready for future POS/inventory integration

---

# 44. Future Integration Contract

The Product Management module should expose clean interfaces for future modules.

Future POS checkout should be able to retrieve:

```text
productId
name
sku
barcode
sellingPrice
unit
isActive
```

Future Inventory should be able to work with:

```text
productId
stockQuantity
unit
lowStockThreshold
```

Future Purchasing should be able to use:

```text
productId
purchasePrice
supplierId
```

Future Reporting should be able to reference:

```text
productId
categoryId
sellingPrice
purchasePrice
```

The Product Management implementation should therefore avoid tightly coupling product data to a particular UI component.

---

# 45. Final Product Vision

MamboPoint should feel like a POS system built for real businesses.

The Product Management module should be:

**Simple enough for a small shop owner.**

**Professional enough for a growing business.**

**Structured enough to support enterprise-level expansion later.**

The initial implementation should focus on getting the fundamentals right:

```text
Clean UX
    +
Reliable Firebase data
    +
Strong validation
    +
Secure access
    +
Responsive design
    +
Maintainable architecture
    =
MamboPoint Product Management
```

Build the foundation correctly now so that Sales, Inventory, Purchasing, Customers, Payments, and Reporting can be added without having to rebuild the Product Management system later.
