# Task Plan: Form Validation, Password Strength Meter & Toastr System

## Goal
Add inline validation rules to all frontend forms (blocking submission of invalid inputs), integrate a real-time password strength meter that rejects weak passwords, and configure a centralized toast notification context provider for message delivery.

## Current Phase
Phase 1: Custom Toast Notification System

## Phases

### Phase 1: Custom Toast Notification System
- [x] Create `toast.tsx` provider, context, and custom hook under `src/components/ui`
- [x] Wrap the application in `ToastProvider` inside `App.tsx`
- **Status:** complete

### Phase 2: Form Validations, Password Strength Meter & Page Refactoring
- [x] Update `Register.tsx` (inline field validations, password strength meter, disabled submit button, toast integration)
- [x] Update `Login.tsx` (real-time validations, disabled submit button, toast integration)
- [x] Update `ConfirmEmail.tsx` (inline email input validation, toast integration)
- [x] Update `ResendConfirmation.tsx` (email validation, toast integration)
- [x] Update `ConfirmEmailChange.tsx` (toast integration)
- **Status:** complete

### Phase 3: Documentation & Verification
- [x] Update the BRD/Source of Truth in `docs/source-of-truth.md`
- [x] Run `npm run build` and check for compile/TS errors
- **Status:** complete

## Notes
- Toasts must support success, error, warning, and info states with rich icons.
- Buttons must remain disabled while validation constraints are failing or when password strength is "Weak".

## Forgot & Reset Password Flow Phases

### Phase 4: Backend Changes and Tests
- [x] Update `UserService.ForgotPasswordAsync` in `UMS.Infrastructure` to use `ClientSettings:BaseUrl` and include plain-text fallback URL
- [x] Update unit tests in `UserServiceTests.cs` to verify client-side redirection URL format and fallback text in the email message body
- [x] Run backend unit tests to verify changes pass successfully

### Phase 5: Frontend Changes
- [x] Register new client-side routes for `/forgot-password` and `/reset-password` in `App.tsx`
- [x] Implement `<ForgotPassword />` page in `src/pages/ForgotPassword.tsx` with email validation, API submission, and in-place success card
- [x] Implement `<ResetPassword />` page in `src/pages/ResetPassword.tsx` with URL parameters parsing, password strength validation, API submission, and automatic redirect countdown

### Phase 6: Documentation & Verification
- [x] Update `docs/source-of-truth.md` with Forgot & Reset Password flow specs and use cases
- [x] Perform end-to-end verification of the forgot/reset password flow manually

## Claims, Route Protection & Redirects Flow Phases

### Phase 7: Session Management & Protection Guard
- [x] Create a robust client JWT decoder utility supporting XML Schema URI parsing and array normalization
- [x] Implement `<AuthProvider>` and `useAuth` hook managing token storage and automated token refreshes
- [x] Create `<ProtectedRoute>` wrapper restricting access based on token presence and user roles
- [x] Create `<PublicOnlyRoute>` wrapper protecting Login/Register pages from already authenticated users
- [x] Implement Shadcn UI-based workspaces for `<AdminHome />` and `<PublicHome />`
- [x] Hook up `<Login />` and `<App />` routes with new protection wrappers
- [x] Update `docs/source-of-truth.md` and `docs/task_plan.md` documentation
- **Status:** complete

## Two-Factor Authentication (2FA) Flow Phases

### Phase 8: Two-Factor Authentication (2FA) Setup & Challenge Login
- [x] Create a dedicated profile page (`Profile.tsx`) containing user details and 2FA settings
- [x] Integrate local `qrcode.react` package for client-side QR generation
- [x] Implement the setup wizard modal with Shadcn/ui-styled dialog to step through Setup, Verification, and Recovery codes
- [x] Integrate 2FA verification panel into `Login.tsx` to challenge users with enabled 2FA
- [x] Verify client builds and runs without compilation errors
- **Status:** complete

## Claims-Based Authorization & Layout Navigation Flow Phases

### Phase 9: Admin Layout, Dynamic Menu & Claim Route Guard
- [x] Extend `AuthContext` to expose `hasPermission` check
- [x] Extend `ProtectedRoute` to support `allowedPermissions` checks with toast redirect
- [x] Create `AdminLayout` wrapper with dynamic header/footer and mobile sidebar menu
- [x] Create mock `UserManagement` with claim-guarded buttons
- [x] Register routes under `AdminLayout` with respective allowed permissions
- **Status:** complete

## Admin User & Role Management Flow Phases

### Phase 10: Admin User Management (Phase 1)
- [x] Implement Users API client mappings in `api-client.ts`
- [x] Implement query searching & dropdown filters
- [x] Implement pagination & sorting using `@tanstack/react-table`
- [x] Guard actions (Edit, Delete, Lock/Unlock) using `hasPermission` helper
- [x] Build Create / Edit `UserFormSheet` side-panel
- [x] Integrate Password Strength Meter in user creation
- [x] Build Lock/Unlock and Delete confirmation dialogs
- [x] Update `docs/source-of-truth.md` and verify clean build
- **Status:** complete

### Phase 11: Admin Role Management (Phase 2)
- [x] Implement Role list & CRUD components
- [x] Build Role Create / Edit `Sheet`
- [x] Build Role Delete confirmation dialog
- **Status:** complete

### Phase 12: Claims/Permissions Matrix UI (Phase 3)
- [x] Build Accordion-grouped permissions matrix under Role Edit flow
- [x] Implement "Select All / Deselect All" global options
- [x] Implement category-level toggles and Switches/Checkboxes
- **Status:** complete

## Product Categories Management Flow Phases

### Phase 13: Product Categories Management
- [x] Modify `GetCategoriesPagedQuery.cs` to add `IsActive` & `RowVersion` and implement status filtering
- [x] Implement frontend centralized client helper `categories-api.ts`
- [x] Build `CategoriesManagement.tsx` component with `@tanstack/react-table`
- [x] Register `/admin/categories` route in `App.tsx` and menu links in `AdminLayout.tsx`
- [x] Verify client build and backend tests compile and pass cleanly
- **Status:** complete

## User Activation & Lockout Toggles Flow Phases

### Phase 14: User Activation & Lockout Toggles
- [x] Add `IsLocked` property to backend `UserResponse` DTO and project in queries
- [x] Add `isLocked` property to frontend `UserResponse` model
- [x] Implement separate toggle controls for Lock/Unlock (lockout) and Activate/Deactivate (status) in the user list UI
- [x] Configure distinctive Shadcn Badges for Active, Inactive, and Locked states
- [x] Verify client production build and all test suites pass successfully
- **Status:** complete

## Enhanced User Management Filtering and Pagination Flow Phases

### Phase 15: Enhanced User Management Filtering and Pagination
- [x] Add status (`IsActive`), lockout (`IsLocked`), and role ID (`RoleId`) filtering parameters to backend query DTO `PagedFilterRequest`
- [x] Apply server-side filters dynamically in `UserService.GetUsersPagedQueryAsync`
- [x] Install official Shadcn `select` and `pagination` components
- [x] Upgrade frontend paginated list to support Status, Lockout, and Assigned Role filters in `UserManagement.tsx`
- [x] Replace pagination controls in frontend with official Shadcn Pagination primitives displaying first/last page, ellipses, and prev/next buttons
- [x] Synchronize search query, current page, and filter selections reactively with URL parameters
- [x] Verify backend tests and frontend client build compile and pass cleanly
- **Status:** complete
