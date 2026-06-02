# How To Use This Template

This folder contains a fully self-contained scaffolding export of the current solution:

- `scaffold-agent-skill.md`
- `Scaffold.ps1`
- `Scaffold.sh`

## What It Does

The scripts recreate the full solution for a new project name, including:

- the `.NET 10` backend projects
- the test projects
- the React client
- embedded source files, config files, and assets

No external template folder is required.

## Choose A Project Name

Use a `ProjectName` that:

- matches `^[A-Z][A-Za-z0-9]*$`
- is not a C# keyword

Examples:

- `MyProduct`
- `InventoryPortal`
- `UserManagement`

## PowerShell Usage

From the repository root:

```powershell
.\docs\template\Scaffold.ps1 -ProjectName MyProduct
```

To create the new solution in a different parent folder:

```powershell
.\docs\template\Scaffold.ps1 -ProjectName MyProduct -OutputPath D:\Projects
```

## Bash Usage

From the repository root:

```bash
./docs/template/Scaffold.sh --ProjectName MyProduct
```

To create the new solution in a different parent folder:

```bash
./docs/template/Scaffold.sh --ProjectName MyProduct --OutputPath /workspace/projects
```

## What Happens During Execution

1. A new folder named after `ProjectName` is created.
2. A `{ProjectName}.slnx` file is created.
3. All backend, test, and client projects are generated.
4. Template stub files are removed.
5. Embedded files are written with namespace and project-name replacement.
6. `dotnet restore` runs.
7. `npm install` runs for `{ProjectName}.Client` if `npm` is available.

## Output

After success, you will get a new folder like:

```text
MyProduct/
  MyProduct.slnx
  MyProduct.API/
  MyProduct.Application/
  MyProduct.Domain/
  MyProduct.Infrastructure/
  MyProduct.API.Tests/
  MyProduct.Application.Tests/
  MyProduct.Domain.Tests/
  MyProduct.Infrastructure.Tests/
  MyProduct.Client/
```

## Notes

- If the target output folder already exists, the scripts stop instead of overwriting it.
- If scaffolding fails partway through, the scripts try to clean up the partial output.
- If `npm` is not installed, the scripts warn you and you can run `npm install` manually inside `{ProjectName}.Client`.
- The scripts are very large because they embed the full solution inline by design.
