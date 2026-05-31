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

