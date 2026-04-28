# Graph Report - UMS.Infrastructure.Tests  (2026-04-28)

## Corpus Check
- Corpus is ~6,258 words - fits in a single context window. You may not need a graph.

## Summary
- 192 nodes · 293 edges · 14 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_UserServiceAuthTests  ConfirmTwoFactorAuthAsync_NoAuthenticatorKeyExists_ReturnsFail|UserServiceAuthTests / ConfirmTwoFactorAuthAsync_NoAuthenticatorKeyExists_ReturnsFail]]
- [[_COMMUNITY_ChangeUserPasswordAsync_WhenPasswordChangeFails_ReturnsFail  ChangeUserStatusAsync_WhenActivating_ReturnsActivatedMessage|ChangeUserPasswordAsync_WhenPasswordChangeFails_ReturnsFail / ChangeUserStatusAsync_WhenActivating_ReturnsActivatedMessage]]
- [[_COMMUNITY_UserServiceTests  ChangeUserPasswordAsync_WhenSuccessful_ReturnsSuccess|UserServiceTests / ChangeUserPasswordAsync_WhenSuccessful_ReturnsSuccess]]
- [[_COMMUNITY_RoleServiceTests  CreateRoleAsync_WhenCreateFails_ReturnsFail|RoleServiceTests / CreateRoleAsync_WhenCreateFails_ReturnsFail]]
- [[_COMMUNITY_CurrentUserServiceTests  AuthenticatedPrincipal|CurrentUserServiceTests / AuthenticatedPrincipal]]
- [[_COMMUNITY_EnumerableQuery  IAsyncEnumerable|EnumerableQuery / IAsyncEnumerable]]
- [[_COMMUNITY_InMemorySessionWrapperTests  Build|InMemorySessionWrapperTests / Build]]
- [[_COMMUNITY_IClassFixture  LocalFileStorageServiceTests|IClassFixture / LocalFileStorageServiceTests]]
- [[_COMMUNITY_DistributedCacheServiceTests  Remove_DelegatesToUnderlyingCache|DistributedCacheServiceTests / Remove_DelegatesToUnderlyingCache]]
- [[_COMMUNITY_IDisposable  TempDirectoryFixture|IDisposable / TempDirectoryFixture]]
- [[_COMMUNITY_DateTimeServiceTests  NowUtc_KindIsUtc|DateTimeServiceTests / NowUtc_KindIsUtc]]
- [[_COMMUNITY_IdentityMockFactory  CreateRoleManager|IdentityMockFactory / CreateRoleManager]]
- [[_COMMUNITY_MailSenderServiceTests  SendAsync_should_configure_smtp_ssl_from_options|MailSenderServiceTests / SendAsync_should_configure_smtp_ssl_from_options]]
- [[_COMMUNITY_Community 13|Community 13]]

## God Nodes (most connected - your core abstractions)
1. `UserServiceTests` - 58 edges
2. `UserServiceAuthTests` - 31 edges
3. `RoleServiceTests` - 28 edges
4. `CurrentUserServiceTests` - 18 edges
5. `LocalFileStorageServiceTests` - 7 edges
6. `InMemorySessionWrapperTests` - 7 edges
7. `DistributedCacheServiceTests` - 5 edges
8. `TestAsyncQueryProvider` - 5 edges
9. `TestAsyncEnumerable` - 5 edges
10. `TestAsyncEnumerator` - 4 edges

## Surprising Connections (you probably didn't know these)
- `RoleServiceTests` --inherits--> `IDisposable`  [EXTRACTED]
  C:\_MyFolder\MyApps\UserManagement\UMSSolution\UMS.Infrastructure.Tests\Identity\Services\RoleServiceTests.cs →   _Bridges community 9 → community 3_

## Communities

### Community 0 - "UserServiceAuthTests / ConfirmTwoFactorAuthAsync_NoAuthenticatorKeyExists_ReturnsFail"
Cohesion: 0.12
Nodes (1): UserServiceAuthTests

### Community 1 - "ChangeUserPasswordAsync_WhenPasswordChangeFails_ReturnsFail / ChangeUserStatusAsync_WhenActivating_ReturnsActivatedMessage"
Cohesion: 0.07
Nodes (0): 

### Community 2 - "UserServiceTests / ChangeUserPasswordAsync_WhenSuccessful_ReturnsSuccess"
Cohesion: 0.07
Nodes (1): UserServiceTests

### Community 3 - "RoleServiceTests / CreateRoleAsync_WhenCreateFails_ReturnsFail"
Cohesion: 0.12
Nodes (1): RoleServiceTests

### Community 4 - "CurrentUserServiceTests / AuthenticatedPrincipal"
Cohesion: 0.26
Nodes (1): CurrentUserServiceTests

### Community 5 - "EnumerableQuery / IAsyncEnumerable"
Cohesion: 0.12
Nodes (8): EnumerableQuery, IAsyncEnumerable, IAsyncEnumerator, IAsyncQueryProvider, IQueryable, TestAsyncEnumerable, TestAsyncEnumerator, TestAsyncQueryProvider

### Community 6 - "InMemorySessionWrapperTests / Build"
Cohesion: 0.36
Nodes (2): InMemorySessionWrapperTests, SessionPayload

### Community 7 - "IClassFixture / LocalFileStorageServiceTests"
Cohesion: 0.25
Nodes (2): IClassFixture, LocalFileStorageServiceTests

### Community 8 - "DistributedCacheServiceTests / Remove_DelegatesToUnderlyingCache"
Cohesion: 0.33
Nodes (1): DistributedCacheServiceTests

### Community 9 - "IDisposable / TempDirectoryFixture"
Cohesion: 0.5
Nodes (2): IDisposable, TempDirectoryFixture

### Community 10 - "DateTimeServiceTests / NowUtc_KindIsUtc"
Cohesion: 0.5
Nodes (1): DateTimeServiceTests

### Community 11 - "IdentityMockFactory / CreateRoleManager"
Cohesion: 0.5
Nodes (1): IdentityMockFactory

### Community 12 - "MailSenderServiceTests / SendAsync_should_configure_smtp_ssl_from_options"
Cohesion: 0.67
Nodes (1): MailSenderServiceTests

### Community 13 - "Community 13"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **1 isolated node(s):** `SessionPayload`
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 13`** (1 nodes): `GlobalUsings.cs`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `UserServiceTests` connect `UserServiceTests / ChangeUserPasswordAsync_WhenSuccessful_ReturnsSuccess` to `ChangeUserPasswordAsync_WhenPasswordChangeFails_ReturnsFail / ChangeUserStatusAsync_WhenActivating_ReturnsActivatedMessage`?**
  _High betweenness centrality (0.072) - this node is a cross-community bridge._
- **Why does `RoleServiceTests` connect `RoleServiceTests / CreateRoleAsync_WhenCreateFails_ReturnsFail` to `IDisposable / TempDirectoryFixture`, `EnumerableQuery / IAsyncEnumerable`?**
  _High betweenness centrality (0.046) - this node is a cross-community bridge._
- **What connects `SessionPayload` to the rest of the system?**
  _1 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `UserServiceAuthTests / ConfirmTwoFactorAuthAsync_NoAuthenticatorKeyExists_ReturnsFail` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._
- **Should `ChangeUserPasswordAsync_WhenPasswordChangeFails_ReturnsFail / ChangeUserStatusAsync_WhenActivating_ReturnsActivatedMessage` be split into smaller, more focused modules?**
  _Cohesion score 0.07 - nodes in this community are weakly interconnected._
- **Should `UserServiceTests / ChangeUserPasswordAsync_WhenSuccessful_ReturnsSuccess` be split into smaller, more focused modules?**
  _Cohesion score 0.07 - nodes in this community are weakly interconnected._
- **Should `RoleServiceTests / CreateRoleAsync_WhenCreateFails_ReturnsFail` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._