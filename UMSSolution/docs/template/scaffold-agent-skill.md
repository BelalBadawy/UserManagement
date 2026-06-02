# Scaffold Agent Skill

Ask for `ProjectName` if it is not already provided. Accept only values matching `^[A-Z][A-Za-z0-9]*$`, and reject C# keywords.

## Execution

PowerShell:

```powershell
./Scaffold.ps1 -ProjectName MyProduct
```

Bash:

```bash
./Scaffold.sh --ProjectName MyProduct
```

## Rules

1. Create `{ProjectName}.slnx` with `dotnet new sln -n {ProjectName} -f slnx`.
2. Create projects in this order: Domain, Application, Infrastructure, API, Domain.Tests, Application.Tests, Infrastructure.Tests, API.Tests.
3. Add every project to the solution, then add project references exactly as the script does.
4. Remove template stubs before writing embedded files.
5. Recreate the full backend, tests, and `{ProjectName}.Client` tree from inline content only.
6. Replace `UMS` with `{ProjectName}` in namespaces, project names, paths, and config values that identify the solution.
7. Replace the client `package.json` name placeholder before running `npm install`.
8. Write text files as UTF-8 without BOM.
9. Use single-quoted here-strings in PowerShell and quoted heredocs in Bash.
10. If `npm` is unavailable, warn instead of failing silently.
11. Do not depend on external template folders or repo copies.

The generated `Scaffold.ps1` and `Scaffold.sh` are the canonical self-contained payloads.
