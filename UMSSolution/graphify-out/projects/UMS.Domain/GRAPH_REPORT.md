# Graph Report - UMS.Domain  (2026-04-28)

## Corpus Check
- Corpus is ~1,131 words - fits in a single context window. You may not need a graph.

## Summary
- 47 nodes · 37 edges · 13 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_AuditTrail  BaseEntity|AuditTrail / BaseEntity]]
- [[_COMMUNITY_Category  IDataConcurrency|Category / IDataConcurrency]]
- [[_COMMUNITY_IAuditable  IFullEntity|IAuditable / IFullEntity]]
- [[_COMMUNITY_BaseEntity  IEntity|BaseEntity / IEntity]]
- [[_COMMUNITY_DomainEvent  IDomainEvent|DomainEvent / IDomainEvent]]
- [[_COMMUNITY_IAuditable|IAuditable]]
- [[_COMMUNITY_IDataConcurrency|IDataConcurrency]]
- [[_COMMUNITY_IDomainEvent|IDomainEvent]]
- [[_COMMUNITY_IEntity|IEntity]]
- [[_COMMUNITY_IMustHaveTenant|IMustHaveTenant]]
- [[_COMMUNITY_ISoftDelete|ISoftDelete]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]

## God Nodes (most connected - your core abstractions)
1. `Category` - 4 edges
2. `IFullEntity` - 4 edges
3. `IEntity` - 3 edges
4. `BaseEntity` - 2 edges
5. `DomainEvent` - 2 edges
6. `AuditTrail` - 2 edges
7. `LogUserActivity` - 2 edges
8. `OutboxMessage` - 2 edges
9. `UMS.Domain.Common` - 1 edges
10. `UMS.Domain.Common` - 1 edges

## Surprising Connections (you probably didn't know these)
- `Category` --inherits--> `BaseEntity`  [EXTRACTED]
  C:\_MyFolder\MyApps\UserManagement\UMSSolution\UMS.Domain\Entities\Category.cs →   _Bridges community 0 → community 1_
- `IFullEntity` --inherits--> `IDataConcurrency`  [EXTRACTED]
  C:\_MyFolder\MyApps\UserManagement\UMSSolution\UMS.Domain\Interfaces\IFullEntity.cs →   _Bridges community 1 → community 2_

## Communities

### Community 0 - "AuditTrail / BaseEntity"
Cohesion: 0.22
Nodes (6): AuditTrail, UMS.Domain.Entities, BaseEntity, LogUserActivity, OutboxMessage, UMS.Domain.Entities

### Community 1 - "Category / IDataConcurrency"
Cohesion: 0.4
Nodes (4): Category, UMS.Domain.Entities, IDataConcurrency, IFullEntity

### Community 2 - "IAuditable / IFullEntity"
Cohesion: 0.4
Nodes (4): IAuditable, IFullEntity, UMS.Domain.Interfaces, ISoftDelete

### Community 3 - "BaseEntity / IEntity"
Cohesion: 0.5
Nodes (3): BaseEntity, UMS.Domain.Common, IEntity

### Community 4 - "DomainEvent / IDomainEvent"
Cohesion: 0.5
Nodes (3): DomainEvent, UMS.Domain.Common, IDomainEvent

### Community 5 - "IAuditable"
Cohesion: 0.67
Nodes (2): IAuditable, UMS.Domain.Interfaces

### Community 6 - "IDataConcurrency"
Cohesion: 0.67
Nodes (2): IDataConcurrency, UMS.Domain.Interfaces

### Community 7 - "IDomainEvent"
Cohesion: 0.67
Nodes (2): IDomainEvent, UMS.Domain.Interfaces

### Community 8 - "IEntity"
Cohesion: 1.0
Nodes (2): IEntity, UMS.Domain.Interfaces

### Community 9 - "IMustHaveTenant"
Cohesion: 0.67
Nodes (2): IMustHaveTenant, UMS.Domain.Interfaces

### Community 10 - "ISoftDelete"
Cohesion: 0.67
Nodes (2): ISoftDelete, UMS.Domain.Interfaces

### Community 11 - "Community 11"
Cohesion: 1.0
Nodes (0): 

### Community 12 - "Community 12"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **17 isolated node(s):** `UMS.Domain.Common`, `UMS.Domain.Common`, `UMS.Domain.Entities`, `UMS.Domain.Entities`, `UMS.Domain.Entities` (+12 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 11`** (1 nodes): `GlobalUsings.cs`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 12`** (1 nodes): `DomainEnums.cs`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Category` connect `Category / IDataConcurrency` to `AuditTrail / BaseEntity`?**
  _High betweenness centrality (0.098) - this node is a cross-community bridge._
- **Why does `IFullEntity` connect `IAuditable / IFullEntity` to `Category / IDataConcurrency`?**
  _High betweenness centrality (0.059) - this node is a cross-community bridge._
- **What connects `UMS.Domain.Common`, `UMS.Domain.Common`, `UMS.Domain.Entities` to the rest of the system?**
  _17 weakly-connected nodes found - possible documentation gaps or missing edges._