# Implementation Plan: Solution Scaffolding Export

## Goal

Generate three self-contained deliverables that can recreate the current `UMSSolution` for any new project name:

1. `scaffold-agent-skill.md`
2. `Scaffold.ps1`
3. `Scaffold.sh`

## Constraints

- Do not scan or include build/cache/dependency folders such as `bin`, `obj`, `node_modules`, `.git`, `.vs`, `dist`, `packages`, `TestResults`, `coverage`, `.sonarqube`, and `wwwroot/lib`.
- Scripts must be fully self-contained and may not depend on external template files.
- All `UMS` root-namespace and project-name usages that should vary by solution name must be replaced with a project placeholder.
- The React client must be scaffolded too if it is part of the current workspace.
- Per repo instructions, implementation work on the actual deliverables starts only after this plan is reviewed and approved.

## Current Context

- Solution file: `UMSSolution.slnx`
- .NET projects currently in solution: `UMS.API`, `UMS.Application`, `UMS.Domain`, `UMS.Infrastructure`, `UMS.API.Tests`, `UMS.Application.Tests`, `UMS.Domain.Tests`, `UMS.Infrastructure.Tests`
- Frontend project present outside solution: `UMS.Client`
- Graphify report indicates the main backend hubs are API service registration, application startup, account/user endpoints, shared constants, and response flow, which matches the expected scaffold surface.

## Key Decisions

### Solution Recreation Strategy

- Primary approach: use `dotnet new sln -n {ProjectName}` followed by `dotnet sln add` so the scaffold is portable and CLI-driven.
- During extraction, verify how the installed .NET 10 SDK handles solution format selection so the generated solution ends up as `.slnx` rather than drifting to `.sln`.
- Verification step: compare the source `UMSSolution.slnx` against the generated structure to detect any solution folders, ordering constraints, or custom solution-level configuration that the CLI approach would lose.
- Fallback: if the source `.slnx` contains custom structure that matters, add a post-creation step that writes a minimal inline `.slnx` template preserving those details and XML-escaping generated names or paths as needed.

### Rename Boundary

- Rename `UMS` to the project placeholder when it appears in:
  - C# namespaces and `using` directives
  - assembly names, root namespaces, and project names in `.csproj`
  - project-reference paths and solution project paths
  - config keys, config values, connection-string names, issuer/audience values, and other identifiers that are project-specific
  - frontend package name, client folder name, proxy/config paths, and project-specific URLs or labels
- Keep `UMS` unchanged when it appears in:
  - third-party namespaces or framework identifiers where it is not the project token
  - generic ignore patterns or tooling metadata where replacement would be incorrect
  - literals that are intentionally product/domain terminology rather than project identity, unless the surrounding usage proves they are meant to be renamed
- Phase 1 output will classify `UMS` occurrences into `rename` vs `keep` so the transformation is auditable.

## Planned Phases

### Phase 1: Inventory and Extraction

- Enumerate the allowed source tree while honoring the ignore rules.
- Produce a directory inventory for all source directories, including empty folders, so scripts can recreate the full tree explicitly.
- Capture the exact `UMSSolution.slnx` content.
- Read every `.csproj` and record:
  - target frameworks
  - package references and exact versions
  - project references
  - implicit and explicit build settings required to recreate the projects, including:
    - `ImplicitUsings`
    - `Nullable`
    - `TreatWarningsAsErrors`
    - `NoWarn`
    - custom `ItemGroup` entries
    - `PropertyGroup` condition blocks
    - any other project-level settings that `dotnet new` would not reproduce by default
- Read all scaffold-relevant source/config/assets for:
  - backend projects
  - test projects
  - frontend project
- Explicitly include these file categories if present:
  - `GlobalUsings.cs`
  - `launchSettings.json`
  - `.editorconfig`
  - `.gitignore`
  - `*.props`
  - `*.targets`
  - `Dockerfile`
  - `docker-compose*.yml`
  - `README.md`
  - any other non-ignored, manually maintained file that affects build, runtime, or developer setup
- Build a rename map of every line where `UMS` appears in namespaces, usings, assembly/project names, config keys, paths, and user-facing strings that should be parameterized.

### Phase 2: Scaffolding Design

- Define a reusable placeholder strategy such as `___PROJECTNAME___` so embedded file bodies remain literal-safe.
- Derive the exact project creation order and reference wiring for the .NET projects.
  - Required creation order: `Domain -> Application -> Infrastructure -> API -> test projects`.
- Derive an explicit directory-creation pass for all source folders, including empty directories not created by `dotnet new`.
- Derive the frontend recreation order, including package installation and any project-name-sensitive settings.
- Decide the output layout and helper functions shared by both scripts.
- Add script-level safety behavior:
  - validate `ProjectName` against `^[A-Z][A-Za-z0-9]*$`
  - reject names that collide with C# keywords
  - abort if the target directory already exists
  - wrap scaffolding in failure handling that cleans up a partial scaffolded root
  - include optional verbose/progress-friendly output
- Add guarded frontend dependency installation:
  - ensure frontend files, especially `package.json`, are written and placeholder-replaced before any `npm install` step
  - run `npm install` only if `npm` is available
  - otherwise emit a clear warning telling the user how to finish manually
- Add a template-cleanup pass after all `dotnet new` commands to remove generated stubs that would otherwise pollute the scaffold:
  - `Class1.cs`
  - `UnitTest1.cs`
  - `WeatherForecast.cs`
  - any other template-default files replaced by embedded scaffold content

### Phase 3: Deliverable Generation

- Create `scaffold-agent-skill.md` with:
  - `ProjectName` input contract
  - step-by-step scaffolding workflow
  - exact package/reference/project creation guidance
  - inline file-writing instructions with full namespace replacement
- Include the `.slnx` strategy explicitly in the skill instructions, including the fallback template rule if source inspection shows CLI lossiness.
- Create `Scaffold.ps1` with:
  - mandatory `-ProjectName`
  - directory creation
  - `dotnet new`, `dotnet sln add`, `dotnet add reference`, `dotnet add package`
  - removal of template-generated stub files before writing embedded replacements
  - inline here-strings for every required file
  - placeholder replacement before writing files
  - explicit UTF-8 without BOM file output with normalized Windows line endings
  - guarded `npm install`
  - cleanup-on-failure behavior
- Create `Scaffold.sh` with the Bash equivalent behavior and quoted heredocs.
  - Include the same validation, template-stub cleanup, guarded `npm install`, and cleanup behavior as the PowerShell script.
  - Use quoted heredocs consistently so embedded C# and TypeScript content is never shell-expanded.
  - Ensure file output is UTF-8 without BOM with normalized Unix line endings.

### Phase 4: Verification

- Sanity-check that all required files from the current solution are represented in the generated outputs.
- Verify that package versions and project references match the source solution.
- Verify that every inventoried source directory, including empty ones, is recreated by the scripts.
- Verify that `.slnx` generation preserves any source solution details that matter, or that the fallback template handles them.
- Confirm the placeholder replacement path is consistent across backend and frontend artifacts.
- Confirm the frontend `package.json` replacement happens before any `npm install` invocation.
- Run `graphify update .` after file creation to satisfy repo maintenance instructions.

## Expected Risks

- The workspace likely contains a large number of source files, so script size will be substantial.
- Some `UMS` occurrences still require judgment even with the rename rules, so the `rename` vs `keep` classification needs careful review during extraction.
- Frontend dependencies may be version-sensitive and should be preserved exactly as declared.

## Approval Checkpoint

After approval of this plan, I will perform the full repository extraction and generate the three requested files.
