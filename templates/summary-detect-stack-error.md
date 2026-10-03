# 🔍 Falha na Detecção de Stack

Não foi possível identificar a linguagem/tecnologia do projeto no diretório:
> `{{CURRENT_DIR}}`

{{HINT_BLOCK}}

### 💡 Como resolver:
1. **Projeto em subpasta:** Se o código não estiver na raiz, adicione `with: project_path: <pasta>` no workflow.
2. **Definição explícita:** Você também pode forçar a stack sem autodetecção via `with: stack: <linguagem>`.

### 📋 Arquivos reconhecidos por stack:
| Stack | Arquivos Reconhecidos |
| :--- | :--- |
| **Node.js** | `package.json`, `yarn.lock`, `pnpm-lock.yaml` |
| **PHP** | `composer.json`, `index.php` |
| **.NET** | `*.csproj`, `*.sln` |
| **Python** | `requirements.txt`, `pyproject.toml`, `Pipfile`, `uv.lock`, `setup.py` |
| **Go** | `go.mod` |
