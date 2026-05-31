# UMS Application: Source of Truth & BRD

## 1. Project Overview
The User Management System (UMS) is a secure, enterprise-grade web application designed to govern identity, permissions, and profile administration. This document serves as the absolute Source of Truth and Business Requirements Document (BRD) for the application logic, user experiences, and integration behaviors.

## 2. Architecture & Layouts
- **Backend Architecture**: Built with .NET Core using the Clean Architecture pattern (Domain, Application, Infrastructure, API layers) and mediator pattern for request handling.
- **Frontend Architecture**: Built as a single-page application using React, TypeScript, Vite, and Tailwind CSS.
- **Navigation & Layout Routing**:
  - The application divides routes into layout containers.
  - Authentication-related pages (Login, Register, Email Confirmations) are encapsulated within a unified layout structure (`LoginLayout`) which provides standard containment and spacing, while rendering pages dynamically.

## 3. User Flows & Use Cases

### 3.1 User Registration & Email Confirmation
Handles the onboarding of new users into the system with self-registration and mandatory email verification.

* **Happy Path**:
  1. **User Onboarding**: The user visits the registration page and provides their Full Name, Email address, Phone Number, and Password. They agree to the privacy policy and submit the form.
  2. **Link Dispatch**: The backend registers the user in an inactive/unconfirmed state. It generates a secure verification token and constructs a callback link targeting the React client page `/confirm-email`. The system dispatches this link to the user's email address.
  3. **Auto-Submit on Load**: When the user clicks the link in their inbox, they are directed to the client-side `/confirm-email` landing page. The client automatically extracts the `userId` and `token` parameters from the query string and submits them to the backend API.
  4. **Verification Success**: The backend validates the parameters and confirms the email. The client displays a premium success screen (with a checkmark and confirmation message) and automatically redirects the user to the login screen after 3 seconds.

* **Alternative Paths & Error States**:
  - **Invalid/Missing Parameters**: If the user visits the `/confirm-email` page without a `userId` or `token`, the page immediately transitions to a verification failure state.
  - **Expired/Invalid Verification Token**: If the token is invalid or expired, the backend returns a failed API response. The client transition to an error screen showing the failure reason.
  - **Embedded Link Resend**: If verification fails, the error view displays an inline resend form. The user can enter their email address and click "Resend" to dispatch a new verification link to their inbox without leaving the page.

### 3.2 User Login
Authenticates users and provides session tokens.

* **Happy Path**:
  1. The user inputs their registered email and password.
  2. The backend validates credentials and checks if the email is confirmed.
  3. If validated, the backend returns a successful response containing a JWT token and a refresh token.
  4. The client saves the tokens to local storage and redirects the user to `/admin`.

* **Alternative Paths & Error States (Unconfirmed Email)**:
  1. The user enters valid credentials, but their email is unconfirmed.
  2. The backend intercepts the login check and returns a failed response wrapper with a status code of `403` (Forbidden) and a message indicating the email is not confirmed.
  3. The React client intercepts this `403` status code, shows the error message, and dynamically appends a call-to-action link: *"Click here to resend verification link"*.
  4. Clicking the link redirects the user to the `/resend-confirmation` landing page where they can request a new verification link.

### 3.3 Email Change Confirmation
Governs secure email updates for existing users.

* **Happy Path**:
  1. A logged-in user requests an email change.
  2. The system sends a confirmation link to their new email address, targeting the client path `/confirm-email-change`.
  3. Clicking the link directs the user to the client-side `/confirm-email-change` landing page, which auto-submits the parameters to the backend.
  4. Upon validation, the user's email and username are updated, and they are redirected to the login page after 3 seconds.

### 3.4 Forgot Password & Password Reset
Governs self-service password recovery for users who have forgotten their credentials.

* **Happy Path (Forgot Password Request)**:
  1. The user navigates to the login page and clicks the "Forgot Password?" link, which routes them to `/forgot-password` on the client.
  2. The user inputs their registered email address and clicks "Send Reset Link".
  3. The React client validates that the email address is structured correctly and sends a `POST` request to `/api/v1/account/forgot-password?email=...`.
  4. To prevent user enumeration, the backend always responds with a success message: `"If the email is registered, you will receive an email shortly."`
  5. The client intercepts the success response and replaces the email form in-place with a clean success screen displaying the exact success message returned from the API ("If the email is registered, you will receive an email shortly.").
  6. The backend dispatches a secure password reset token link targeting the React client's `/reset-password` path (e.g. `{clientBaseUrl}/reset-password?email={email}&token={token}`) and includes a plain-text fallback URL block in the email message body.

* **Happy Path (Password Reset)**:
  1. The user clicks the link in their email inbox, directing them to `/reset-password` on the client.
  2. The React client checks the query string parameters. If `email` or `token` is missing, it renders an "Invalid Link" error screen.
  3. If both parameters are present, the client displays a form showing their email address (disabled field) and inputs for New Password and Confirm Password.
  4. The client calculates password strength in real-time. If the strength is evaluated as "Weak" (less than 8 characters or failing complexity tests), or if the confirmation password does not match, the submit button remains disabled.
  5. Once a strong matching password is typed, the user submits the form. The client issues a `POST` request to `/api/v1/account/reset-password` with the email, token, new password, and confirmation password.
  6. The backend validates the parameters and token, resets the password, updates the user's security stamp, and returns a success response wrapper.
  7. The client displays a success screen, triggers a success toast, and starts a 3-second countdown timer that automatically redirects the user to the `/login` route.

---

## 4. API Contracts & Integrations

### 4.1 Authentication Endpoints

#### `POST /api/v1/users/register`
- **Access**: Anonymous (`AllowAnonymous`)
- **Purpose**: Registers a new user.
- **Request Payload**:
  - `fullName` (string): Full name of the user.
  - `email` (string): User's registration email.
  - `phoneNumber` (string): User's phone number.
  - `password` (string): User's password.
  - `confirmPassword` (string): Confirmation matching password.
  - `autoConfirmEmail` (boolean): Set to `false` for self-registration to require confirmation.
  - `activateUser` (boolean): Set to `true` to mark account active once verified.
- **Response Wrapper**: Returns a standard `ResponseWrapper` indicating registration status.

#### `POST /api/v1/account/login`
- **Access**: Anonymous
- **Purpose**: Validates credentials and returns session tokens.
- **Request Payload**:
  - `email` (string): User email.
  - `password` (string): User password.
- **Response Wrapper**:
  - **Success (200 OK)**: Returns the JWT access token and refresh token in the `data` object.
  - **Unconfirmed Email (403 Forbidden)**: Returns `isSuccessful: false`, message `"Email not confirmed."`, and `statusCode: 403`.

#### `POST /api/v1/account/confirm-email`
- **Access**: Anonymous
- **Purpose**: Validates confirmation token and confirms user's email.
- **Request Payload**:
  - `userId` (integer): ID of the user.
  - `token` (string): The verification token generated by the Identity system.
- **Response Wrapper**: Standard `ResponseWrapper` with success/failure status.

#### `POST /api/v1/account/confirm-email-change`
- **Access**: Anonymous
- **Purpose**: Validates and completes email update requests.
- **Request Payload**:
  - `userId` (integer): User ID.
  - `newEmail` (string): The target email address.
  - `token` (string): Secure change token.
- **Response Wrapper**: Standard `ResponseWrapper` confirming update.

#### `POST /api/v1/account/resend-confirmation-email`
- **Access**: Anonymous
- **Purpose**: Dispatches a new email verification token.
- **Request Payload**:
  - `email` (string): Registered email address.
- **Response Wrapper**: Returns standard success/fail wrapper.

#### `POST /api/v1/account/forgot-password`
- **Access**: Anonymous (`AllowAnonymous`)
- **Purpose**: Generates a password reset token and sends a reset link to the user's email.
- **Request Parameters**:
  - `email` (string, query parameter): User's registered email address.
- **Response Wrapper**: Always returns a standard successful `ResponseWrapper` (to prevent user enumeration).

#### `POST /api/v1/account/reset-password`
- **Access**: Anonymous
- **Purpose**: Resets the password using the token received in the email.
- **Request Payload**:
  - `email` (string): User's email address.
  - `token` (string): The reset token.
  - `password` (string): The new password.
  - `confirmPassword` (string): Confirmation matching the new password.
- **Response Wrapper**: Returns standard success/fail wrapper.

---

## 5. UI/UX Safeguards & Notifications

### 5.1 Inline Form Validation & Submit Restrictions
To ensure clean data entry and reduce unnecessary API calls, all frontend forms enforce real-time inline validations. The submit buttons remain disabled (`disabled={isLoading || !isFormValid}`) until all validation criteria are met.

*   **Registration Form**:
    *   **Full Name**: Required, minimum of 3 characters.
    *   **Email Address**: Required, must match standard email pattern (`/^[^\s@]+@[^\s@]+\.[^\s@]+$/`).
    *   **Phone Number**: Required, must be a numeric string between 7 and 15 characters, allowing digits, spaces, hyphens, and a leading plus sign (`/^[0-9+\s-]{7,15}$/`).
    *   **Password**: Must not be evaluated as "Weak" by the strength meter.
    *   **Confirm Password**: Must exactly match the password.
    *   **Privacy Agreement**: Checkbox must be checked.
*   **Login Form**:
    *   **Email Address**: Required, must match standard email pattern.
    *   **Password**: Required (non-empty).
*   **Resend Confirmation Form**:
    *   **Email Address**: Required, must match standard email pattern.
*   **Confirm Email Form (Inline Resend)**:
    *   **Email Address**: Required, must match standard email pattern.

### 5.2 Real-time Password Strength Meter
The registration screen incorporates a password complexity analysis component that grades the input password in real-time.
*   **Grading Score**: Points are accumulated (0 to 5) based on the presence of:
    1.  Minimum length of 8 characters.
    2.  At least one lowercase letter.
    3.  At least one uppercase letter.
    4.  At least one numerical digit.
    5.  At least one special/symbol character (`@$!%*?&`).
*   **Categories & Submission Rules**:
    *   **Weak**: If the password length is less than 8, or the complexity score is 2 or lower. **Passwords in this category are strictly blocked and the Submit/Sign Up button remains locked.**
    *   **Medium**: Password length is at least 8, and the complexity score is 3 or 4. (Accepted for registration).
    *   **Strong**: Password length is at least 8, and the complexity score is 5. (Accepted for registration).

### 5.3 Centralized Glassmorphic Toast Notification System (Toastr)
A custom, lightweight, glassmorphic toast notification component and context provider have been introduced to manage user-facing alert bubbles globally.
*   **No Third-Party Dependencies**: Implemented using a custom React Context provider (`ToastProvider`) and a hook (`useToast`).
*   **Visual Style**: Glassmorphic background blur (`backdrop-blur-md bg-white/70`), subtle borders, dynamic slide-in/fade-in animations, and absolute positioning in the top-right corner (`fixed top-5 right-5 z-[9999]`).
*   **Alert Status Types**:
    *   `success`: Displays an emerald checkmark circle for successful operations.
    *   `error`: Displays a rose cross circle for failed requests or inputs.
    *   `warning`: Displays an amber alert triangle for warning states.
    *   `info`: Displays a blue information circle.
*   **Automatic Dismissal**: Toast cards auto-fade-out and dismiss after 5 seconds, or can be dismissed manually by clicking them.

---

## 6. Data Models & State Management
- **Token Management**: JWT and refresh tokens are cached and persisted locally in the client browser's `localStorage` space.
- **Request State**: The client uses local component states (`isLoading`, `errorMsg`, `successMsg`, `status`) to render interactive progress states, loading loops, and error overlays dynamically.

---

## 7. Configuration & Environment
- **Backend appsettings.json**:
  - `ClientSettings:BaseUrl` (string): Configures the base address of the React client application (e.g. `http://localhost:5173`) to build verification callback links pointing directly to client routes.
- **Frontend Environment**:
  - `VITE_API_BASE_URL` (string): Environment option containing the target base address of the API gateway (defaults to `https://localhost:7122`).

---

## 8. Development Log / Changelog
- **2026-05-29**: Implemented public user self-registration and email verification flow.
  - **Backend**: Bound `ClientSettings` configs, set `StatusCode = 403` on unconfirmed email validation checks, and updated `UserService` to build links resolving to client-side paths.
  - **Frontend**: Established centralized API client, updated registration form, created `/confirm-email`, `/resend-confirmation`, and `/confirm-email-change` landing pages, and intercepted unconfirmed email errors (`403`) to prompt resending links.
  - **Form Validation, Password Strength & Toastr**: Installed client-side validations to block invalid form submissions, integrated a real-time password strength meter rejecting weak passwords, and built a custom, glassmorphic toast notification system (`useToast`) across all account/verification pages.
- **2026-05-30**: Implemented Forgot Password and Password Reset (4k Password) flow.
  - **Backend**: Modified `UserService.ForgotPasswordAsync` to generate reset links resolving to client-side routes using `_clientSettings.BaseUrl` and added a plain-text fallback URL block in the email message body. Updated `UserServiceTests` to verify client URL redirection format.
  - **Frontend**: Registered `/forgot-password` and `/reset-password` routes in `App.tsx`.
  - **Forgot Password Page**: Implemented a glassmorphic form for forgot password requests, displaying an in-place success view upon successful submission to prevent enumeration.
  - **Reset Password Page**: Implemented a form to parse query string parameters, validate password strength in real-time, block weak passwords, submit the reset token, and trigger an auto-redirect countdown to the login screen on success.

---

## 9. Client-Side Session & Route Protection

### 9.1 JWT Claim Decoding & Normalization
To prevent dependencies on external token libraries, the client uses a native decoding mechanism (`src/lib/jwt.ts`) that splits the token parts, decodes the Base64URL payload via `window.atob`, and maps .NET claim formats to clean TypeScript fields:
- **Roles Normalization**: Looks up `"http://schemas.microsoft.com/ws/2008/06/identity/claims/role"`. If the user has a single role, it parses as a string; if multiple, it parses as an array. The utility normalizes both cases by wrapping single strings into a string array.
- **Permissions Normalization**: Similar normalization logic is applied to the `"permission"` claim key to return arrays consistently.
- **Expiration Check**: Validates token expiration (`exp` claim) locally against the current system time using a 30-second clock skew buffer.

### 9.2 Auth Context & Token Refresh
The React application's session state is managed via `<AuthProvider>` and the `useAuth` custom hook:
- **Initial Load**: On mount, the provider checks the active token. If expired, it attempts a silent refresh request to `POST /api/v1/account/refresh-token` with the stored access token and refresh token. If the refresh request fails or tokens are missing/invalid, the session is cleared.
- **Token Refresh**: Provides automatic check/refresh logic triggered on page loads and transitions, preventing session dropouts.
- **Login/Logout**: Updates both context states and `localStorage` keys immediately.

### 9.3 Protected vs Public-Only Routes
- **Protected Routes (`ProtectedRoute`)**: Restricts access to authenticated users. Supports optional role verification (e.g., `/admin` requires the "Admin" role). Unauthenticated users are redirected to `/login`, and authenticated users without required roles are redirected back to the public homepage `/`.
- **Public-Only Routes (`PublicOnlyRoute`)**: Restricts access to guests. If an authenticated user attempts to visit auth pages like `/login`, `/register`, or verification routes, they are automatically intercepted and routed to their respective homepage (Admin to `/admin`, others to `/`).
- **Public Home (`/`)**: Open anonymously. Displays generic greeting for guests, or username/logout button if authenticated.

