# Graph Report - UMS.Application  (2026-04-28)

## Corpus Check
- Corpus is ~8,180 words - fits in a single context window. You may not need a graph.

## Summary
- 516 nodes · 580 edges · 59 communities detected
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 65 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_AbstractValidator  ChangeUserStatusValidator|AbstractValidator / ChangeUserStatusValidator]]
- [[_COMMUNITY_ConfirmEmailCommand  ConfirmEmailCommandHandler|ConfirmEmailCommand / ConfirmEmailCommandHandler]]
- [[_COMMUNITY_CategoryWriteGuards  GetUniqueConstraintMessage|CategoryWriteGuards / GetUniqueConstraintMessage]]
- [[_COMMUNITY_DeleteRoleCommand  DeleteRoleCommandHandler|DeleteRoleCommand / DeleteRoleCommandHandler]]
- [[_COMMUNITY_ChangeUserStatusCommand  ChangeUserStatusCommandHandler|ChangeUserStatusCommand / ChangeUserStatusCommandHandler]]
- [[_COMMUNITY_CreateCategoryCommandHandler  CreateCategoryRequest|CreateCategoryCommandHandler / CreateCategoryRequest]]
- [[_COMMUNITY_CategoryCreatedEvent  CategoryCreatedEventHandler|CategoryCreatedEvent / CategoryCreatedEventHandler]]
- [[_COMMUNITY_IPipelineBehavior  IValidationFailureFactory|IPipelineBehavior / IValidationFailureFactory]]
- [[_COMMUNITY_ICurrentUserService  GetClaims|ICurrentUserService / GetClaims]]
- [[_COMMUNITY_CategoryCacheKeys  GetAll|CategoryCacheKeys / GetAll]]
- [[_COMMUNITY_IApiRequest  DeleteAsync|IApiRequest / DeleteAsync]]
- [[_COMMUNITY_AppAction  AppFeature|AppAction / AppFeature]]
- [[_COMMUNITY_CreateRoleCommand  CreateRoleCommandHandler|CreateRoleCommand / CreateRoleCommandHandler]]
- [[_COMMUNITY_UnlockUserAsync  UnlockUserCommand|UnlockUserAsync / UnlockUserCommand]]
- [[_COMMUNITY_UpdateUserAsync  UpdateUserCommand|UpdateUserAsync / UpdateUserCommand]]
- [[_COMMUNITY_GetUsersPagedQuery  GetUsersPagedQueryHandler|GetUsersPagedQuery / GetUsersPagedQueryHandler]]
- [[_COMMUNITY_ConfirmEmailChangeCommand  ConfirmEmailChangeCommandHandler|ConfirmEmailChangeCommand / ConfirmEmailChangeCommandHandler]]
- [[_COMMUNITY_LogoutAsync  LogoutCommand|LogoutAsync / LogoutCommand]]
- [[_COMMUNITY_GetUserRolesQuery  GetUserRolesQueryHandler|GetUserRolesQuery / GetUserRolesQueryHandler]]
- [[_COMMUNITY_GetUserByIdQuery  GetUserByIdQueryHandler|GetUserByIdQuery / GetUserByIdQueryHandler]]
- [[_COMMUNITY_ISessionWrapper  GetFromSession|ISessionWrapper / GetFromSession]]
- [[_COMMUNITY_IFileStorageService  DeleteFile|IFileStorageService / DeleteFile]]
- [[_COMMUNITY_ServiceCollectionExtensions  AddApplicationServices|ServiceCollectionExtensions / AddApplicationServices]]
- [[_COMMUNITY_IValidationFailureFactory  CreateFailure|IValidationFailureFactory / CreateFailure]]
- [[_COMMUNITY_IEmailService  SendAsync|IEmailService / SendAsync]]
- [[_COMMUNITY_CacheConfiguration|CacheConfiguration]]
- [[_COMMUNITY_FileData|FileData]]
- [[_COMMUNITY_SD|SD]]
- [[_COMMUNITY_EmailConfiguration|EmailConfiguration]]
- [[_COMMUNITY_SendEmailDto|SendEmailDto]]
- [[_COMMUNITY_JwtConfiguration|JwtConfiguration]]
- [[_COMMUNITY_PagedFilterRequest|PagedFilterRequest]]
- [[_COMMUNITY_IResponseWrapper|IResponseWrapper]]
- [[_COMMUNITY_AppEnums|AppEnums]]
- [[_COMMUNITY_RoleClaimResponse|RoleClaimResponse]]
- [[_COMMUNITY_RoleClaimViewModel|RoleClaimViewModel]]
- [[_COMMUNITY_RoleResponse|RoleResponse]]
- [[_COMMUNITY_ChangeUserStatusRequest|ChangeUserStatusRequest]]
- [[_COMMUNITY_ConfirmEmailRequest|ConfirmEmailRequest]]
- [[_COMMUNITY_ConfirmEmailChangeRequest|ConfirmEmailChangeRequest]]
- [[_COMMUNITY_LockUserRequest|LockUserRequest]]
- [[_COMMUNITY_ResendConfirmationEmailRequest|ResendConfirmationEmailRequest]]
- [[_COMMUNITY_UnlockUserRequest|UnlockUserRequest]]
- [[_COMMUNITY_UpdateUserRequest|UpdateUserRequest]]
- [[_COMMUNITY_UpdateUserRolesRequest|UpdateUserRolesRequest]]
- [[_COMMUNITY_UserRegistrationRequest|UserRegistrationRequest]]
- [[_COMMUNITY_UserRoleViewModel|UserRoleViewModel]]
- [[_COMMUNITY_UserResponse|UserResponse]]
- [[_COMMUNITY_ICacheAbleMediatorQuery|ICacheAbleMediatorQuery]]
- [[_COMMUNITY_IDateTimeService|IDateTimeService]]
- [[_COMMUNITY_TwoFactorOptions|TwoFactorOptions]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_DisableTwoFactorAuthRequest|DisableTwoFactorAuthRequest]]
- [[_COMMUNITY_LogoutRequest|LogoutRequest]]
- [[_COMMUNITY_TwoFactorCodeRequest|TwoFactorCodeRequest]]
- [[_COMMUNITY_ProfileResponse|ProfileResponse]]
- [[_COMMUNITY_TwoFactorAuthViewModel|TwoFactorAuthViewModel]]
- [[_COMMUNITY_IValidateMe|IValidateMe]]
- [[_COMMUNITY_Community 58|Community 58]]

## God Nodes (most connected - your core abstractions)
1. `IUserService` - 24 edges
2. `ICurrentUserService` - 9 edges
3. `IRoleService` - 8 edges
4. `IApplicationDbContext` - 7 edges
5. `ResponseWrapper` - 6 edges
6. `IApiRequest` - 6 edges
7. `CategoryWriteGuards` - 5 edges
8. `ValidationFailureFactory` - 4 edges
9. `ICacheService` - 4 edges
10. `ISessionWrapper` - 4 edges

## Surprising Connections (you probably didn't know these)
- `GetAllCategoriesQueryHandler` --inherits--> `IRequestHandler`  [EXTRACTED]
  C:\_MyFolder\MyApps\UserManagement\UMSSolution\UMS.Application\Features\Categories\Queries\GetAllCategories\GetAllCategoriesQuery.cs →   _Bridges community 5 → community 9_
- `GetCategoriesPagedQueryHandler` --inherits--> `IRequestHandler`  [EXTRACTED]
  C:\_MyFolder\MyApps\UserManagement\UMSSolution\UMS.Application\Features\Categories\Queries\GetCategoriesPaged\GetCategoriesPagedQuery.cs →   _Bridges community 5 → community 1_
- `CreateRoleCommandHandler` --inherits--> `IRequestHandler`  [EXTRACTED]
  C:\_MyFolder\MyApps\UserManagement\UMSSolution\UMS.Application\Features\Roles\Commands\CreateRole\CreateRoleCommand.cs →   _Bridges community 5 → community 12_
- `DeleteRoleCommandHandler` --inherits--> `IRequestHandler`  [EXTRACTED]
  C:\_MyFolder\MyApps\UserManagement\UMSSolution\UMS.Application\Features\Roles\Commands\DeleteRole\DeleteRoleCommand.cs →   _Bridges community 5 → community 3_
- `ChangeUserStatusCommandHandler` --inherits--> `IRequestHandler`  [EXTRACTED]
  C:\_MyFolder\MyApps\UserManagement\UMSSolution\UMS.Application\Features\Users\Commands\ChangeUserStatus\ChangeUserStatusCommand.cs →   _Bridges community 5 → community 4_

## Communities

### Community 0 - "AbstractValidator / ChangeUserStatusValidator"
Cohesion: 0.02
Nodes (61): AbstractValidator, ChangeUserStatusValidator, UMS.Application.Features.Users.Commands, ConfirmEmailChangeValidator, UMS.Application.Features.Users.Commands, ConfirmEmailValidator, UMS.Application.Features.Users.Commands, ConfirmTwoFactorAuthValidator (+53 more)

### Community 1 - "ConfirmEmailCommand / ConfirmEmailCommandHandler"
Cohesion: 0.04
Nodes (32): ConfirmEmailCommand, ConfirmEmailCommandHandler, UMS.Application.Features.Users.Commands, DisableTwoFactorAuthCommand, DisableTwoFactorAuthCommandHandler, UMS.Application.Features.Users.Commands.DisableTwoFactorAuth, EnableTwoFactorAuthCommand, EnableTwoFactorAuthCommandHandler (+24 more)

### Community 2 - "CategoryWriteGuards / GetUniqueConstraintMessage"
Cohesion: 0.08
Nodes (10): CategoryWriteGuards, IApplicationDbContext, UMS.Application.Interfaces.Common, ICacheService, UMS.Application.Interfaces.Common, IResponseWrapper, ResponseWrapper, UMS.Application.Dtos.Wrappers (+2 more)

### Community 3 - "DeleteRoleCommand / DeleteRoleCommandHandler"
Cohesion: 0.05
Nodes (20): DeleteRoleCommand, DeleteRoleCommandHandler, UMS.Application.Features.Roles.Commands, GetPermissionsQuery, GetPermissionsQueryHandler, UMS.Application.Features.Roles.Queries, GetRoleByIdQuery, GetRoleByIdQueryHandler (+12 more)

### Community 4 - "ChangeUserStatusCommand / ChangeUserStatusCommandHandler"
Cohesion: 0.06
Nodes (15): ChangeUserStatusCommand, ChangeUserStatusCommandHandler, UMS.Application.Features.Users.Commands, ConfirmTwoFactorAuthCommand, ConfirmTwoFactorAuthCommandHandler, UMS.Application.Features.Users.Commands.ConfirmTwoFactorAuth, GenerateNew2FARecoveryCodesCommandHandler, IUserService (+7 more)

### Community 5 - "CreateCategoryCommandHandler / CreateCategoryRequest"
Cohesion: 0.06
Nodes (19): CreateCategoryCommandHandler, CreateCategoryRequest, UMS.Application.Features.Categories.Commands.Create, DeleteCategoryCommandHandler, UMS.Application.Features.Categories.Commands.Delete, GetAllCategoriesAdminQueryHandler, UMS.Application.Features.Categories.Queries.GetCategoriesAdmin, GetAllCategoriesForListQueryHandler (+11 more)

### Community 6 - "CategoryCreatedEvent / CategoryCreatedEventHandler"
Cohesion: 0.13
Nodes (11): CategoryCreatedEvent, CategoryCreatedEventHandler, UMS.Application.Features.Categories.Events, CategoryDeletedEvent, CategoryDeletedEventHandler, UMS.Application.Features.Categories.Events, CategoryUpdatedEvent, CategoryUpdatedEventHandler (+3 more)

### Community 7 - "IPipelineBehavior / IValidationFailureFactory"
Cohesion: 0.18
Nodes (6): IPipelineBehavior, IValidationFailureFactory, UMS.Application.Behaviors, ValidationFailureFactory, UMS.Application.Behaviors, ValidationPipelineBehavior

### Community 8 - "ICurrentUserService / GetClaims"
Cohesion: 0.18
Nodes (2): ICurrentUserService, UMS.Application.Interfaces.Common

### Community 9 - "CategoryCacheKeys / GetAll"
Cohesion: 0.25
Nodes (4): CategoryCacheKeys, UMS.Application.Features.Categories, GetAllCategoriesQueryHandler, UMS.Application.Features.Categories.Queries.GetAllCategories

### Community 10 - "IApiRequest / DeleteAsync"
Cohesion: 0.25
Nodes (2): IApiRequest, UMS.Application.Interfaces.Common

### Community 11 - "AppAction / AppFeature"
Cohesion: 0.29
Nodes (5): AppAction, AppFeature, AppPermissions, AppService, UMS.Application.Authorization

### Community 12 - "CreateRoleCommand / CreateRoleCommandHandler"
Cohesion: 0.29
Nodes (4): CreateRoleCommand, CreateRoleCommandHandler, CreateRoleRequest, UMS.Application.Features.Roles.Commands

### Community 13 - "UnlockUserAsync / UnlockUserCommand"
Cohesion: 0.33
Nodes (3): UMS.Application.Features.Users.Commands, UnlockUserCommand, UnlockUserCommandHandler

### Community 14 - "UpdateUserAsync / UpdateUserCommand"
Cohesion: 0.33
Nodes (3): UMS.Application.Features.Users.Commands, UpdateUserCommand, UpdateUserCommandHandler

### Community 15 - "GetUsersPagedQuery / GetUsersPagedQueryHandler"
Cohesion: 0.33
Nodes (3): GetUsersPagedQuery, GetUsersPagedQueryHandler, UMS.Application.Features.Users.Queries

### Community 16 - "ConfirmEmailChangeCommand / ConfirmEmailChangeCommandHandler"
Cohesion: 0.33
Nodes (3): ConfirmEmailChangeCommand, ConfirmEmailChangeCommandHandler, UMS.Application.Features.Users.Commands

### Community 17 - "LogoutAsync / LogoutCommand"
Cohesion: 0.33
Nodes (3): LogoutCommand, LogoutCommandHandler, UMS.Application.Features.Users.Commands.Logout

### Community 18 - "GetUserRolesQuery / GetUserRolesQueryHandler"
Cohesion: 0.33
Nodes (3): GetUserRolesQuery, GetUserRolesQueryHandler, UMS.Application.Features.Users.Queries

### Community 19 - "GetUserByIdQuery / GetUserByIdQueryHandler"
Cohesion: 0.33
Nodes (3): GetUserByIdQuery, GetUserByIdQueryHandler, UMS.Application.Features.Users.Queries

### Community 20 - "ISessionWrapper / GetFromSession"
Cohesion: 0.33
Nodes (2): ISessionWrapper, UMS.Application.Interfaces.Common

### Community 21 - "IFileStorageService / DeleteFile"
Cohesion: 0.4
Nodes (2): IFileStorageService, UMS.Application.Interfaces.Common

### Community 22 - "ServiceCollectionExtensions / AddApplicationServices"
Cohesion: 0.5
Nodes (2): ServiceCollectionExtensions, UMS.Application

### Community 23 - "IValidationFailureFactory / CreateFailure"
Cohesion: 0.5
Nodes (2): IValidationFailureFactory, UMS.Application.Behaviors

### Community 24 - "IEmailService / SendAsync"
Cohesion: 0.5
Nodes (2): IEmailService, UMS.Application.Interfaces.Common

### Community 25 - "CacheConfiguration"
Cohesion: 0.67
Nodes (2): CacheConfiguration, UMS.Application.Dtos.Cache

### Community 26 - "FileData"
Cohesion: 0.67
Nodes (2): FileData, UMS.Application.Dtos.Common

### Community 27 - "SD"
Cohesion: 0.67
Nodes (2): SD, UMS.Application.Dtos.Common

### Community 28 - "EmailConfiguration"
Cohesion: 0.67
Nodes (2): EmailConfiguration, UMS.Application.Dtos.Email

### Community 29 - "SendEmailDto"
Cohesion: 0.67
Nodes (2): SendEmailDto, UMS.Application.Dtos.Email

### Community 30 - "JwtConfiguration"
Cohesion: 0.67
Nodes (2): JwtConfiguration, UMS.Application.Dtos.JWT

### Community 31 - "PagedFilterRequest"
Cohesion: 0.67
Nodes (2): PagedFilterRequest, UMS.Application.Dtos.Pagination

### Community 32 - "IResponseWrapper"
Cohesion: 1.0
Nodes (2): IResponseWrapper, UMS.Application.Dtos.Wrappers

### Community 33 - "AppEnums"
Cohesion: 0.67
Nodes (2): AppEnums, UMS.Application.Enums

### Community 34 - "RoleClaimResponse"
Cohesion: 0.67
Nodes (2): RoleClaimResponse, UMS.Application.Features.Roles

### Community 35 - "RoleClaimViewModel"
Cohesion: 0.67
Nodes (2): RoleClaimViewModel, UMS.Application.Features.Roles

### Community 36 - "RoleResponse"
Cohesion: 0.67
Nodes (2): RoleResponse, UMS.Application.Features.Roles

### Community 37 - "ChangeUserStatusRequest"
Cohesion: 0.67
Nodes (2): ChangeUserStatusRequest, UMS.Application.Features.Users.Commands

### Community 38 - "ConfirmEmailRequest"
Cohesion: 0.67
Nodes (2): ConfirmEmailRequest, UMS.Application.Features.Users.Commands

### Community 39 - "ConfirmEmailChangeRequest"
Cohesion: 0.67
Nodes (2): ConfirmEmailChangeRequest, UMS.Application.Features.Users.Commands

### Community 40 - "LockUserRequest"
Cohesion: 0.67
Nodes (2): LockUserRequest, UMS.Application.Features.Users.Commands

### Community 41 - "ResendConfirmationEmailRequest"
Cohesion: 0.67
Nodes (2): ResendConfirmationEmailRequest, UMS.Application.Features.Users.Commands

### Community 42 - "UnlockUserRequest"
Cohesion: 0.67
Nodes (2): UMS.Application.Features.Users.Commands, UnlockUserRequest

### Community 43 - "UpdateUserRequest"
Cohesion: 0.67
Nodes (2): UMS.Application.Features.Users.Commands, UpdateUserRequest

### Community 44 - "UpdateUserRolesRequest"
Cohesion: 0.67
Nodes (2): UMS.Application.Features.Users.Commands, UpdateUserRolesRequest

### Community 45 - "UserRegistrationRequest"
Cohesion: 0.67
Nodes (2): UMS.Application.Features.Users.Commands, UserRegistrationRequest

### Community 46 - "UserRoleViewModel"
Cohesion: 0.67
Nodes (2): UMS.Application.Features.Users.Models.Requests, UserRoleViewModel

### Community 47 - "UserResponse"
Cohesion: 0.67
Nodes (2): UMS.Application.Features.Users.Models.Responses, UserResponse

### Community 48 - "ICacheAbleMediatorQuery"
Cohesion: 0.67
Nodes (2): ICacheAbleMediatorQuery, UMS.Application.Interfaces.Common

### Community 49 - "IDateTimeService"
Cohesion: 0.67
Nodes (2): IDateTimeService, UMS.Application.Interfaces.Common

### Community 50 - "TwoFactorOptions"
Cohesion: 1.0
Nodes (1): TwoFactorOptions

### Community 51 - "Community 51"
Cohesion: 1.0
Nodes (1): UMS.Application.Features.Categories.Queries.GetAllCategoriesForList

### Community 52 - "DisableTwoFactorAuthRequest"
Cohesion: 1.0
Nodes (1): DisableTwoFactorAuthRequest

### Community 53 - "LogoutRequest"
Cohesion: 1.0
Nodes (1): LogoutRequest

### Community 54 - "TwoFactorCodeRequest"
Cohesion: 1.0
Nodes (1): TwoFactorCodeRequest

### Community 55 - "ProfileResponse"
Cohesion: 1.0
Nodes (1): ProfileResponse

### Community 56 - "TwoFactorAuthViewModel"
Cohesion: 1.0
Nodes (1): TwoFactorAuthViewModel

### Community 57 - "IValidateMe"
Cohesion: 1.0
Nodes (1): IValidateMe

### Community 58 - "Community 58"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **152 isolated node(s):** `UMS.Application`, `UMS.Application.Authorization`, `AppAction`, `AppFeature`, `AppService` (+147 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `TwoFactorOptions`** (2 nodes): `TwoFactorOptions.cs`, `TwoFactorOptions`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 51`** (2 nodes): `CategoryLookupDto.cs`, `UMS.Application.Features.Categories.Queries.GetAllCategoriesForList`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `DisableTwoFactorAuthRequest`** (2 nodes): `DisableTwoFactorAuthRequest.cs`, `DisableTwoFactorAuthRequest`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `LogoutRequest`** (2 nodes): `LogoutRequest.cs`, `LogoutRequest`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `TwoFactorCodeRequest`** (2 nodes): `TwoFactorCodeRequest.cs`, `TwoFactorCodeRequest`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `ProfileResponse`** (2 nodes): `ProfileResponse.cs`, `ProfileResponse`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `TwoFactorAuthViewModel`** (2 nodes): `TwoFactorAuthViewModel.cs`, `TwoFactorAuthViewModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `IValidateMe`** (2 nodes): `IValidateMe.cs`, `IValidateMe`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 58`** (1 nodes): `GlobalUsings.cs`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `UpdateCategoryCommandHandler` connect `CreateCategoryCommandHandler / CreateCategoryRequest` to `CategoryWriteGuards / GetUniqueConstraintMessage`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Why does `CreateCategoryCommandHandler` connect `CreateCategoryCommandHandler / CreateCategoryRequest` to `CategoryWriteGuards / GetUniqueConstraintMessage`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Why does `IUserService` connect `ChangeUserStatusCommand / ChangeUserStatusCommandHandler` to `ConfirmEmailCommand / ConfirmEmailCommandHandler`, `CreateCategoryCommandHandler / CreateCategoryRequest`, `UnlockUserAsync / UnlockUserCommand`, `UpdateUserAsync / UpdateUserCommand`, `GetUsersPagedQuery / GetUsersPagedQueryHandler`, `ConfirmEmailChangeCommand / ConfirmEmailChangeCommandHandler`, `LogoutAsync / LogoutCommand`, `GetUserRolesQuery / GetUserRolesQueryHandler`, `GetUserByIdQuery / GetUserByIdQueryHandler`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **What connects `UMS.Application`, `UMS.Application.Authorization`, `AppAction` to the rest of the system?**
  _152 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `AbstractValidator / ChangeUserStatusValidator` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `ConfirmEmailCommand / ConfirmEmailCommandHandler` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `CategoryWriteGuards / GetUniqueConstraintMessage` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._