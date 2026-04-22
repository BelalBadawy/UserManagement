# 🔍 UMS Solution — Strict Test Coverage Audit

> **Audit Date:** 2026-04-22 | **Auditor:** Senior .NET Test Architect (AI)
> **Standard:** ZERO-TOLERANCE — every endpoint, handler, and service method must have at least one test.

---

## 📊 1. COVERAGE SUMMARY

| Category | Total | Tested | Missing | Coverage % |
|---|---|---|---|---|
| **API Endpoints** | 27 | 2 | 25 | **7.4%** |
| **Command/Query Handlers** | 30 | 1 | 29 | **3.3%** |
| **Service Methods (public)** | 25 | 0 | 25 | **0%** |
| **Domain/Business Logic Methods** | 6 | 0 | 6 | **0%** |
| **OVERALL** | **88** | **3** | **85** | **3.4%** ❌ |

> [!CAUTION]
> **Overall coverage is 3.4%.** This is catastrophically below the 90% minimum threshold. The project has **85 untested units** and is a **CRITICAL PRODUCTION RISK**.

---

## ❌ 2. MISSING TESTS — COMPLETE LIST

### 🔴 ACCOUNT ENDPOINTS (4 missing)

| Type | Name | File |
|---|---|---|
| Endpoint | `POST /api/v1/account/login` | `AccountEndpoints.cs` |
| Endpoint | `POST /api/v1/account/refresh-token` | `AccountEndpoints.cs` |
| Endpoint | `POST /api/v1/account/forgot-password` | `AccountEndpoints.cs` |
| Endpoint | `POST /api/v1/account/reset-password` | `AccountEndpoints.cs` |

### 🔴 CATEGORY ENDPOINTS (5 missing — 2 exist)

| Type | Name | File |
|---|---|---|
| Endpoint | `GET /api/v1/categories/paged` | `CategoryEndpoints.cs` |
| Endpoint | `GET /api/v1/categories/for-list` | `CategoryEndpoints.cs` |
| Endpoint | `POST /api/v1/categories/` | `CategoryEndpoints.cs` |
| Endpoint | `PUT /api/v1/categories/` | `CategoryEndpoints.cs` |
| Endpoint | `DELETE /api/v1/categories/{id}` | `CategoryEndpoints.cs` |

### 🔴 ROLE ENDPOINTS (7 missing)

| Type | Name | File |
|---|---|---|
| Endpoint | `POST /api/v1/roles/` | `RoleEndpoints.cs` |
| Endpoint | `GET /api/v1/roles/all` | `RoleEndpoints.cs` |
| Endpoint | `PUT /api/v1/roles/` | `RoleEndpoints.cs` |
| Endpoint | `GET /api/v1/roles/{roleId}` | `RoleEndpoints.cs` |
| Endpoint | `DELETE /api/v1/roles/{roleId}` | `RoleEndpoints.cs` |
| Endpoint | `GET /api/v1/roles/permissions/{roleId}` | `RoleEndpoints.cs` |
| Endpoint | `PUT /api/v1/roles/update-permissions` | `RoleEndpoints.cs` |

### 🔴 USER ENDPOINTS (9 missing)

| Type | Name | File |
|---|---|---|
| Endpoint | `GET /api/v1/users/{userId}` | `UserEndpoints.cs` |
| Endpoint | `GET /api/v1/users/all` | `UserEndpoints.cs` |
| Endpoint | `GET /api/v1/users/paged-list` | `UserEndpoints.cs` |
| Endpoint | `PUT /api/v1/users/update` | `UserEndpoints.cs` |
| Endpoint | `PUT /api/v1/users/change-password` | `UserEndpoints.cs` |
| Endpoint | `PUT /api/v1/users/change-status` | `UserEndpoints.cs` |
| Endpoint | `PUT /api/v1/users/user-roles` | `UserEndpoints.cs` |
| Endpoint | `GET /api/v1/users/roles/{userId}` | `UserEndpoints.cs` |
| Endpoint | `POST /api/v1/users/register` | `UserEndpoints.cs` |

---

### 🔴 CATEGORY COMMAND HANDLERS (3 missing)

| Type | Name | File |
|---|---|---|
| Handler | `CreateCategoryCommandHandler.Handle` | `CreateCategoryCommand.cs` |
| Handler | `UpdateCategoryCommandHandler.Handle` | `UpdateCategoryCommand.cs` |
| Handler | `DeleteCategoryCommandHandler.Handle` | `DeleteCategoryCommand.cs` |

### 🔴 CATEGORY QUERY HANDLERS (7 missing)

| Type | Name | File |
|---|---|---|
| Handler | `GetAllCategoriesQueryHandler.Handle` | `GetAllCategoriesQuery.cs` |
| Handler | `GetCategoriesPagedQueryHandler.Handle` | `GetCategoriesPagedQuery.cs` |
| Handler | `GetAllCategoriesForListQueryHandler.Handle` | `GetAllCategoriesForListQuery.cs` |
| Handler | `GetCategoryByIdQueryHandler.Handle` | `GetCategoryByIdQuery.cs` |
| Handler | `GetAllCategoriesAdminQueryHandler.Handle` | `GetAllCategoriesAdminQuery.cs` |
| Handler | `GetCategoriesPagedAdminQueryHandler.Handle` | `GetCategoriesPagedAdminQuery.cs` |
| Handler | `GetCategoryByIdAdminQueryHandler.Handle` | `GetCategoryByIdAdmin.cs` |

### 🔴 ROLE COMMAND HANDLERS (4 missing)

| Type | Name | File |
|---|---|---|
| Handler | `CreateRoleCommandHandler.Handle` | `CreateRoleCommand.cs` |
| Handler | `UpdateRoleCommandHandler.Handle` | `UpdateRoleCommand.cs` |
| Handler | `DeleteRoleCommandHandler.Handle` | `DeleteRoleCommand.cs` |
| Handler | `UpdateRolePermissionsCommandHandler.Handle` | `UpdateRolePermissionsCommand.cs` |

### 🔴 ROLE QUERY HANDLERS (3 missing)

| Type | Name | File |
|---|---|---|
| Handler | `GetRolesQueryHandler.Handle` | `GetRolesQuery.cs` |
| Handler | `GetRoleByIdQueryHandler.Handle` | `GetRoleByIdQuery.cs` |
| Handler | `GetPermissionsQueryHandler.Handle` | `GetPermissionsQuery.cs` |

### 🔴 USER COMMAND HANDLERS (6 missing)

| Type | Name | File |
|---|---|---|
| Handler | `UpdateUserCommandHandler.Handle` | `UpdateUserCommand.cs` |
| Handler | `ChangeUserPasswordCommandHandler.Handle` | `ChangeUserPasswordCommand.cs` |
| Handler | `ChangeUserStatusCommandHandler.Handle` | `ChangeUserStatusCommand.cs` |
| Handler | `ForgotPasswordCommandHandler.Handle` | `ForgotPasswordCommand.cs` |
| Handler | `ResetPasswordCommandHandler.Handle` | `ResetPasswordCommand.cs` |
| Handler | `UpdateUserRolesCommandHandler.Handle` | `UpdateUserRolesCommand.cs` |

### 🔴 USER QUERY HANDLERS (4 missing)

| Type | Name | File |
|---|---|---|
| Handler | `GetAllUsersQueryHandler.Handle` | `GetAllUsersQuery.cs` |
| Handler | `GetUserByIdQueryHandler.Handle` | `GetUserByIdQuery.cs` |
| Handler | `GetUsersPagedQueryHandler.Handle` | `GetUsersPagedQuery.cs` |
| Handler | `GetUserRolesQueryHandler.Handle` | `GetUserRolesQuery.cs` |

### 🔴 TOKEN QUERY HANDLERS (2 missing)

| Type | Name | File |
|---|---|---|
| Handler | `GetTokenQueryHandler.Handle` | `GetTokenQuery.cs` |
| Handler | `GetRefreshTokenQueryHandler.Handle` | `GetRefreshTokenQuery.cs` |

---

### 🔴 SERVICE METHODS — UserService (11 missing)

| Type | Name | File |
|---|---|---|
| Service | `UserService.RegisterUserAsync` | `UserService.cs` |
| Service | `UserService.UpdateUserAsync` | `UserService.cs` |
| Service | `UserService.GetUserByIdAsync` | `UserService.cs` |
| Service | `UserService.GetAllUsersAsync` | `UserService.cs` |
| Service | `UserService.GetUsersPagedQueryAsync` | `UserService.cs` |
| Service | `UserService.ChangeUserPasswordAsync` | `UserService.cs` |
| Service | `UserService.ChangeUserStatusAsync` | `UserService.cs` |
| Service | `UserService.GetUserRolesAsync` | `UserService.cs` |
| Service | `UserService.UpdateUserRolesAsync` | `UserService.cs` |
| Service | `UserService.ForgotPasswordAsync` | `UserService.cs` |
| Service | `UserService.ResetPasswordAsync` | `UserService.cs` |

### 🔴 SERVICE METHODS — RoleService (7 missing)

| Type | Name | File |
|---|---|---|
| Service | `RoleService.CreateRoleAsync` | `RoleService.cs` |
| Service | `RoleService.DeleteRoleAsync` | `RoleService.cs` |
| Service | `RoleService.GetPermissionsAsync` | `RoleService.cs` |
| Service | `RoleService.GetRoleByIdAsync` | `RoleService.cs` |
| Service | `RoleService.GetRolesAsync` | `RoleService.cs` |
| Service | `RoleService.UpdateRoleAsync` | `RoleService.cs` |
| Service | `RoleService.UpdateRolePermissionsAsync` | `RoleService.cs` |

### 🔴 SERVICE METHODS — TokenService (2 missing)

| Type | Name | File |
|---|---|---|
| Service | `TokenService.GetTokenAsync` | `TokenService.cs` |
| Service | `TokenService.GetRefreshTokenAsync` | `TokenService.cs` |

### 🔴 SERVICE METHODS — LocalFileStorageService (2 missing)

| Type | Name | File |
|---|---|---|
| Service | `LocalFileStorageService.SaveFileAsync` | `LocalFileStorageService.cs` |
| Service | `LocalFileStorageService.DeleteFile` | `LocalFileStorageService.cs` |

### 🔴 SERVICE METHODS — DistributedCacheService (3 missing)

| Type | Name | File |
|---|---|---|
| Service | `DistributedCacheService.TryGet<T>` | `DistributedCacheService.cs` |
| Service | `DistributedCacheService.Set<T>` | `DistributedCacheService.cs` |
| Service | `DistributedCacheService.Remove` | `DistributedCacheService.cs` |

### 🔴 BUSINESS LOGIC — CategoryWriteGuards (4 methods, 6 branches missing)

| Type | Name | File |
|---|---|---|
| Logic | `CategoryWriteGuards.NormalizeKey` | `CategoryWriteGuards.cs` |
| Logic | `CategoryWriteGuards.ValidateParentAssignmentAsync` | `CategoryWriteGuards.cs` |
| Logic | `CategoryWriteGuards.IsUniqueConstraintViolation` | `CategoryWriteGuards.cs` |
| Logic | `CategoryWriteGuards.GetUniqueConstraintMessage` | `CategoryWriteGuards.cs` |

---

## ⚠️ 3. LOW QUALITY TESTS

| File | Test | Issue |
|---|---|---|
| `UMS.Tests/UnitTest1.cs` | `Test1()` | No behaviour tested. `Assert.Pass()` is a placeholder — not a real test. |
| `UMS.IntegrationTests/UnitTest1.cs` | `Test1()` | Same. Placeholder file only. Must be deleted or replaced. |

> [!WARNING]
> Both `UnitTest1.cs` files violate the **"real behaviour only"** test quality rule. They inflate the test count without providing any value.

The two existing real tests (`UserRegistrationCommandTests`) are **VALID** — they use proper AAA structure, mock the service, and assert on `IsSuccessful` and `Messages`. However:

- They only cover the **happy path** and **email-already-exists** scenario.
- Missing edge cases: `null` request, empty fields, password mismatch, invalid phone number.

The two existing integration tests (`CategoryEndpointsTests`) are **VALID** structurally, but:
- Only cover `GET /categories` (happy path) and `GET /categories/{id}` (404 path).
- Missing: auth-protected endpoints, POST/PUT/DELETE, paging, filters.

---

## 🔁 4. DUPLICATE / REDUNDANT TESTS

No duplicate tests detected. The test suite is too sparse for duplicates to emerge.

---

## 🧪 5. SUGGESTED TESTS TO ADD

### 5.1 Category Command Handlers (Unit Tests)

**Class:** `CreateCategoryCommandHandlerTests`
```
CreateCategory_Should_ReturnSuccess_When_ValidRequest()
CreateCategory_Should_ReturnFail_When_NameAlreadyExists()
CreateCategory_Should_ReturnFail_When_SlugAlreadyExists()
CreateCategory_Should_ReturnFail_When_ParentNotFound()
CreateCategory_Should_ReturnFail_When_SelfReferencingParent()
CreateCategory_Should_ReturnFail_When_CircularParentHierarchy()
CreateCategory_Should_InvalidateCacheKeys_After_Success()
```

**Class:** `UpdateCategoryCommandHandlerTests`
```
UpdateCategory_Should_ReturnSuccess_When_ValidRequest()
UpdateCategory_Should_ReturnFail_When_CategoryNotFound()
UpdateCategory_Should_ReturnFail_When_DuplicateName()
UpdateCategory_Should_ReturnFail_When_DuplicateSlug()
UpdateCategory_Should_ReturnFail_When_ConcurrencyConflict()
UpdateCategory_Should_ReturnFail_When_AssignedToDescendant()
```

**Class:** `DeleteCategoryCommandHandlerTests`
```
DeleteCategory_Should_ReturnSuccess_When_ValidId()
DeleteCategory_Should_ReturnFail_When_IdIsZero()
DeleteCategory_Should_ReturnFail_When_NotFound()
DeleteCategory_Should_ReturnFail_When_HasChildren()
DeleteCategory_Should_InvalidateCacheKeys_After_Success()
```

### 5.2 Category Query Handlers (Unit Tests)

**Class:** `GetAllCategoriesQueryHandlerTests`
```
GetAllCategories_Should_ReturnCachedData_When_CacheHit()
GetAllCategories_Should_QueryDb_And_Cache_When_CacheMiss()
GetAllCategories_Should_FilterByIsActive_When_Provided()
GetAllCategories_Should_ReturnAll_When_IsActiveIsNull()
```

**Class:** `GetCategoryByIdQueryHandlerTests`
```
GetCategoryById_Should_ReturnCategory_When_Found()
GetCategoryById_Should_ReturnFail_When_NotFound()
```

**Class:** `GetCategoriesPagedQueryHandlerTests`
```
GetCategoriesPaged_Should_ReturnPagedResult_When_ValidRequest()
GetCategoriesPaged_Should_ReturnCorrectPage_When_Paginated()
GetCategoriesPaged_Should_FilterBySearchTerm()
```

### 5.3 Role Command Handlers (Unit Tests)

**Class:** `CreateRoleCommandHandlerTests`
```
CreateRole_Should_ReturnSuccess_When_RoleDoesNotExist()
CreateRole_Should_ReturnFail_When_RoleAlreadyExists()
```

**Class:** `DeleteRoleCommandHandlerTests`
```
DeleteRole_Should_ReturnSuccess_When_ValidId()
DeleteRole_Should_ReturnFail_When_IdIsZero()
DeleteRole_Should_ReturnFail_When_RoleNotFound()
DeleteRole_Should_ReturnFail_When_RoleIsAdmin()
DeleteRole_Should_ReturnFail_When_UsersAssignedToRole()
```

**Class:** `UpdateRoleCommandHandlerTests`
```
UpdateRole_Should_ReturnSuccess_When_ValidRequest()
UpdateRole_Should_ReturnFail_When_RoleIsAdmin()
UpdateRole_Should_ReturnFail_When_RoleNotFound()
```

**Class:** `UpdateRolePermissionsCommandHandlerTests`
```
UpdateRolePermissions_Should_ReturnSuccess_When_ClaimsChanged()
UpdateRolePermissions_Should_ReturnSuccess_When_NoChangesDetected()
UpdateRolePermissions_Should_ReturnFail_When_RoleNotFound()
UpdateRolePermissions_Should_ReturnFail_When_RoleIsAdmin()
```

### 5.4 User Command Handlers (Unit Tests)

**Class:** `UserRegistrationCommandHandlerTests` *(extend existing)*
```
Handle_Should_ReturnFail_When_NullRequest()
Handle_Should_ReturnFail_When_PasswordMismatch()
Handle_Should_CallRegisterAsync_Exactly_Once()
```

**Class:** `UpdateUserCommandHandlerTests`
```
UpdateUser_Should_ReturnSuccess_When_UserExists()
UpdateUser_Should_ReturnFail_When_UserNotFound()
```

**Class:** `ChangeUserPasswordCommandHandlerTests`
```
ChangePassword_Should_ReturnSuccess_When_Valid()
ChangePassword_Should_ReturnFail_When_UserNotFound()
ChangePassword_Should_ReturnFail_When_WrongCurrentPassword()
```

**Class:** `ChangeUserStatusCommandHandlerTests`
```
ChangeStatus_Should_Activate_When_FlagIsTrue()
ChangeStatus_Should_Deactivate_When_FlagIsFalse()
ChangeStatus_Should_ReturnFail_When_UserNotFound()
```

**Class:** `ForgotPasswordCommandHandlerTests`
```
ForgotPassword_Should_ReturnSuccess_When_EmailExists_And_Confirmed()
ForgotPassword_Should_ReturnFail_When_EmailNotFound()
ForgotPassword_Should_ReturnFail_When_EmailNotConfirmed()
```

**Class:** `ResetPasswordCommandHandlerTests`
```
ResetPassword_Should_ReturnSuccess_When_Valid()
ResetPassword_Should_ReturnFail_When_EmailNotFound()
ResetPassword_Should_ReturnFail_When_EmailNotConfirmed()
ResetPassword_Should_ReturnFail_When_InvalidToken()
```

**Class:** `UpdateUserRolesCommandHandlerTests`
```
UpdateUserRoles_Should_ReturnSuccess_When_ValidRoles()
UpdateUserRoles_Should_ReturnFail_When_UserNotFound()
UpdateUserRoles_Should_ReturnFail_When_RoleDoesNotExist()
UpdateUserRoles_Should_ReturnFail_When_UserIsSystemAdmin()
```

### 5.5 Token Query Handlers (Unit Tests)

**Class:** `GetTokenQueryHandlerTests`
```
GetToken_Should_ReturnToken_When_CredentialsValid()
GetToken_Should_ReturnFail_When_UserNotFound()
GetToken_Should_ReturnFail_When_UserNotActive()
GetToken_Should_ReturnFail_When_EmailNotConfirmed()
GetToken_Should_ReturnFail_When_WrongPassword()
GetToken_Should_ReturnFail_When_AccountLockedOut()
```

**Class:** `GetRefreshTokenQueryHandlerTests`
```
GetRefreshToken_Should_ReturnNewToken_When_RefreshTokenValid()
GetRefreshToken_Should_ReturnFail_When_RefreshTokenExpired()
GetRefreshToken_Should_ReturnFail_When_RefreshTokenMismatch()
GetRefreshToken_Should_ReturnFail_When_UserNotFound()
```

### 5.6 Business Logic — CategoryWriteGuards (Unit Tests)

**Class:** `CategoryWriteGuardsTests`
```
NormalizeKey_Should_TrimAndUppercase()
NormalizeKey_Should_Handle_WhitespacePadding()
ValidateParentAssignment_Should_ReturnNull_When_NoParent()
ValidateParentAssignment_Should_ReturnError_When_SelfReference()
ValidateParentAssignment_Should_ReturnError_When_ParentNotFound()
ValidateParentAssignment_Should_ReturnError_When_DescendantAssigned()
ValidateParentAssignment_Should_ReturnError_When_CycleDetected()
IsUniqueConstraintViolation_Should_ReturnTrue_For_DuplicateKeyMessage()
IsUniqueConstraintViolation_Should_ReturnFalse_For_OtherError()
GetUniqueConstraintMessage_Should_ReturnNameMessage_For_NameIndex()
GetUniqueConstraintMessage_Should_ReturnSlugMessage_For_SlugIndex()
GetUniqueConstraintMessage_Should_ReturnGenericMessage_For_Unknown()
```

### 5.7 Missing Integration Tests

**Class:** `AccountEndpointsTests`
```
Login_Should_ReturnToken_When_ValidCredentials()
Login_Should_Return400_When_InvalidCredentials()
Login_Should_Return400_When_UserNotActive()
RefreshToken_Should_ReturnNewToken_When_Valid()
RefreshToken_Should_Return400_When_Expired()
ForgotPassword_Should_Return200_When_EmailExists()
ForgotPassword_Should_Return400_When_EmailNotFound()
ResetPassword_Should_Return200_When_Valid()
ResetPassword_Should_Return400_When_InvalidToken()
```

**Class:** `CategoryEndpointsTests` *(extend existing)*
```
GetCategoriesPaged_Should_ReturnPagedResult()
GetCategoriesForList_Should_Return401_When_Unauthenticated()
CreateCategory_Should_Return200_When_Valid_And_Authorized()
CreateCategory_Should_Return401_When_Unauthenticated()
UpdateCategory_Should_Return200_When_Valid()
UpdateCategory_Should_Return409_When_ConcurrencyConflict()
DeleteCategory_Should_Return200_When_Valid()
DeleteCategory_Should_Return400_When_HasChildren()
```

**Class:** `RoleEndpointsTests`
```
GetAllRoles_Should_Return200_When_Authorized()
GetAllRoles_Should_Return401_When_Unauthenticated()
GetRoleById_Should_Return200_When_Found()
GetRoleById_Should_Return404_When_NotFound()
CreateRole_Should_Return200_When_Valid()
CreateRole_Should_Return400_When_DuplicateName()
UpdateRole_Should_Return200_When_Valid()
DeleteRole_Should_Return200_When_Valid()
DeleteRole_Should_Return400_When_HasUsers()
GetPermissions_Should_Return200_For_ExistingRole()
UpdatePermissions_Should_Return200_When_Valid()
```

**Class:** `UserEndpointsTests`
```
RegisterUser_Should_Return200_When_Valid()
RegisterUser_Should_Return400_When_DuplicateEmail()
GetUserById_Should_Return200_When_Found()
GetUserById_Should_Return404_When_NotFound()
GetAllUsers_Should_Return200_When_Authorized()
GetUsersPaged_Should_ReturnPagedResult()
UpdateUser_Should_Return200_When_Valid()
ChangePassword_Should_Return200_When_Valid()
ChangeStatus_Should_Return200_When_Valid()
UpdateUserRoles_Should_Return200_When_Valid()
GetUserRoles_Should_Return200_For_ExistingUser()
```

---

## 🚨 6. CRITICAL FAIL CONDITIONS TRIGGERED

| Condition | Status |
|---|---|
| Any endpoint has no integration test | ❌ 25 of 27 endpoints have NO integration test |
| Any command has no unit test | ❌ 16 of 17 commands have NO unit test |
| Any query has no unit test | ❌ 13 of 13 queries have NO unit test |
| Coverage < 90% | ❌ **Coverage is 3.4%** |
| Critical business logic untested | ❌ `CategoryWriteGuards`, `TokenService`, `UserService`, `RoleService` are all untested |
| Placeholder tests present | ❌ Two `UnitTest1.cs` files with `Assert.Pass()` only |

---

## 🏁 7. FINAL VERDICT

```
╔══════════════════════════════════════════════════════╗
║                                                      ║
║   ❌  FAIL                                           ║
║                                                      ║
║   Coverage: 3.4% (Threshold: ≥ 90%)                 ║
║   Missing Tests: 85 out of 88 testable units         ║
║   Critical Gaps: ALL endpoint groups, ALL handlers   ║
║   Placeholder tests: 2 (must be removed)             ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
```

---

## 🛠️ REMEDIATION ROADMAP

To reach **PASS (≥ 95%)**, the following test files must be created:

### Unit Test Project (`UMS.Tests`)

| Priority | New File | Tests to Write |
|---|---|---|
| 🔴 P1 | `Features/Categories/Commands/CreateCategoryCommandHandlerTests.cs` | 7 tests |
| 🔴 P1 | `Features/Categories/Commands/UpdateCategoryCommandHandlerTests.cs` | 6 tests |
| 🔴 P1 | `Features/Categories/Commands/DeleteCategoryCommandHandlerTests.cs` | 5 tests |
| 🔴 P1 | `Features/Categories/Commands/CategoryWriteGuardsTests.cs` | 12 tests |
| 🔴 P1 | `Features/Categories/Queries/GetAllCategoriesQueryHandlerTests.cs` | 4 tests |
| 🔴 P1 | `Features/Categories/Queries/GetCategoryByIdQueryHandlerTests.cs` | 2 tests |
| 🔴 P1 | `Features/Categories/Queries/GetCategoriesPagedQueryHandlerTests.cs` | 3 tests |
| 🔴 P1 | `Features/Roles/Commands/CreateRoleCommandHandlerTests.cs` | 2 tests |
| 🔴 P1 | `Features/Roles/Commands/DeleteRoleCommandHandlerTests.cs` | 5 tests |
| 🔴 P1 | `Features/Roles/Commands/UpdateRoleCommandHandlerTests.cs` | 3 tests |
| 🔴 P1 | `Features/Roles/Commands/UpdateRolePermissionsCommandHandlerTests.cs` | 4 tests |
| 🔴 P1 | `Features/Token/Queries/GetTokenQueryHandlerTests.cs` | 6 tests |
| 🔴 P1 | `Features/Token/Queries/GetRefreshTokenQueryHandlerTests.cs` | 4 tests |
| 🟠 P2 | `Features/Users/Commands/UpdateUserCommandHandlerTests.cs` | 2 tests |
| 🟠 P2 | `Features/Users/Commands/ChangeUserPasswordCommandHandlerTests.cs` | 3 tests |
| 🟠 P2 | `Features/Users/Commands/ChangeUserStatusCommandHandlerTests.cs` | 3 tests |
| 🟠 P2 | `Features/Users/Commands/ForgotPasswordCommandHandlerTests.cs` | 3 tests |
| 🟠 P2 | `Features/Users/Commands/ResetPasswordCommandHandlerTests.cs` | 4 tests |
| 🟠 P2 | `Features/Users/Commands/UpdateUserRolesCommandHandlerTests.cs` | 4 tests |
| 🟡 P3 | `Features/Users/Queries/GetAllUsersQueryHandlerTests.cs` | 2 tests |
| 🟡 P3 | `Features/Users/Queries/GetUserByIdQueryHandlerTests.cs` | 2 tests |
| 🟡 P3 | `Features/Users/Queries/GetUsersPagedQueryHandlerTests.cs` | 3 tests |

### Integration Test Project (`UMS.IntegrationTests`)

| Priority | New File | Tests to Write |
|---|---|---|
| 🔴 P1 | `Endpoints/AccountEndpointsTests.cs` | 9 tests |
| 🔴 P1 | `Endpoints/RoleEndpointsTests.cs` | 11 tests |
| 🔴 P1 | `Endpoints/UserEndpointsTests.cs` | 11 tests |
| 🟠 P2 | `Endpoints/CategoryEndpointsTests.cs` *(extend)* | 8 more tests |

> [!IMPORTANT]
> **Delete both `UnitTest1.cs` placeholder files.** They are noise that obscures real test failures.

> [!TIP]
> Start with **P1 items** — Category and Token handlers — since these are already touched by the partial integration tests and can be verified quickly. Use `NSubstitute` (already referenced) for all unit test mocks. Use `InMemory` DB (already configured in `CustomWebApplicationFactory`) for integration tests.
