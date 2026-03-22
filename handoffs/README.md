# Handoffs

Un handoff es un flujo orquestado: un agente principal coordina una secuencia de sub-agentes para completar una tarea compleja. Cada handoff tiene su propia carpeta con dos archivos:

- `config.yaml` — metadatos del handoff: nombre, descripcion, modelo y lista ordenada de sub-agentes.
- `<nombre>.agent.md` — el orquestador, que define el flujo de ejecucion y como encadena los sub-agentes.

## Handoffs disponibles

| Handoff               | Descripcion                                                                                                | Sub-agentes                                                                          |
| --------------------- | ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `project-inicializer` | Inicializa un proyecto de software validando el prompt y encadenando planificacion, sprints, testing y CI. | PromptValidator, ProjectPlanner, SprintPlanner, TestStrategy, CISetup                                          |
| `shell`               | Crea o refactoriza proyectos shell con framework OCP+DI, scripts SOLID con shellcheck y tests en Docker.   | ShellProjectOrganizer, ShellDeveloper, ShellTestEngineer                                                       |
| `python`              | Flujo TDD Python completo: decide OOP/Funcional, escribe tests (RED), implementa con SOLID (GREEN) y verifica cobertura con pytest-cov en Docker. | PythonProjectOrganizer, PythonTestEngineer (RED), PythonDeveloper (GREEN), PythonTestEngineer (VERIFY) |
| `node`                | Flujo TDD Node.js/TypeScript completo: decide OOP/Funcional y Jest/Vitest, escribe tests (RED), implementa con TypeScript strict + SOLID (GREEN) y verifica cobertura en Docker. | NodeProjectOrganizer, NodeTestEngineer (RED), NodeDeveloper (GREEN), NodeTestEngineer (VERIFY) |
| `nextjs`              | Flujo TDD Next.js App Router completo: decide paradigma + estrategia Server/Client, escribe tests con Jest + RTL por tipo de artefacto (RED), implementa con TypeScript strict (GREEN) y verifica en Docker. Menciona Playwright para E2E. | NextProjectOrganizer, NextTestEngineer (RED), NextDeveloper (GREEN), NextTestEngineer (VERIFY) |

## Instalacion

El script `scripts/install.sh` lee el `config.yaml` del handoff e instala el orquestador y todos sus sub-agentes en el destino elegido:

```bash
# Instalar un handoff en el repo actual (.github/agents/)
./scripts/install.sh --handoff <nombre> --repo

# Instalar un handoff en el perfil de usuario (~/.github/agents/)
./scripts/install.sh --handoff <nombre> --profile

# Instalar desde una carpeta local (sin clonar este repo)
./scripts/install.sh --handoff <nombre> --repo --source /ruta/fuente

# Instalar desde un paquete local (.zip/.tar.*)
./scripts/install.sh --handoff <nombre> --repo --archive /ruta/paquete.zip
```

Estructura resultante en el destino:

```
.github/agents/
├── <orquestador>.agent.md          <- invocable por el usuario
└── <nombre-handoff>/
    ├── <sub-agente-1>.agent.md
    ├── <sub-agente-2>.agent.md
    └── ...
```

## Estructura de config.yaml

```yaml
name: nombre-del-handoff
description: Descripcion de una linea del flujo completo.
llm: claude-sonnet-2024-06   # modelo del orquestador
agents:
  1: nombre-sub-agente-1     # orden de ejecucion
  2: nombre-sub-agente-2
  3: nombre-sub-agente-3
```

Los nombres en `agents` deben coincidir con los archivos `<nombre>.agent.md` de la carpeta `../agents/`.

## Como anadir un nuevo handoff

1. Crea la carpeta `handoffs/<nombre>/`.
2. Crea `config.yaml` con los campos `name`, `description`, `llm` y `agents`.
3. Crea `<nombre>.agent.md` con el orquestador (pon `user-invocable: true` y `tools: [agent]`).
4. Asegurate de que todos los sub-agentes referenciados existen en `../agents/`.
5. Actualiza la tabla de este README.

### Plantilla de config.yaml

```yaml
name: mi-handoff
description: Descripcion breve del flujo.
llm: claude-sonnet-2024-06
agents:
  1: primer-agente
  2: segundo-agente
```

### Plantilla de orquestador

```markdown
---
name: MiHandoff
description: Descripcion de una linea del flujo orquestado.
tools:
  - agent
agents:
  - PrimerAgente
  - SegundoAgente
model: gpt-4o
user-invocable: true
disable-model-invocation: false
---

Eres el orquestador de [flujo]. Tu mision es...

## Paso 1 — ...

Invoca al agente `PrimerAgente` con...

## Paso 2 — ...

Invoca al agente `SegundoAgente` con...
```
