---
description: "Track and visualize dependencies between repos in the workspace"
---

# Cross-Repo Dependency Graph

> **Version:** 1.0
> **Scope:** Track and visualize dependencies between repos in the workspace
> **Integration:** Works with `/plan-feature` (multi-repo), `/ship`, and deployment commands

## When to Activate

Task keywords: `cross-repo`, `dependency graph`, `repo dependency`, `shared types`, `shared package`, `monorepo`, `workspace`, `multi-repo`, `depends on`, `consumes`

## Dependency Types

### 1. Package Dependencies

One repo depends on a package published by another repo:

```
Repo A (consumer) → npm package → Repo B (producer)
```

**Examples:**
- `ClearPathOS` depends on `@personal/shared-types` from `SharedTypes` repo
- `example-app` depends on `@personal/ui-components` from `UIComponents` repo

### 2. Schema Dependencies

One repo's database schema references another repo's types:

```
Repo A (consumer) → schema references → Repo B (producer)
```

**Examples:**
- `ProjectTracker` schema references types from `SharedTypes` repo

### 3. API Dependencies

One repo's API calls another repo's API:

```
Repo A (consumer) → HTTP/gRPC → Repo B (producer)
```

**Examples:**
- `example-dashboard` calls API from `ClearPathOS`

### 4. Configuration Dependencies

One repo shares configuration with another repo:

```
Repo A (consumer) ← shared config → Repo B (producer)
```

**Examples:**
- All repos share `tsconfig.base.json` from `SharedConfig` repo

## Dependency Detection

### Automated Detection

```bash
# Find all package.json files
find . -name "package.json" -path "*/repos/*" -exec grep -l "personal/" {} \;

# Find cross-repo imports
grep -r "from '@personal/" --include="*.ts" --include="*.tsx" .

# Find shared type references
grep -r "shared-types\|shared-ui\|shared-config" --include="*.ts" --include="*.json" .
```

### Manual Registration

Add to `.opencode/dependency-graph.yaml`:

```yaml
dependencies:
  ClearPathOS:
    packages:
      - "@personal/shared-types"
      - "@personal/ui-components"
    apis:
      - "ClearPathOS API"
    schemas:
      - "SharedTypes.User"
    configs:
      - "tsconfig.base.json"
  
  example-app:
    packages:
      - "@personal/shared-types"
    apis: []
    schemas: []
    configs:
      - "tsconfig.base.json"
  
  SharedTypes:
    packages: []
    apis: []
    schemas: []
    configs: []
    consumers:
      - "ClearPathOS"
      - "example-app"
      - "ProjectTracker"
```

## Dependency Analysis

### Impact Analysis

Before changing a shared package:

1. **Identify consumers:**
   ```bash
   grep -r "@personal/shared-types" --include="package.json" .
   ```

2. **Assess impact:**
   - How many repos are affected?
   - What types/interfaces are changing?
   - Is the change breaking?

3. **Plan deployment order:**
   - Update producer repo first
   - Publish new version
   - Update consumer repos
   - Test all consumers

### Breaking Change Detection

```yaml
breaking_changes:
  - type: "Removed export"
    impact: "All consumers will fail to compile"
    mitigation: "Deprecate first, remove in next major version"
  
  - type: "Changed type signature"
    impact: "Consumers may have type errors"
    mitigation: "Use overloads or union types for transition"
  
  - type: "Changed API endpoint"
    impact: "API consumers will get 404s"
    mitigation: "Maintain old endpoint with deprecation notice"
```

## Deployment Order

### Rule: Producer Before Consumer

When updating shared packages:

1. **Update producer repo** (e.g., `SharedTypes`)
2. **Publish new version** (e.g., `@personal/shared-types@2.0.0`)
3. **Update consumer repos** (e.g., `ClearPathOS`, `example-app`)
4. **Test all consumers**
5. **Deploy consumers**

### Rule: API Versioning

When changing APIs:

1. **Add new endpoint** (don't remove old one)
2. **Update consumers to use new endpoint**
3. **Deprecate old endpoint**
4. **Remove old endpoint after transition period**

## Dependency Health Monitoring

### Metrics to Track

| Metric | Target | Critical |
|---|---|---|
| **Dependency freshness** | <30 days outdated | >90 days |
| **Breaking change frequency** | <1 per month | >2 per month |
| **Consumer update lag** | <7 days | >30 days |
| **Dependency count** | <10 per repo | >20 per repo |

### Alerts

- Shared package not updated in 90 days
- Consumer repo not updated after producer change
- Breaking change published without notice
- Circular dependency detected

## Integration with Development Workflow

### Before Changing Shared Code

1. Run dependency analysis
2. Identify all consumers
3. Assess impact of change
4. Plan deployment order
5. Communicate with consumer repo owners

### Before Deploying Consumer

1. Verify producer is up to date
2. Run consumer tests
3. Verify no dependency conflicts
4. Deploy producer first if needed

## Troubleshooting

### Common Issues

| Issue | Cause | Fix |
|---|---|---|
| Type mismatch after update | Producer changed type | Update consumer to match |
| Missing export | Producer removed export | Restore export or update consumer |
| Version conflict | Two repos need different versions | Use workspace aliases |
| Circular dependency | Repo A depends on B, B depends on A | Extract shared code to new repo |

## Do Not

- Change shared types without updating consumers
- Deploy consumer before producer
- Remove exports without deprecation period
- Create circular dependencies
- Ignore dependency freshness warnings
- Deploy breaking changes without notice
