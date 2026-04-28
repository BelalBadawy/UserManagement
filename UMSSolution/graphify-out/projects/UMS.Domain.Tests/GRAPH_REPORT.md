# Graph Report - UMS.Domain.Tests  (2026-04-28)

## Corpus Check
- Corpus is ~246 words - fits in a single context window. You may not need a graph.

## Summary
- 16 nodes · 19 edges · 4 communities detected
- Extraction: 63% EXTRACTED · 37% INFERRED · 0% AMBIGUOUS · INFERRED: 7 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_CategoryBuilder  Deleted|CategoryBuilder / Deleted]]
- [[_COMMUNITY_Build  WithParent|Build / WithParent]]
- [[_COMMUNITY_EntityTestExtensions  WithId|EntityTestExtensions / WithId]]
- [[_COMMUNITY_Community 3|Community 3]]

## God Nodes (most connected - your core abstractions)
1. `CategoryBuilder` - 6 edges
2. `CategoryTests` - 4 edges
3. `EntityTestExtensions` - 2 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities

### Community 0 - "CategoryBuilder / Deleted"
Cohesion: 0.4
Nodes (1): CategoryBuilder

### Community 1 - "Build / WithParent"
Cohesion: 0.4
Nodes (1): CategoryTests

### Community 2 - "EntityTestExtensions / WithId"
Cohesion: 0.67
Nodes (1): EntityTestExtensions

### Community 3 - "Community 3"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **Thin community `Community 3`** (1 nodes): `GlobalUsings.cs`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `CategoryBuilder` connect `CategoryBuilder / Deleted` to `Build / WithParent`?**
  _High betweenness centrality (0.330) - this node is a cross-community bridge._
- **Why does `CategoryTests` connect `Build / WithParent` to `CategoryBuilder / Deleted`?**
  _High betweenness centrality (0.197) - this node is a cross-community bridge._