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

### 3.5 Admin User Management (Phase 1)
Governs identity search, list traversal, status locks, details updates, and initial registration privileges.

* **List & Traversal Flow**:
  1. The Admin navigates to `/admin/users`. The route is guarded at the routing tier to only allow users possessing `Permission.Identity.Users.Read`.
  2. On load, the page parses URL query parameters (`page`, `search`, `active`, `locked`, `role`) to initialize search and filtering states reactively.
  3. The page presents an advanced filter bar including:
     - **Status Filter**: Options for *All*, *Active*, and *Inactive*, mapping to server-side `IsActive` filtering.
     - **Lockout Filter**: Options for *All*, *Locked*, and *Unlocked*, mapping to server-side `IsLocked` filtering.
     - **Assigned Role Filter**: A dropdown dynamically populated by fetching roles from `GET api/v1/roles/all`, filtering users by role ID.
  4. The page dispatches a paginated request `GET /api/v1/users/paged-list` with `pageNumber`, `pageSize`, `sortBy`, `sortDirection`, `searchTerm`, `isActive`, `isLocked`, and `roleId`. Changing any filter or search term automatically resets pagination back to Page 1.
  5. The footer renders a full numbered pagination structure using official Shadcn Pagination components (`PaginationContent`, `PaginationItem`, `PaginationLink`, `PaginationEllipsis`) presenting the first page, last page, current page, one page on either side of the current page, and ellipses for gaps, with Previous/Next buttons disabled appropriately at boundaries.
  6. Parallel roles queries (`GET /api/v1/users/roles/{userId}`) are fired to fetch role mappings for rendering under the "Assigned Roles" column.
  7. Column headers are interactive; clicking them switches sorting keys or directions dynamically, triggering a page refresh from the API.

* **Guarded Action Operations**:
  1. **Lock/Unlock (Lockout)**: Governs security lockouts. Checked by `Permission.Identity.Users.Lock` / `Permission.Identity.Users.Unlock` claims. Action buttons show/hide based on the backend-tracked `IsLocked` (or `LockoutEnd`) status. Locking a user sets their lockout expiry date to a 1,000-year offset (`DateTimeOffset.UtcNow.AddYears(1000)`) to prevent database type overflows, invalidates active refresh tokens (by setting their expiry to yesterday), and regenerates the user's **Security Stamp** (`UpdateSecurityStampAsync`) to instantly invalidate and reject any currently active access tokens (JWTs) mid-session. Unlocking resets the lockout date and resets the failed access count. Toggling triggers a confirmation modal and dispatches `PUT /api/v1/users/lock-user` or `PUT /api/v1/users/unlock-user`.
  2. **Activate/Deactivate (Activation)**: Governs account status. Checked by `Permission.Identity.Users.Update`. Action buttons show/hide based on the `IsActive` flag. Deactivating a user flags the account as inactive in the database, preventing generic session logins. Toggling triggers a confirmation modal and dispatches `PUT /api/v1/users/change-status`.
  3. **Create User**: Checked by `Permission.Identity.Users.Create`. Opens a side-panel `Sheet` allowing form entry. Evaluates password strength in real-time, blocking submission of weak passwords. Auto-assigns roles. Dispatches to `POST /api/v1/users/register`.
  4. **Edit Details & Roles**: Checked by `Permission.Identity.Users.Update`. Loads existing credentials into `Sheet`. Admin edits Name, Phone Number, and toggles Assigned Roles. Clicking save dispatches a profile update `PUT /api/v1/users/update` followed by role assignment changes `PUT /api/v1/users/user-roles`.
  5. **Delete User**: Checked by `Permission.Identity.Users.Delete`. Deletion logic is verified and simulated client-side.

### 3.6 Admin Role Management (Phase 2)
Governs custom role classifications configuration, security level naming, descriptions, and dynamic authorization checks.

* **List & Traversal Flow**:
  1. The Admin navigates to `/admin/roles`. The route is guarded at the routing tier to only allow users possessing `Permission.Identity.Roles.Read`.
  2. On load, the page dispatches a request `GET /api/v1/roles/all` to fetch the complete list of system roles.
  3. The page displays roles (ID, Role Name, Description) in a clean tabular view. Users can filter roles locally via an interactive search bar.

* **Guarded Action Operations**:
  1. **Create Role**: Checked by `Permission.Identity.Roles.Create`. Activates a side-panel `Sheet` containing Name and Description inputs. Submitting dispatches `POST /api/v1/roles`.
  2. **Edit Role**: Checked by `Permission.Identity.Roles.Update`. Opens the `Sheet` populated with the role data. Submitting dispatches `PUT /api/v1/roles` (basic details updates).
  3. **Delete Role**: Checked by `Permission.Identity.Roles.Delete`. Displays a confirmation modal `Dialog`. On confirmation, dispatches `DELETE /api/v1/roles/{roleId}` to wipe out the role.

### 3.7 Claims & Permissions Management (Phase 3)
Governs assigning granular access permission claims (such as `Permission.Identity.Users.Read`) to security roles.

* **Permissions Matrix Load & Render Flow**:
  1. Integrated inside the `RoleFormSheet` container.
  2. On sheet activation:
     - In **Create Mode**: Calls `GET /api/v1/roles/permissions/{firstRoleId}` (representing any valid system role) to dynamically load the system permissions metadata schema. All checkboxes default to unchecked (`selected: false`).
     - In **Edit Mode**: Calls `GET /api/v1/roles/permissions/{roleId}`. The backend returns all system permissions with their active state checked (`selected: true`) or unchecked.
  3. The client parses permission claim names (e.g. `Permission.Identity.Users.Read`) into `AppService` ("Identity"), `AppFeature` ("Users"), and `AppAction` ("Read").
  4. Renders categories dynamically grouped by Service and Feature inside interactive expandable Accordion sections.

* **Bulk Toggle & Matrix Controls**:
  1. **Global Toggle**: A "Select All" master checkbox at the top to select or deselect all system permissions with one click. Supports indeterminate check states.
  2. **Category Toggle**: Individual category headers have checkboxes to toggle all child actions (e.g. check all *Identity -> Users* permissions at once).
  3. **Individual Toggle**: Each permission item displays its read label and action name with a toggle checkbox.

* **Save & Update Flow**:
  1. When clicking "Save Role & Permissions", the client saves core metadata, then updates permissions.
  2. The client filters active checked claims and posts the array to `PUT /api/v1/roles/update-permissions` containing the `RoleId` and `RoleClaims` list.
  3. The backend calculates additions/removals within a SQL transaction, ensuring atomic updates.

### 3.8 Product Categories Management
Governs the catalog organization, hierarchy, sorting, and active status configurations of product categories.

* **List & Traversal Flow**:
  1. The Admin navigates to `/admin/categories`. The route is guarded at the routing tier to only allow users possessing `Permission.Product.Categories.Read`.
  2. On load, the page dispatches a paginated request `GET /api/v1/categories/paged-list` with `pageNumber`, `pageSize`, `sortBy`, `sortOrder`, `searchQuery`, and `isActive` (if filtering).
  3. The page displays categories (ID, Name, Slug, Sort Order, Status) in a Tanstack Table with full pagination support.
  4. Header columns are interactive; clicking them triggers sorting dynamically. A search input debounces and filters by name or slug. A status dropdown filters by Active, Inactive, or All.

* **Guarded Action Operations**:
  1. **Create Category**: Checked by `Permission.Product.Categories.Create`. Activates a side-panel `Sheet` containing Name, Slug (auto-generated from Name but editable), Parent Category (dynamically fetched dropdown of parent categories), Sort Order, and IsActive toggle. Submitting dispatches `POST /api/v1/categories`.
  2. **Edit Category**: Checked by `Permission.Product.Categories.Update`. Opens the `Sheet` populated with the category's current data. Submitting dispatches `PUT /api/v1/categories` along with the `rowVersion` for concurrency control.
  3. **Delete Category**: Checked by `Permission.Product.Categories.Delete`. Displays a confirmation modal `Dialog`. On confirmation, dispatches `DELETE /api/v1/categories/{id}`.

### 3.9 Audit Logs Management
Governs tracking database events, inspecting mutated properties, identifying remote IP addresses, and actors.

* **List & Traversal Flow**:
  1. The Admin navigates to `/admin/audit-logs`. The route is guarded at the routing tier to only allow users possessing `Permission.Identity.AuditTrails.Read`.
  2. On load, the page dispatches a paginated request `GET /api/v1/audit-logs` with `pageNumber`, `pageSize`, `sortBy`, `sortDirection`, and `searchTerm`.
  3. The page displays log events (Log ID, Affected Table, Event Type, Actor Email, IP Address, Timestamp) in a structured table.
  4. Users can sort by ID, Affected Table, Event Type, or Timestamp, and filter logs dynamically using the real-time search bar.
  
* **Guarded Action Operations**:
  1. **Inspection Sheet**: Clicking "View Details" opens a side-panel `<Sheet>` showing advanced details: affected columns list (as labels), and an interactive `<EntityDiffViewer>` component containing:
     - **Visual Diff Table**: Performs key-by-key parsing and comparisons of before/after JSON values dynamically, highlighting changed values, added values, and deleted values in clean, high-contrast colorized formatting. It supports inline copy-to-clipboard, property search filtering, and a toggle to only display modified properties.
     - **Raw JSON View**: Offers side-by-side formatted JSON blocks for developers who need to review or copy the entire raw data structures.

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

### 4.2 Product Categories Endpoints

#### `GET /api/v1/categories/paged-list`
- **Access**: Authenticated, requires `Permission.Product.Categories.Read`
- **Purpose**: Retrieves a paged list of product categories based on search query, sorting, and status filters.
- **Request Parameters**:
  - `pageNumber` (integer, query parameter): Page index.
  - `pageSize` (integer, query parameter): Page capacity.
  - `sortBy` (string, query parameter): Field name to sort by (e.g. `name`, `slug`, `sortOrder`).
  - `sortOrder` (string, query parameter): Sorting direction (`asc` or `desc`).
  - `searchQuery` (string, query parameter): Search query to filter categories by name or slug.
  - `isActive` (boolean, optional query parameter): Filter categories by status.
- **Response Wrapper**: Returns a standard `ResponseWrapper` containing the paginated data list.

#### `GET /api/v1/categories/{id}`
- **Access**: Authenticated, requires `Permission.Product.Categories.Read`
- **Purpose**: Retrieves category details by ID.
- **Response Wrapper**: Returns category entity.

#### `POST /api/v1/categories`
- **Access**: Authenticated, requires `Permission.Product.Categories.Create`
- **Purpose**: Creates a new product category.
- **Request Payload**:
  - `name` (string): Unique category name.
  - `slug` (string): Auto-generated or custom editable slug.
  - `parentId` (integer, optional): Parent category identifier.
  - `sortOrder` (integer): Sorting sequence rank.
  - `isActive` (boolean): Active status flag.
- **Response Wrapper**: Standard `ResponseWrapper`.

#### `PUT /api/v1/categories`
- **Access**: Authenticated, requires `Permission.Product.Categories.Update`
- **Purpose**: Modifies an existing category.
- **Request Payload**:
  - `id` (integer): Category identifier.
  - `name` (string): Updated name.
  - `slug` (string): Updated slug.
  - `parentId` (integer, optional): Parent category ID.
  - `sortOrder` (integer): Sorting position.
  - `isActive` (boolean): Active status flag.
  - `rowVersion` (string): Optimistic concurrency token check.
- **Response Wrapper**: Standard `ResponseWrapper`.

#### `DELETE /api/v1/categories/{id}`
- **Access**: Authenticated, requires `Permission.Product.Categories.Delete`
- **Purpose**: Deletes category by ID.
- **Response Wrapper**: Standard `ResponseWrapper`.

### 4.3 Audit Logs Endpoints

#### `GET /api/v1/audit-logs`
- **Access**: Authenticated, requires `Permission.Identity.AuditTrails.Read`
- **Purpose**: Retrieves a paged, sorted, and searchable list of audit trails.
- **Request Parameters**:
  - `pageNumber` (integer, query parameter): Page index.
  - `pageSize` (integer, query parameter): Page capacity.
  - `sortBy` (string, query parameter): Field name to sort by (`tablename`, `type`, `datetime`, `id`).
  - `sortDirection` (string, query parameter): Sort direction (`asc` or `desc`).
  - `searchTerm` (string, query parameter): Search query to filter audit logs by table name, IP address, or user email.
- **Response Wrapper**: Returns a standard `ResponseWrapper` containing the paginated data list of `AuditTrailResponse`.

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

---

## 10. Two-Factor Authentication (2FA)

UMS integrates Time-Based One-Time Password (TOTP) multi-factor authentication. Users can self-manage 2FA from their profile settings, and the system enforces a code challenge on subsequent logins.

### 10.1 User Profile Page & 2FA Management Flow
Authenticated users can navigate to `/profile` (accessible from both Admin and Public Home pages) to view and manage their account details:
- **Profile Detail Display**: Renders account statistics, active status, roles, permissions, and phone number.
- **Enable 2FA Setup Dialog**:
  1. The user clicks "Setup 2FA". The client calls `POST api/v1/users/setup-2fa` to generate an authenticator key and `CodeQR` otpauth URI.
  2. The dialog displays a QR code (rendered client-side securely via `qrcode.react`) and the raw secret key.
  3. The user scans the QR code into their authenticator application and clicks "Next".
  4. The client prompts the user to enter the temporary 6-digit TOTP code. It posts the code to `PUT api/v1/users/enable-2fa`.
  5. On verification success, 10 recovery codes are generated and shown. The user must save them before completing setup.
- **Disable 2FA Dialog**:
  - To turn off 2FA, the user clicks "Disable 2FA", enters their account password (and optional authenticator code), and submits a request to `PUT api/v1/users/disable-2fa` to remove protection.

### 10.2 2FA Login Challenge Flow
When a user with 2FA enabled logs in with valid credentials:
1. The login call to `POST api/v1/account/login` responds successfully indicating `{ requiresTwoFactor: true, twoFactorChallengeToken: "..." }` instead of yielding a session token.
2. The client intercepts this flag, transitions the login form view to the 2FA Verification panel, and stores the challenge token in state.
3. The user must input the 6-digit TOTP code from their authenticator app, or a backup 8-character recovery code.
4. On submission, the client calls `POST api/v1/account/login-2fa` passing the code and challenge token.
5. If the code verifies, the API returns the final JWT and refresh token, and the client logs the user in.

### 10.3 2FA API Contracts

#### `POST /api/v1/users/setup-2fa`
- **Access**: Authenticated
- **Purpose**: Generates key and QR code URI for 2FA.
- **Response**: `{ keySecret: string, codeQR: string }`

#### `PUT /api/v1/users/enable-2fa`
- **Access**: Authenticated
- **Purpose**: Validates code, enables 2FA, and returns 10 backup codes.
- **Request**: `{ code: string }`
- **Response**: `string[]` (list of 10 recovery codes)

#### `PUT /api/v1/users/disable-2fa`
- **Access**: Authenticated
- **Purpose**: Disables 2FA using account password and optional code.
- **Request**: `{ password: string, code?: string }`
- **Response**: Standard `ResponseWrapper`

#### `POST /api/v1/account/login-2fa`
- **Access**: Anonymous
- **Purpose**: Completes 2FA login challenge.
- **Request**: `{ twoFactorChallengeToken: string, code: string }`
- **Response**: Standard Token Response `{ token: string, refreshToken: string, ... }`

---

## 12. Claims-Based Dynamic Navigation & Route Protection

UMS implements a granular claims-based client-side permission mechanism:

### 12.1 Dynamic Layout Navigation Menu
The `<AdminLayout />` wrapper provides a unified navigation header and footer extracted from the design template:
- **Desktop Header Menu**: Dynamically evaluates the user's session claims from the token and renders navigation tabs (e.g. *Users Management*, *Roles Management*) only if the user possesses the matching read permission (e.g. `Permission.Identity.Users.Read`).
- **Responsive Mobile Drawer**: A slide-out panel (simulating Sheet behavior) containing the same dynamic navigation list and logout trigger.
- **Account Dropdown**: A dropdown menu displaying user session details (email, profile links, logout trigger).

### 12.2 Route-Level claims authorization (`allowedPermissions`)
The `<ProtectedRoute />` guard was extended to accept an optional `allowedPermissions` array parameter:
- **Authorization Verification**: Intercepts routing, extracts the user's claims array from the context state, and checks if the user possesses at least one of the required permission strings.
- **Access Violation Redirect**: If the permission check fails, the guard intercepts execution, prompts a global toast alert warning (*"Access Denied: You do not have permission to access this resource."*), and redirects the user back to the default home screen `/`.

### 12.3 Action-Level authorization (`hasPermission`)
The `useAuth()` context hook provides a `hasPermission(permissionName: string)` helper:
- **Button Hiding/Locking**: Elements (such as *Create User*, *Edit*, and *Delete* buttons) check the helper inline and remain hidden or disabled if the user lacks the required permission claim (e.g. `Permission.Identity.Users.Create`).

---

## 13. Changelog Updates
- **2026-05-31**: Implemented Two-Factor Authentication (2FA) client integration.
  - **Frontend Page**: Created `/profile` page with account details and interactive 2FA setup/disable wizards using Shadcn/ui Dialog and Card styling. Used `qrcode.react` for local browser-side QR rendering.
  - **Login Integration**: Added 2FA code verification panel to `Login.tsx` that intercepts 2FA requirements and completes the auth flow using challenge tokens.
- **2026-05-31 (Late)**: Implemented Claims-Based Route Protection & Dynamic Admin Layout Menu.
  - **Admin Layout**: Created `<AdminLayout />` wrapping children in a common header/footer featuring a dynamic header menu, responsive mobile sheet, and profile dropdown menu.
  - **Route Guard**: Extended `<ProtectedRoute />` to support `allowedPermissions` checks with automated redirect and toast alerts on access violation.
  - **Action Guard**: Exposed `hasPermission` helper from `useAuth` hook to block unauthorized button clicks and hides/reveals actions dynamically (Create, Edit, Delete).
  - **Mock Page**: Created `/admin/users` view to test user administration actions and permission checks.
- **2026-05-31 (Night)**: Implemented Product Categories Management Module.
  - **Backend**: Updated `GetCategoriesPagedQuery` query model to integrate server-side pagination, sorting, search, and dynamic status filters (`IsActive`).
  - **Frontend API**: Added centralized `categories-api.ts` file handling CRUD operations, lists, and filtering query mapping.
  - **UI Views**: Built `/admin/categories` using Tanstack Table with full inline search, sorting, status dropdown, delete warning confirmation dialogs, and a responsive category creation/edit `CategoryFormSheet` featuring automatic slugification.
  - **Navigation**: Registered claim-guarded routes in `App.tsx` and dynamically included menu option in `AdminLayout.tsx` using permission checks.
- **2026-05-31 (Late Night)**: Separated User Lockout (Lock/Unlock) and Activation (Activate/Deactivate) flows.
  - **Backend**: Added `IsLocked` property to `UserResponse` DTO and mapped it using the Identity lockout expiry date check in user query handlers.
  - **Frontend API**: Updated client-side `UserResponse` model interface to track `isLocked`.
  - **UI Page**: Updated actions column to present separate lockout (Lock/Unlock) toggles and status (Activate/Deactivate) toggles. Configured custom visual status indicators for Active (default), Inactive (secondary/grey), and Locked (warning/orange) badges. Added activation confirmation dialogs and wired them up.
  - **Fixes**: Fixed API test email sink to support retrieving tokens mapped as `token` parameter.
  - **Verification**: Confirmed all 470 unit/integration tests pass, and verified a clean production build compilation.
- **2026-05-31 (End of Day)**: Enhanced User Management Filtering and Pagination.
  - **Backend**: Updated `PagedFilterRequest` to include nullable properties `IsLocked` and `RoleId`. Modified `UserService` to inject `IApplicationDbContext`, applying server-side filters for `IsActive`, `IsLocked` (comparing with `UtcNow`), and `RoleId` (joining via `ApplicationUserRole`) inside `GetUsersPagedQueryAsync`.
  - **Unit Tests**: Updated `UserServiceTests` and `UserServiceAuthTests` to mock and inject `IApplicationDbContext` into `UserService`.
  - **Frontend UI/UX**: Installed official Shadcn Select and Pagination components. Implemented advanced filter bar containing Status, Lockout, and Assigned Role selectors in `UserManagement.tsx`. Integrated full numbered pagination displaying first/last pages, ellipses, and Previous/Next buttons.
  - **URL Synchronization**: Configured reactive URL state syncing for filters, search, and page variables with page reset logic on filter updates.
  - **Verification**: Verified zero errors on client build `npm run build` and all backend test suites.
- **2026-06-01**: Implemented Backend and Frontend Audit Trails.
  - **Backend**: Added `IpAddress` column to `AuditTrail` domain model, updated `ApplicationDbContext` to capture IP address and ignore changes to `AuditTrail` itself. Enabled auditing globally via config (`"EnableAuditLog": true`).
  - **API**: Registered the `Read Audit Trails` permission claim. Created `GetAuditTrailsPagedQuery` in Application and `AuditTrailService` in Infrastructure joining the user table to display email. Mapped API endpoint `/api/v1/audit-logs`.
  - **Frontend**: Created client-side API helper `audit-logs-api.ts`. Integrated "Audit Logs" option in `AdminLayout.tsx` and mapped `/admin/audit-logs` route in `App.tsx` guarded by `Permission.Identity.AuditTrails.Read`. Built the `AuditLogsManagement.tsx` page showcasing paginated logs, search/sort, and a JSON detail diff view panel.
  - **Verification**: Generated and ran EF migration `AddAuditTrailIpAddress`, ran backend test suites (469 tests passed), and verified a clean frontend compilation (`npm run build`).
- **2026-06-01 (Late)**: Implemented Visual Entity Comparison Diff for Audit Logs.
  - **Reusable Component**: Created `<EntityDiffViewer />` in `src/components/EntityDiffViewer.tsx` that dynamically computes modifications (added, deleted, modified, unchanged) from raw JSON values and shows them in an interactive table with copy actions, text search, and toggle filters.
  - **Page Integration**: Integrated the diff visualizer into `AuditLogsManagement.tsx` details sheet to replace the raw `<pre>` JSON blocks.
  - **Documentation**: Updated tasks in `docs/task_plan.md` and specs in `docs/source-of-truth.md`.
- **2026-06-01 (End of Day)**: Enhanced User Lockout Security.
  - **Security Stamp Invalidation**: Updated `UserService.LockUserAsync` to call `_userManager.UpdateSecurityStampAsync(user)` during lockouts, ensuring any currently active JWT tokens are instantly rejected.
  - **Safe Date Constraint**: Changed lockout end date to `DateTimeOffset.UtcNow.AddYears(1000)` to bypass SQL Server MaxValue conversion/overflow bugs.
  - **Testing**: Updated Mock assertions in `UserServiceTests.cs` and verified all backend unit tests pass cleanly.
  - **Documentation**: Updated `docs/task_plan.md` and `docs/source-of-truth.md` specifications.






