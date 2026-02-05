# Reusable CI/CD Actions – Contract v1.0

Este documento define o contrato estável das actions reutilizáveis.
Qualquer mudança incompatível requer bump de versão MAJOR.

---

## 1️⃣ Reusable CI (`ci.yml`)

### Inputs

| Nome | Tipo | Default | Descrição |
|----|----|----|----|
| project_path | string | `.` | Caminho do projeto |
| stack | string | auto | node \| php \| dotnet \| python \| go |
| skip_tests | boolean | false | Ignora execução de testes |

### Comportamento garantido

- Detecta stack automaticamente se não informado
- Executa testes **somente se houver estrutura de testes**
- Gera cobertura **quando suportado**
- Nunca falha por ausência de testes
- Sempre tenta gerar `coverage-summary.normalized.json`

### Artifact gerado

```bash
coverage-report
└─ coverage/coverage-summary.normalized.json
```

Formato do arquivo:
```json
{
  "line": 82.3,
  "branch": 80.1,
  "function": 85.0   
}
```

---

## 2️⃣ Auto PR (`auto-pr.yml`)

### Inputs

| Nome          | Tipo    | Default | Descrição                   |
| ------------- | ------- | ------- | --------------------------- |
| skip-tests    | boolean | false   | Ignora leitura de cobertura |
| min-coverage  | number  | 80      | Percentual mínimo           |
| coverage-mode | string  | info    | info | block                |

### Comportamento garantido

| Nome          | Tipo    | Default | Descrição                   |
| ------------- | ------- | ------- | --------------------------- |
| skip-tests    | boolean | false   | Ignora leitura de cobertura |
| min-coverage  | number  | 80      | Percentual mínimo           |
| coverage-mode | string  | info    | info | block                |

### Outputs internos

- coverage.line
- coverage.status (passed / failed)

--- 

## 3️⃣ Garantias de compatibilidade

- v1.x.x mantém este contrato
- Quebras exigem v2.0.0

---