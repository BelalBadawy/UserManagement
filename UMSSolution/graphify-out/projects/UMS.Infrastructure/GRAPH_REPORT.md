# Graph Report - UMS.Infrastructure  (2026-04-28)

## Corpus Check
- Corpus is ~8,966 words - fits in a single context window. You may not need a graph.

## Summary
- 234 nodes · 254 edges · 31 communities detected
- Extraction: 87% EXTRACTED · 13% INFERRED · 0% AMBIGUOUS · INFERRED: 32 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_GetUserId  IUserService|GetUserId / IUserService]]
- [[_COMMUNITY_ApplicationDbContext  AddOutboxMessage|ApplicationDbContext / AddOutboxMessage]]
- [[_COMMUNITY_CurrentUserMiddleware  InvokeAsync|CurrentUserMiddleware / InvokeAsync]]
- [[_COMMUNITY_IdentityServiceExtensions  AddIdentityServices|IdentityServiceExtensions / AddIdentityServices]]
- [[_COMMUNITY_DistributedCacheService  Remove|DistributedCacheService / Remove]]
- [[_COMMUNITY_IRoleService  RoleService|IRoleService / RoleService]]
- [[_COMMUNITY_InitiailDb  Down|InitiailDb / Down]]
- [[_COMMUNITY_ApplicationDbSeeder  CheckAndApplyPendingMigrationAsync|ApplicationDbSeeder / CheckAndApplyPendingMigrationAsync]]
- [[_COMMUNITY_IdentityDbSeeder  AssignPermissionsToRoleAsync|IdentityDbSeeder / AssignPermissionsToRoleAsync]]
- [[_COMMUNITY_IAuthorizationPolicyProvider  PermissionPolicyProvider|IAuthorizationPolicyProvider / PermissionPolicyProvider]]
- [[_COMMUNITY_SaveChangesInterceptor  TrimStringInterceptor|SaveChangesInterceptor / TrimStringInterceptor]]
- [[_COMMUNITY_IFileStorageService  LocalFileStorageService|IFileStorageService / LocalFileStorageService]]
- [[_COMMUNITY_AuthorizationHandler  PermissionAuthorizationHandler|AuthorizationHandler / PermissionAuthorizationHandler]]
- [[_COMMUNITY_ApplicationDbContextModelSnapshot  BuildModel|ApplicationDbContextModelSnapshot / BuildModel]]
- [[_COMMUNITY_CategoryConfiguration  Configure|CategoryConfiguration / Configure]]
- [[_COMMUNITY_SeedUserConfiguration  SeedUsersConfiguration|SeedUserConfiguration / SeedUsersConfiguration]]
- [[_COMMUNITY_ApplicationRole  IdentityRole|ApplicationRole / IdentityRole]]
- [[_COMMUNITY_ApplicationRoleClaim  IdentityRoleClaim|ApplicationRoleClaim / IdentityRoleClaim]]
- [[_COMMUNITY_ApplicationUser  IdentityUser|ApplicationUser / IdentityUser]]
- [[_COMMUNITY_ApplicationUserClaim  IdentityUserClaim|ApplicationUserClaim / IdentityUserClaim]]
- [[_COMMUNITY_ApplicationUserLogin  IdentityUserLogin|ApplicationUserLogin / IdentityUserLogin]]
- [[_COMMUNITY_ApplicationUserRole  IdentityUserRole|ApplicationUserRole / IdentityUserRole]]
- [[_COMMUNITY_IAuthorizationRequirement  PermissionRequirement|IAuthorizationRequirement / PermissionRequirement]]
- [[_COMMUNITY_InitiailDb  BuildTargetModel|InitiailDb / BuildTargetModel]]
- [[_COMMUNITY_AddCategoryNormalizationAndConcurrency  BuildTargetModel|AddCategoryNormalizationAndConcurrency / BuildTargetModel]]
- [[_COMMUNITY_DateTimeService  IDateTimeService|DateTimeService / IDateTimeService]]
- [[_COMMUNITY_IEmailService  MailSenderService|IEmailService / MailSenderService]]
- [[_COMMUNITY_AppClaim|AppClaim]]
- [[_COMMUNITY_AppRoles|AppRoles]]
- [[_COMMUNITY_SchemaNames|SchemaNames]]
- [[_COMMUNITY_Community 30|Community 30]]

## God Nodes (most connected - your core abstractions)
1. `UserService` - 27 edges
2. `ApplicationDbContext` - 14 edges
3. `RoleService` - 11 edges
4. `CurrentUserService` - 10 edges
5. `IdentityDbSeeder` - 7 edges
6. `IdentityServiceExtensions` - 6 edges
7. `ServiceCollectionExtensions` - 5 edges
8. `PermissionPolicyProvider` - 5 edges
9. `TrimStringInterceptor` - 5 edges
10. `DistributedCacheService` - 5 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities

### Community 0 - "GetUserId / IUserService"
Cohesion: 0.1
Nodes (3): IUserService, UMS.Infrastructure.Identity.Services, UserService

### Community 1 - "ApplicationDbContext / AddOutboxMessage"
Cohesion: 0.1
Nodes (8): ApplicationDbContext, UMS.Infrastructure.Persistence.Contexts, AuditEntry, UMS.Infrastructure.Persistence.Audit, IApplicationDbContext, IdentityDbContext, QueryExtensions, UMS.Infrastructure.Extensions

### Community 2 - "CurrentUserMiddleware / InvokeAsync"
Cohesion: 0.13
Nodes (5): CurrentUserMiddleware, UMS.Infrastructure.Identity, CurrentUserService, ICurrentUserService, IMiddleware

### Community 3 - "IdentityServiceExtensions / AddIdentityServices"
Cohesion: 0.18
Nodes (4): IdentityServiceExtensions, UMS.Infrastructure.Identity, ServiceCollectionExtensions, UMS.Infrastructure

### Community 4 - "DistributedCacheService / Remove"
Cohesion: 0.14
Nodes (6): DistributedCacheService, UMS.Infrastructure.Services.Common, ICacheService, InMemorySessionWrapper, UMS.Infrastructure.Common, ISessionWrapper

### Community 5 - "IRoleService / RoleService"
Cohesion: 0.25
Nodes (3): IRoleService, RoleService, UMS.Infrastructure.Identity.Services

### Community 6 - "InitiailDb / Down"
Cohesion: 0.18
Nodes (5): InitiailDb, UMS.Infrastructure.Migrations, AddCategoryNormalizationAndConcurrency, UMS.Infrastructure.Migrations, Migration

### Community 7 - "ApplicationDbSeeder / CheckAndApplyPendingMigrationAsync"
Cohesion: 0.25
Nodes (4): ApplicationDbSeeder, UMS.Infrastructure.Persistence.DbInitializers, FeaturesDbSeeder, UMS.Infrastructure.Persistence.DbInitializers

### Community 8 - "IdentityDbSeeder / AssignPermissionsToRoleAsync"
Cohesion: 0.36
Nodes (2): IdentityDbSeeder, UMS.Infrastructure.Persistence.DbInitializers

### Community 9 - "IAuthorizationPolicyProvider / PermissionPolicyProvider"
Cohesion: 0.29
Nodes (3): IAuthorizationPolicyProvider, PermissionPolicyProvider, UMS.Infrastructure.Identity.Permissions

### Community 10 - "SaveChangesInterceptor / TrimStringInterceptor"
Cohesion: 0.38
Nodes (3): SaveChangesInterceptor, TrimStringInterceptor, UMS.Infrastructure.Persistence.Interceptors

### Community 11 - "IFileStorageService / LocalFileStorageService"
Cohesion: 0.33
Nodes (3): IFileStorageService, LocalFileStorageService, UMS.Infrastructure.Services

### Community 12 - "AuthorizationHandler / PermissionAuthorizationHandler"
Cohesion: 0.4
Nodes (3): AuthorizationHandler, PermissionAuthorizationHandler, UMS.Infrastructure.Identity.Permissions

### Community 13 - "ApplicationDbContextModelSnapshot / BuildModel"
Cohesion: 0.4
Nodes (3): ApplicationDbContextModelSnapshot, UMS.Infrastructure.Migrations, ModelSnapshot

### Community 14 - "CategoryConfiguration / Configure"
Cohesion: 0.4
Nodes (3): CategoryConfiguration, UMS.Infrastructure.Persistence.DbConfigurations, IEntityTypeConfiguration

### Community 15 - "SeedUserConfiguration / SeedUsersConfiguration"
Cohesion: 0.5
Nodes (3): SeedUserConfiguration, SeedUsersConfiguration, UMS.Infrastructure.Identity.Configurations

### Community 16 - "ApplicationRole / IdentityRole"
Cohesion: 0.5
Nodes (3): ApplicationRole, UMS.Infrastructure.Identity.Models, IdentityRole

### Community 17 - "ApplicationRoleClaim / IdentityRoleClaim"
Cohesion: 0.5
Nodes (3): ApplicationRoleClaim, UMS.Infrastructure.Identity.Models, IdentityRoleClaim

### Community 18 - "ApplicationUser / IdentityUser"
Cohesion: 0.5
Nodes (3): ApplicationUser, UMS.Infrastructure.Identity.Models, IdentityUser

### Community 19 - "ApplicationUserClaim / IdentityUserClaim"
Cohesion: 0.5
Nodes (3): ApplicationUserClaim, UMS.Infrastructure.Identity.Models, IdentityUserClaim

### Community 20 - "ApplicationUserLogin / IdentityUserLogin"
Cohesion: 0.5
Nodes (3): ApplicationUserLogin, UMS.Infrastructure.Identity.Models, IdentityUserLogin

### Community 21 - "ApplicationUserRole / IdentityUserRole"
Cohesion: 0.5
Nodes (3): ApplicationUserRole, UMS.Infrastructure.Identity.Models, IdentityUserRole

### Community 22 - "IAuthorizationRequirement / PermissionRequirement"
Cohesion: 0.5
Nodes (3): IAuthorizationRequirement, PermissionRequirement, UMS.Infrastructure.Identity.Permissions

### Community 23 - "InitiailDb / BuildTargetModel"
Cohesion: 0.5
Nodes (2): InitiailDb, UMS.Infrastructure.Migrations

### Community 24 - "AddCategoryNormalizationAndConcurrency / BuildTargetModel"
Cohesion: 0.5
Nodes (2): AddCategoryNormalizationAndConcurrency, UMS.Infrastructure.Migrations

### Community 25 - "DateTimeService / IDateTimeService"
Cohesion: 0.5
Nodes (3): DateTimeService, UMS.Infrastructure.Services.Common, IDateTimeService

### Community 26 - "IEmailService / MailSenderService"
Cohesion: 0.5
Nodes (3): IEmailService, MailSenderService, UMS.Infrastructure.Services.Common

### Community 27 - "AppClaim"
Cohesion: 0.67
Nodes (2): AppClaim, UMS.Infrastructure.Identity.Constants

### Community 28 - "AppRoles"
Cohesion: 0.67
Nodes (2): AppRoles, UMS.Infrastructure.Identity.Constants

### Community 29 - "SchemaNames"
Cohesion: 0.67
Nodes (2): SchemaNames, UMS.Infrastructure.Persistence.Constants

### Community 30 - "Community 30"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **41 isolated node(s):** `UMS.Infrastructure`, `UMS.Infrastructure.Extensions`, `UMS.Infrastructure.Identity`, `UMS.Infrastructure.Identity`, `UMS.Infrastructure.Identity.Configurations` (+36 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 30`** (1 nodes): `GlobalUsings.cs`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `UMS.Infrastructure`, `UMS.Infrastructure.Extensions`, `UMS.Infrastructure.Identity` to the rest of the system?**
  _41 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `GetUserId / IUserService` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Should `ApplicationDbContext / AddOutboxMessage` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Should `CurrentUserMiddleware / InvokeAsync` be split into smaller, more focused modules?**
  _Cohesion score 0.13 - nodes in this community are weakly interconnected._
- **Should `DistributedCacheService / Remove` be split into smaller, more focused modules?**
  _Cohesion score 0.14 - nodes in this community are weakly interconnected._