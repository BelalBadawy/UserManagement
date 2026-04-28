# Graph Report - UMS.API  (2026-04-28)

## Corpus Check
- Corpus is ~7,316 words - fits in a single context window. You may not need a graph.

## Summary
- 41 nodes · 38 edges · 9 communities detected
- Extraction: 76% EXTRACTED · 21% INFERRED · 3% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.77)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_CategoryEndpoints  MapCategoryEndpoints|CategoryEndpoints / MapCategoryEndpoints]]
- [[_COMMUNITY_ServiceCollectionExtensions  AddApiVersioningConfig|ServiceCollectionExtensions / AddApiVersioningConfig]]
- [[_COMMUNITY_BearerSchemeTransformer  TransformAsync|BearerSchemeTransformer / TransformAsync]]
- [[_COMMUNITY_ErrorHandlingMiddleware  HandleExceptionAsync|ErrorHandlingMiddleware / HandleExceptionAsync]]
- [[_COMMUNITY_Banner Image 1  Folded Clothes Stack|Banner Image 1 / Folded Clothes Stack]]
- [[_COMMUNITY_AccountEndpoints  MapAccountEndpoints|AccountEndpoints / MapAccountEndpoints]]
- [[_COMMUNITY_UserEndpoints  MapUserEndpoints|UserEndpoints / MapUserEndpoints]]
- [[_COMMUNITY_SD|SD]]
- [[_COMMUNITY_Program|Program]]

## God Nodes (most connected - your core abstractions)
1. `Banner Image 1` - 4 edges
2. `ServiceCollectionExtensions` - 3 edges
3. `BearerSchemeTransformer` - 3 edges
4. `ErrorHandlingMiddleware` - 3 edges
5. `Minimalist Aesthetic` - 3 edges
6. `Wardrobe or Lifestyle Promotion` - 3 edges
7. `AccountEndpoints` - 2 edges
8. `CategoryEndpoints` - 2 edges
9. `RoleEndpoints` - 2 edges
10. `UserEndpoints` - 2 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities

### Community 0 - "CategoryEndpoints / MapCategoryEndpoints"
Cohesion: 0.2
Nodes (4): CategoryEndpoints, UMS.API.Endpoints, ResponseResultExtensions, RoleEndpoints

### Community 1 - "ServiceCollectionExtensions / AddApiVersioningConfig"
Cohesion: 0.4
Nodes (2): ServiceCollectionExtensions, UMS.API

### Community 2 - "BearerSchemeTransformer / TransformAsync"
Cohesion: 0.4
Nodes (3): BearerSchemeTransformer, UMS.API.Helpers, IOpenApiDocumentTransformer

### Community 3 - "ErrorHandlingMiddleware / HandleExceptionAsync"
Cohesion: 0.5
Nodes (2): ErrorHandlingMiddleware, UMS.API

### Community 4 - "Banner Image 1 / Folded Clothes Stack"
Cohesion: 0.7
Nodes (5): Banner Image 1, Folded Clothes Stack, Minimalist Aesthetic, Wardrobe or Lifestyle Promotion, White Chair

### Community 5 - "AccountEndpoints / MapAccountEndpoints"
Cohesion: 0.67
Nodes (1): AccountEndpoints

### Community 6 - "UserEndpoints / MapUserEndpoints"
Cohesion: 0.67
Nodes (1): UserEndpoints

### Community 7 - "SD"
Cohesion: 0.67
Nodes (2): SD, UMS.API.Helpers

### Community 8 - "Program"
Cohesion: 1.0
Nodes (1): Program

## Ambiguous Edges - Review These
- `Banner Image 1` → `Wardrobe or Lifestyle Promotion`  [AMBIGUOUS]
  UMS.API/wwwroot/images/banners/1.jpg · relation: conceptually_related_to

## Knowledge Gaps
- **7 isolated node(s):** `Program`, `UMS.API`, `UMS.API.Endpoints`, `UMS.API.Helpers`, `UMS.API.Helpers` (+2 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Program`** (2 nodes): `Program`, `Program.cs`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Banner Image 1` and `Wardrobe or Lifestyle Promotion`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Are the 3 inferred relationships involving `Minimalist Aesthetic` (e.g. with `Banner Image 1` and `White Chair`) actually correct?**
  _`Minimalist Aesthetic` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Program`, `UMS.API`, `UMS.API.Endpoints` to the rest of the system?**
  _7 weakly-connected nodes found - possible documentation gaps or missing edges._