## payment 

```
curl -X POST -is "http://localhost:8000/api/v2/payments" \
-H "Content-Type: application/json" \
-d '{"name": "Kuay", "price": 60000}'
```

## Getting Started

### Frontend

1. Clone repository

```bash
git clone https://github.com/brain-flowing-company/psuechaokhai-backend.git
```

2. Start backend server

```bash
docker-compose up -d --build --no-deps # note: frontend only
```

3. pgAdmin is available at [localhost:5050](http://localhost:5050)

| Field              | Value           |
| ------------------ | --------------- |
| _pgAdmin_ Username | admin@admin.com |
| _pgAdmin_ Password | admin           |
| Host name/address  | db              |
| Port               | 5432            |
| Username           | postgres        |
| Password           | 123456          |

### Backend

**Prerequisite**

- Golang
- Makefile (optional)
- docker
- git
- swagger

1. Clone repository

```bash
git clone https://github.com/brain-flowing-company/psuechaokhai-backend.git
```

2. Copy `.env.example` to `.env`

3. Get Swagger cli

```bash
go install github.com/swaggo/swag/cmd/swag@latest
```

4. Run development server

```bash
docker-compose -f docker-compose.dev.yaml up -d --build --no-deps # note: backend only
# or
make up
```

5. pgAdmin is available at [localhost:5050](http://localhost:5050)

| Field              | Value           |
| ------------------ | --------------- |
| _pgAdmin_ Username | admin@admin.com |
| _pgAdmin_ Password | admin           |
| Host name/address  | db              |
| Port               | 5432            |
| Username           | postgres        |
| Password           | 123456          |

> Note: make sure you have `Makefile` before using `make` command

- This will automatically start postgres database and development server with auto-reload.
- **Swagger (API docs)** is at [localhost:8000/docs](http://localhost:8000/docs) \*_change port if your app is running on different port_
- If you've made any changes to API docs (comments above handler function), make sure you run this command to update API docs page.

```bash
swag init -g ./cmd/main.go -o ./docs/
# or
make docs
```

## Project structures

- `cmd/` contains `main.go`
- `config/` contains env var loader
- `database/` contains database (postgres) connector
- `internal/`
  - name folder by service name (snake_case)
  - `.handler.go` handles http request
  - `.service.go` holds core logic
  - `.repository.go` holds data fetcher (database queries or external api calls)

## Contribution

1. Make sure to pull the latest commit from `dev` branch

```bash
git pull origin dev
```

2. Create new branch with your git GUI tools or use this command

```bash
git checkout -b <branch-name>
```

3. Make sure you on the correct branch
4. Craft your wonderful code and don't forget to commit frequently

```bash
git add <file-path> # add specific file
# or
git add . # add all files
```

```bash
git commit -m "<prefix>: <commit message>"
```

> Note: _check out [commit message convention](#commit-message-convention)_

5. Push code to remote repository
6. Create pull request on [github](https://github.com/brain-flowing-company/pprp-backend/pulls)

- compare changes with **base**: `dev` &#8592; **compare**: `<branch-name>`
- title also apply [commit message convention](#commit-message-convention)
- put fancy description

### Commit message convention

```bash
git commit -m "<prefix>: <commit message>"
```

- use lowercase
- **meaningful** commit message

**Prefix**

- **`feat`**: introduce new feature
- **`fix`**: fix bug
- **`refactor`**: changes which neither fix bug nor add a feature
- **`chore`**: changes to the build process or extra tools and libraries
