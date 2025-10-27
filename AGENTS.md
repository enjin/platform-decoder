## 📝 Git Workflow

### Branch Naming
Pattern: `{type}/PLA-{number}/{description}`

Types: `feature`, `bugfix`, `hotfix`, `enhancement`, `improvement`, `refactor`, `security`, `docs`, `chore`, `revert`, `other`

Examples:
- `feature/PLA-1234/add-user-authentication`
- `bugfix/PLA-5678/fix-null-pointer`
- `hotfix/PLA-9012/critical-security-patch`

### Commit Format
**IMPORTANT** Use conventional commits: `type(scope): description`

Examples:
- `fix(auth): resolve login timeout issue`
- `feat(graphql): add new asset query endpoint`
- `refactor(balances): improve error handling`

### PR Guidelines
- Title: `[PLA-XXXX] Clear description`
- Keep descriptions concise and focused on changes
