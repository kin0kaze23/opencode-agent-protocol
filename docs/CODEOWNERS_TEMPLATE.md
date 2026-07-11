# CODEOWNERS Template

> **Copy this file to `.github/CODEOWNERS` in your repo and customize.**
> **Version:** v4.38

## How to Use

1. Copy this file to `.github/CODEOWNERS`
2. Replace `@your-team` with actual GitHub usernames or team names
3. Remove sections that don't apply to your repo
4. Add repo-specific sensitive paths

## Syntax

```
# Each line: <path-pattern> <owner1> <owner2>...
# Owners can be @username or @org/team-name
# Last matching pattern wins (like .gitignore)
# * matches any path
```

## Recommended Ownership Blocks

### Default owner (catch-all)
```
* @your-team
```

### Release gate and CI/CD
```
/.github/workflows/           @your-team
/.github/scripts/             @your-team
/.opencode/config/            @your-team
```

### Security and authentication
```
/auth/                        @your-team
/security/                    @your-team
/secrets/                     @your-team
```

### Payments and billing
```
/payment/                     @your-team
/payments/                    @your-team
/billing/                     @your-team
```

### Database and schema
```
/schema/                      @your-team
/migrations/                  @your-team
/supabase/                    @your-team
/prisma/                      @your-team
/drizzle/                     @your-team
```

### Deployment and infrastructure
```
/Dockerfile                   @your-team
/docker-compose*              @your-team
/vercel.json                  @your-team
/wrangler.toml                @your-team
/Makefile                     @your-team
/Procfile                     @your-team
```

### Protocol and configuration
```
/AGENTS.md                    @your-team
/NOW.md                       @your-team
/RELEASES.md                  @your-team
/.env.example                 @your-team
```

## Notes

- CODEOWNERS is advisory — it adds required reviewers but does not block merges
- Branch protection must be configured separately to enforce CODEOWNERS reviews
- The `reviewer-approved` label is governed by the trust policy, not CODEOWNERS
- For private repos, ensure owners have read access to the repo
