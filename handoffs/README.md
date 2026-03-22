# Handoffs

Un handoff es un flujo orquestado: un agente principal coordina una secuencia ordenada de subagentes para resolver tareas complejas de punta a punta.

Cada handoff vive en su carpeta y contiene:

- `config.yaml`: metadatos, orden de agentes y dependencias.
- `<nombre>.agent.md`: orquestador invocable por el usuario.

## Handoffs disponibles

| Handoff | Descripcion | Subagentes |
| --- | --- | --- |
| `project-inicializer` | Inicializa un proyecto validando prompt y encadenando planificacion, sprints, testing y CI. | PromptValidator, ProjectPlanner, SprintPlanner, TestStrategy, CISetup |
| `shell` | Flujo shell completo con organizacion de proyecto, desarrollo y tests en Docker. | ShellProjectOrganizer, ShellDeveloper, ShellTestEngineer |
| `python` | Flujo TDD Python completo (estructura, RED, GREEN, VERIFY). | PythonProjectOrganizer, PythonTestEngineer, PythonDeveloper, PythonTestEngineer |
| `node` | Flujo TDD Node.js/TypeScript con Jest o Vitest y cobertura en Docker. | NodeProjectOrganizer, NodeTestEngineer, NodeDeveloper, NodeTestEngineer |
| `nextjs` | Flujo TDD Next.js App Router con Jest + RTL y verificacion final en Docker. | NextProjectOrganizer, NextTestEngineer, NextDeveloper, NextTestEngineer |
| `langchain` | Flujo TDD LangChain: arquitectura, tests RED, implementacion GREEN y cobertura. | LangChainProjectOrganizer, LangChainTestEngineer, LangChainDeveloper, LangChainTestEngineer, LangChainDevOps |
| `crewai` | Flujo TDD CrewAI: validacion inicial, arquitectura multiagente, RED/GREEN/VERIFY y DevOps. | PromptValidator, CrewAIProjectOrganizer, CrewAITestEngineer, CrewAIDeveloper, CrewAITestEngineer, CrewAIDevOps |

## Instalacion

```bash
# Instalar handoff en el repo actual
./scripts/install.sh --handoff <nombre> --repo

# Instalar handoff en el perfil de usuario
./scripts/install.sh --handoff <nombre> --profile

# Instalar desde carpeta local
./scripts/install.sh --handoff <nombre> --repo --source /ruta/fuente

# Instalar desde archivo .zip/.tar.*
./scripts/install.sh --handoff <nombre> --repo --archive /ruta/paquete.zip
```

## Validacion y ejecucion

```bash
# Validar que el handoff este bien instalado
./scripts/validate-handoff.sh --handoff <nombre> --repo

# Preparar ejecucion guiada del orquestador
./scripts/run-handoff.sh --handoff <nombre> --repo --prompt "<tu prompt>"
```

## Estructura esperada de config.yaml

```yaml
name: mi-handoff
description: Descripcion breve del flujo.
agents:
  1: primer-subagente
  2: segundo-subagente
dependencias:
  - python3
  - docker
```

Reglas:

1. Los nombres en `agents` deben coincidir con archivos en `../agents/`.
2. El orden numerico define la secuencia del flujo.
3. Declara en `dependencias` solo requisitos reales del handoff.

## Crear un nuevo handoff

1. Crea carpeta `handoffs/<nombre>/`.
2. Crea `config.yaml`.
3. Crea `<nombre>.agent.md` con `user-invocable: true`.
4. Referencia subagentes existentes y valida nombres.
5. Actualiza este README.
6. Prueba instalacion + validacion con scripts.

### Plantilla minima de orquestador

```markdown
---
name: MiHandoffOrchestrator
description: Orquesta un flujo multiagente para <caso>.
tools:
  - agent
agents:
  - PrimerAgente
  - SegundoAgente
model: gpt-4o
user-invocable: true
disable-model-invocation: false
---

Eres el orquestador de <caso>.

## Paso 1

Invoca `PrimerAgente` con el contexto inicial.

## Paso 2

Invoca `SegundoAgente` con el contexto acumulado.
```
