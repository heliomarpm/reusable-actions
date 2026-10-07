# 📊 Mapa de Dados, Contratos de Estado e Integrações (DATA.md)

Este documento descreve o fluxo de dados, modelos de estado em tempo de execução, contratos de arquivos normalizados e integrações com serviços externos utilizados pelo ecossistema `reusable-workflows`.

---

## 1. 🔄 Contratos de Dados Normalizados

Como este projeto atua na camada de infraestrutura e esteiras de automação (sem banco de dados relacional tradicional), a persistência e troca de estado entre etapas e jobs ocorre através de arquivos estruturados e variáveis de saída.

### 1.1. Contrato de Cobertura de Testes (SSOT)
- **Caminho:** `coverage/coverage-summary.normalized.json`
- **Produtores:** Plugins de stack (`scripts/plugins/node/coverage.sh`, `scripts/plugins/php/coverage.sh`).
- **Consumidores:** `actions/run-coverage`, `actions/create-pr`, `ci-quality-gate.yml`, `cd-pull-request.yml`.
- **Esquema JSON:**
```json
{
  "line": 85.5,
  "min": 80.0,
  "status": "passed",
  "mode": "block",
  "base_line": 82.0
}
```
- **Campos:**
  - `line` (*float*): Percentual consolidado de cobertura de linhas calculado pelos testes.
  - `min` (*float*): Meta mínima configurada via input `coverage-min`.
  - `status` (*string*): `"passed"` | `"failed"` | `"missing"`.
  - `mode` (*string*): `"block"` | `"info"` | `"decrease"`.
  - `base_line` (*float | null*): Percentual da branch base para validação em modo `decrease`.

---

### 1.2. Contrato de Delimitação de Commits (Git Log Stream)
Para evitar quebras no processamento de mensagens de commit com quebras de linha e emojis, as engines de changelog e release utilizam delimitadores ASCII não imprimíveis:
- **Unit Separator (`0x1f`):** Separa os campos de um mesmo commit (`%H`, `%h`, `%s`, `%b`).
- **Record Separator (`0x1e`):** Separa commits consecutivos.
- **Comando Canônico:**
```bash
git log "$RANGE" --no-merges --pretty=format:"%H%x1f%h%x1f%s%x1f%b%x1e" -- .
```

---

## 2. 🔐 Segredos, Tokens e Autenticação

| Segredo / Token | Origem | Escopo / Finalidade |
| :--- | :--- | :--- |
| `GITHUB_TOKEN` | Nativo do GitHub Actions | Permissões padrão para leitura de código, criação de labels e summaries. |
| `GH_TOKEN` | Secret do Repositório | Criação de PRs, push de Git Tags protegidas e GitHub Releases oficiais. |
| `NPM_TOKEN` | Secret do Repositório | Autenticação no registry público do NPM (`registry.npmjs.org`). |
| `PYPI_TOKEN` | Secret do Repositório | Token de API para upload de pacotes Python no PyPI (planejado). |
| `NUGET_TOKEN` | Secret do Repositório | Chave de API para upload de pacotes .NET no NuGet (planejado). |

---

## 3. 🌐 Integrações com Serviços e APIs Externas

```
┌────────────────────────────────────────────────────────────────────────┐
│                        reusable-workflows Engine                         │
└───────┬─────────────────────────┬────────────────────────────┬─────────┘
        │                         │                            │
        ▼                         ▼                            ▼
┌──────────────────┐    ┌──────────────────┐         ┌──────────────────┐
│    GitHub CLI    │    │ NPM / Registries │         │ Packagist / PHP  │
│      (`gh`)      │    │  (npmjs, GitHub) │         │    (Composer)    │
├──────────────────┤    ├──────────────────┤         ├──────────────────┤
│ • gh pr create   │    │ • npm publish    │         │ • git tag push   │
│ • gh pr edit     │    │ • .npmrc auth    │         │ • webhook update │
│ • gh release     │    │ • Auto-scoping   │         │                  │
└──────────────────┘    └──────────────────┘         └──────────────────┘
```

1. **GitHub CLI (`gh`):**
   - Criação e atualização de Pull Requests com verificação de PR existente (`gh pr list`).
   - Aplicação de labels automáticas (`auto-generated`, `coverage-passed`, `coverage-failed`).
   - Criação de releases no GitHub anexando notas geradas.
2. **NPM Registry & GitHub Packages:**
   - Injeção controlada de escopo de pacote (`@owner/nome`) durante upload para o GitHub Packages.
   - Restauração automática de arquivos originais (`package.json`, `.npmrc`) após o término do deploy.
3. **Packagist:**
   - Integração com publicação PHP acionada via envio de tags Git assinadas/anotadas.
