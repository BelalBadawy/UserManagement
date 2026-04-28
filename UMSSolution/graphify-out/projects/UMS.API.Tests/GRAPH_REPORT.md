# Graph Report - UMS.API.Tests  (2026-04-28)

## Corpus Check
- Corpus is ~5,515 words - fits in a single context window. You may not need a graph.

## Summary
- 162 nodes · 290 edges · 11 communities detected
- Extraction: 57% EXTRACTED · 43% INFERRED · 0% AMBIGUOUS · INFERRED: 124 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_ApiTestBase  UseSelfServiceClient|ApiTestBase / UseSelfServiceClient]]
- [[_COMMUNITY_ApiStateVerifier  GetCategoryByIdAsync|ApiStateVerifier / GetCategoryByIdAsync]]
- [[_COMMUNITY_ApiTestAuthenticationHeaderHelper  Clear|ApiTestAuthenticationHeaderHelper / Clear]]
- [[_COMMUNITY_AccountEndpointsTests  ConfirmEmail_UnknownUser_ReturnsUnsuccessfulPayload|AccountEndpointsTests / ConfirmEmail_UnknownUser_ReturnsUnsuccessfulPayload]]
- [[_COMMUNITY_GetUserByIdAsync  UserEndpointsTests|GetUserByIdAsync / UserEndpointsTests]]
- [[_COMMUNITY_ApiTestDataSeeder  ClearCategoryCaches|ApiTestDataSeeder / ClearCategoryCaches]]
- [[_COMMUNITY_ApiPermissionHelper  GetRequiredPermission|ApiPermissionHelper / GetRequiredPermission]]
- [[_COMMUNITY_ApiTestEmailService  SendAsync|ApiTestEmailService / SendAsync]]
- [[_COMMUNITY_PagedResultContract  ResponseContract|PagedResultContract / ResponseContract]]
- [[_COMMUNITY_ApiCollectionDefinition|ApiCollectionDefinition]]
- [[_COMMUNITY_Community 10|Community 10]]

## God Nodes (most connected - your core abstractions)
1. `UserEndpointsTests` - 19 edges
2. `AccountEndpointsTests` - 16 edges
3. `CustomWebApplicationFactory` - 11 edges
4. `CategoryEndpointsTests` - 10 edges
5. `RoleEndpointsTests` - 9 edges
6. `ApiTestBase` - 7 edges
7. `ApiStateVerifier` - 7 edges
8. `DisableTwoFactorAuthEndpointTests` - 6 edges
9. `ApiTestAuthenticationHeaderHelper` - 6 edges
10. `ApiTestDataSeeder` - 6 edges

## Surprising Connections (you probably didn't know these)
- `AccountEndpointsTests` --inherits--> `ApiTestBase`  [EXTRACTED]
  C:\_MyFolder\MyApps\UserManagement\UMSSolution\UMS.API.Tests\Endpoints\AccountEndpointsTests.cs →   _Bridges community 3 → community 0_
- `CategoryEndpointsTests` --inherits--> `ApiTestBase`  [EXTRACTED]
  C:\_MyFolder\MyApps\UserManagement\UMSSolution\UMS.API.Tests\Endpoints\CategoryEndpointsTests.cs →   _Bridges community 0 → community 5_
- `RoleEndpointsTests` --inherits--> `ApiTestBase`  [EXTRACTED]
  C:\_MyFolder\MyApps\UserManagement\UMSSolution\UMS.API.Tests\Endpoints\RoleEndpointsTests.cs →   _Bridges community 0 → community 1_
- `UserEndpointsTests` --inherits--> `ApiTestBase`  [EXTRACTED]
  C:\_MyFolder\MyApps\UserManagement\UMSSolution\UMS.API.Tests\Endpoints\UserEndpointsTests.cs →   _Bridges community 0 → community 4_

## Communities

### Community 0 - "ApiTestBase / UseSelfServiceClient"
Cohesion: 0.07
Nodes (8): ApiTestBase, ConfirmTwoFactorAuthEndpointTests, DisableTwoFactorAuthEndpointTests, EnableTwoFactorAuthEndpointTests, LoginWith2FAEndpointTests, LogoutEndpointTests, ProfileEndpointTests, SetupTwoFactorAuthEndpointTests

### Community 1 - "ApiStateVerifier / GetCategoryByIdAsync"
Cohesion: 0.16
Nodes (4): ApiStateVerifier, ApiTestBase, IClassFixture, RoleEndpointsTests

### Community 2 - "ApiTestAuthenticationHeaderHelper / Clear"
Cohesion: 0.12
Nodes (5): ApiTestAuthenticationHeaderHelper, ApiTestDatabaseInitializer, CustomWebApplicationFactory, IAsyncLifetime, WebApplicationFactory

### Community 3 - "AccountEndpointsTests / ConfirmEmail_UnknownUser_ReturnsUnsuccessfulPayload"
Cohesion: 0.13
Nodes (2): AccountEndpointsTests, ApiTestEmailSink

### Community 4 - "GetUserByIdAsync / UserEndpointsTests"
Cohesion: 0.17
Nodes (1): UserEndpointsTests

### Community 5 - "ApiTestDataSeeder / ClearCategoryCaches"
Cohesion: 0.29
Nodes (2): ApiTestDataSeeder, CategoryEndpointsTests

### Community 6 - "ApiPermissionHelper / GetRequiredPermission"
Cohesion: 0.25
Nodes (3): ApiPermissionHelper, ApiTestAuthenticationHandler, AuthenticationHandler

### Community 7 - "ApiTestEmailService / SendAsync"
Cohesion: 0.5
Nodes (2): ApiTestEmailService, IEmailService

### Community 8 - "PagedResultContract / ResponseContract"
Cohesion: 0.5
Nodes (3): PagedResultContract, ResponseContract, RoleClaimResponseContract

### Community 9 - "ApiCollectionDefinition"
Cohesion: 1.0
Nodes (1): ApiCollectionDefinition

### Community 10 - "Community 10"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **4 isolated node(s):** `ResponseContract`, `PagedResultContract`, `RoleClaimResponseContract`, `ApiCollectionDefinition`
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `ApiCollectionDefinition`** (2 nodes): `TestCollectionDefinitions.cs`, `ApiCollectionDefinition`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 10`** (1 nodes): `GlobalUsings.cs`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AccountEndpointsTests` connect `AccountEndpointsTests / ConfirmEmail_UnknownUser_ReturnsUnsuccessfulPayload` to `ApiTestBase / UseSelfServiceClient`?**
  _High betweenness centrality (0.125) - this node is a cross-community bridge._
- **Why does `UserEndpointsTests` connect `GetUserByIdAsync / UserEndpointsTests` to `ApiTestBase / UseSelfServiceClient`, `AccountEndpointsTests / ConfirmEmail_UnknownUser_ReturnsUnsuccessfulPayload`?**
  _High betweenness centrality (0.087) - this node is a cross-community bridge._
- **What connects `ResponseContract`, `PagedResultContract`, `RoleClaimResponseContract` to the rest of the system?**
  _4 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `ApiTestBase / UseSelfServiceClient` be split into smaller, more focused modules?**
  _Cohesion score 0.07 - nodes in this community are weakly interconnected._
- **Should `ApiTestAuthenticationHeaderHelper / Clear` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._
- **Should `AccountEndpointsTests / ConfirmEmail_UnknownUser_ReturnsUnsuccessfulPayload` be split into smaller, more focused modules?**
  _Cohesion score 0.13 - nodes in this community are weakly interconnected._