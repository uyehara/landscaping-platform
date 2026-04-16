# Contributing Guide

## Code Style

### General Principles

- **Readability**: Code should be self-documenting with clear variable/function names
- **Consistency**: Follow established patterns in each package
- **Simplicity**: Prefer simple solutions over clever ones
- **Testability**: Write code that can be easily tested


### JavaScript/TypeScript (Frontend, API Gateway, Collaboration)


```typescript
// Use explicit types for function signatures
interface Project {
  id: string;
  name: string;
  status: ProjectStatus;
}


// Use async/await consistently
async function getProject(id: string): Promise<Project> {
  return db.query('SELECT * FROM projects WHERE id = $1', [id]);
}

// Handle errors with specific types
interface ApiError {
  statusCode: number;
  message: string;
  details?: unknown;
}
```


**Formatting:**
- 2-space indentation
- Single quotes for strings
- Trailing commas
- Semicolons required
- Max line length: 100 characters

**Linting:**
```bash
# ESLint configuration
npm run lint
npm run lint:fix  # Auto-fix
```

### Python (AI Service)

```python
# Use type hints
from typing import Optional, List

def generate_embedding(text: str, model: str = "text-embedding-3-large") -> List[float]:
    """Generate embedding for text using specified model."""
    response = openai.embeddings.create(model=model, input=text)
    return response.data[0].embedding

# Use dataclasses for data structures
from dataclasses import dataclass

@dataclass
class ProcessingJob:
    id: str
    workflow_name: str
    status: ProcessingStatus
    input_params: dict
```

**Formatting:**
- Black formatter (line length: 88)
- isort for imports
- Type hints required for public APIs

**Linting:**
```bash
# Ruff configuration
ruff check .
ruff format .
```

### SQL

```sql
-- UPPERCASE keywords
-- lowercase identifiers (or quoted if needed)
SELECT p.id, p.name, c.name as customer_name
FROM projects p
JOIN customers c ON c.id = p.customer_id
WHERE p.status = 'active'
  AND c.customer_type = 'commercial'
ORDER BY p.created_at DESC;
```


## Git Workflow

### Branch Naming

```
feature/add-plant-similarity-search
feature/user-role-management
bugfix/fix-project-create-error
hotfix/security-patch-auth
docs/update-api-reference
refactor/extract-common-utils
```

### Commit Messages

Follow Conventional Commits:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no code change)
- `refactor`: Code restructure
- `test`: Adding tests
- `chore`: Maintenance

**Examples:**
```bash
git commit -m "feat(projects): add project filtering by status"
git commit -m "fix(api): handle missing property coordinates"
git commit -m "docs(database): document line_items polymorphic relationship"
git commit -m "refactor(ai-service): extract embedding generation to service"
```

### Workflow


```bash
# 1. Create feature branch from main
git checkout main
git pull
git checkout -b feature/add-export-functionality

# 2. Make changes with atomic commits
git add .
git commit -m "feat(estimates): add CSV export for line items"

# 3. Keep branch updated
git checkout main
git pull
git checkout feature/add-export-functionality
git rebase main

# 4. Push and create PR
git push -u origin feature/add-export-functionality
```



## Pull Request Process

### Before Creating PR

1. **Run tests**:
```bash
# All packages
npm run test
pytest

# Integration tests
./scripts/integration-tests.sh
```


2. **Run linters**:
```bash
npm run lint
ruff check .
```


3. **Update documentation** if needed

4. **Self-review** your changes


### PR Description Template

```markdown
## Summary
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe how changes were tested

## Checklist
- [ ] Tests pass
- [ ] Linting passes
- [ ] Documentation updated
- [ ] No console.log/debugger left
```


### Review Process

1. At least one approval required
2. All CI checks must pass
3. No unresolved conversations
4. Branch can be squash-merged


## Testing Requirements

### Unit Tests

**Frontend:**
```bash
# Test files alongside source
packages/frontend/src/lib/__tests__/project.test.ts
packages/frontend/src/lib/utils/__tests__/format.test.ts
```

**API Gateway:**
```bash
packages/api-gateway/src/__tests__/projects.test.ts
```

**AI Service:**
```bash
packages/ai-service/tests/
├── test_embeddings.py
├── test_image_processing.py
└── test_ai_analysis.py
```


### Coverage Requirements

| Package | Minimum Coverage |
|---------|------------------|
| frontend | 70% |
| api-gateway | 80% |
| ai-service | 75% |


### Integration Tests

```bash
# Full stack test
./scripts/integration-tests.sh

# Test specific flow
curl -X POST http://localhost:3001/projects \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name": "Test Project"}'
```


## Package-Specific Guidelines


### Frontend (SvelteKit)

**Component Structure:**
```
src/lib/components/
├── Button.svelte
├── ProjectCard.svelte
└── Modal.svelte

Button.svelte
-------------
<script lang="ts">
  export let variant: 'primary' | 'secondary' = 'primary';
  export let disabled = false;
</script>

<button class="btn btn-{variant}" {disabled}>
  <slot />
</button>

<style>
  .btn { ... }
</style>
```

**Stores:** Use Svelte stores for shared state
```typescript
// src/lib/stores/project.ts
import { writable } from 'svelte/store';

export interface ProjectState {
  projects: Project[];
  loading: boolean;
  error: string | null;
}

export const projectStore = writable<ProjectState>({
  projects: [],
  loading: false,
  error: null,
});
```

### API Gateway (Fastify)

**Route Structure:**
```typescript
// src/routes/projects.ts
import type { FastifyPluginAsync } from 'fastify';

const projectsRoute: FastifyPluginAsync = async (fastify) => {
  // GET /projects
  fastify.get('/', {
    schema: {
      querystring: ProjectQuerySchema,
      response: { 200: ProjectListSchema }
    }
  }, async (request, reply) => {
    return getProjects(request.query);
  });

  // POST /projects
  fastify.post('/', {
    schema: {
      body: CreateProjectSchema,
      response: { 201: ProjectSchema }
    }
  }, async (request, reply) => {
    const project = await createProject(request.body);
    reply.code(201);
    return project;
  });
};

export default projectsRoute;
```


### AI Service (FastAPI)

**Route Structure:**
```python
# src/routes/embeddings.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List


router = APIRouter(prefix="/embeddings", tags=["embeddings"])

class EmbeddingRequest(BaseModel):
    text: str
    model: str = "text-embedding-3-large"

class EmbeddingResponse(BaseModel):
    embedding: List[float]
    model: str
    tokens: int

@router.post("/text", response_model=EmbeddingResponse)
async def generate_text_embedding(request: EmbeddingRequest):
    """Generate embedding for text input."""
    try:
        response = openai.embeddings.create(
            model=request.model,
            input=request.text
        )
        return EmbeddingResponse(
            embedding=response.data[0].embedding,
            model=request.model,
            tokens=response.usage.total_tokens
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```


## Documentation Updates

When contributing, update relevant docs:

- **New feature**: Add to appropriate doc in `/docs`
- **API change**: Update `/docs/reference/api.md`
- **Schema change**: Update `/docs/reference/database.md`
- **New dependency**: Document in this guide


## Questions?

- Open an issue for bugs/feature requests
- Check existing issues before creating new ones
- Be respectful and follow our code of conduct
