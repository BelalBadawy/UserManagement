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
