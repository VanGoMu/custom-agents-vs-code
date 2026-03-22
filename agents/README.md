# Agentes

Sub-agentes atómicos reutilizables. Cada archivo `.agent.md` define un rol único con herramientas y modelo acotados. Los agentes de esta carpeta son bloques de construcción: se usan directamente o se encadenan desde un handoff.

## Agentes disponibles

| Agente                 | Archivo                             | Invocable | Descripcion                                                                                                                   |
| ---------------------- | ----------------------------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------- |
| ShellDeveloper         | `shell-developer.agent.md`          | Si        | Escribe y revisa scripts Bash con shellcheck, separacion de funciones y SOLID.                                                |
| ShellProjectOrganizer  | `shell-project-organizer.agent.md`  | Si        | Organiza proyectos shell en un framework con OCP (plugins/hooks) y separacion de dependencias.                                |
| ShellTestEngineer      | `shell-test-engineer.agent.md`      | Si        | Genera y ejecuta suites de tests para scripts shell via Docker con bats-core y stubs de dependencias.                         |
| PythonProjectOrganizer | `python-project-organizer.agent.md` | Si        | Decide OOP o Funcional con justificacion, scaffoldea src-layout con SOLID y valida con ruff + mypy.                           |
| PythonDeveloper        | `python-developer.agent.md`         | Si        | Fase GREEN del ciclo TDD: implementa el minimo codigo para pasar los tests en rojo. Type hints + SOLID.                       |
| PythonTestEngineer     | `python-test-engineer.agent.md`     | Si        | Fase RED y VERIFY del ciclo TDD: escribe tests con pytest contra contratos de API y verifica cobertura en Docker.             |
| NodeProjectOrganizer   | `node-project-organizer.agent.md`   | Si        | Decide OOP/Funcional y Jest/Vitest con justificacion, scaffoldea TypeScript src-layout con SOLID y valida con tsc + eslint.   |
| NodeDeveloper          | `node-developer.agent.md`           | Si        | Fase GREEN del ciclo TDD: implementa el minimo TypeScript para pasar los tests en rojo. Strict types + SOLID.                 |
| NodeTestEngineer       | `node-test-engineer.agent.md`       | Si        | Fase RED y VERIFY del ciclo TDD: escribe tests con Jest o Vitest contra contratos TypeScript y verifica cobertura en Docker.  |
| NextProjectOrganizer   | `next-project-organizer.agent.md`   | Si        | App Router: decide OOP/Funcional para negocio y estrategia Server/Client. Framework fijo: Jest + next/jest + RTL.             |
| NextDeveloper          | `next-developer.agent.md`           | Si        | Fase GREEN: implementa Server Components, Client Components, Server Actions y servicios con TypeScript strict + SOLID.        |
| NextTestEngineer       | `next-test-engineer.agent.md`       | Si        | Fase RED y VERIFY: patrones de test por tipo de artefacto Next.js (servicio, action, server/client component, route handler). |
| ShellDevOps            | `shell-devops.agent.md`             | Si        | CI local (pre-commit: shellcheck nativo + bats Docker) y GitHub Actions con matriz Ubuntu/Alpine.                             |
| PythonDevOps           | `python-devops.agent.md`            | Si        | CI local (pre-commit: ruff nativo + mypy+pytest Docker) y GitHub Actions con cobertura >= 80%.                                |
| NodeDevOps             | `node-devops.agent.md`              | Si        | CI local (pre-commit: tsc+eslint nativos + tests Docker) y GitHub Actions. Detecta Jest o Vitest. Cobertura >= 80%.           |
| NextDevOps             | `next-devops.agent.md`              | Si        | CI local (pre-commit: tsc+next lint nativos + jest Docker) y GitHub Actions con next build dockerizado. Cobertura >= 80%.     |
| PromptValidator        | `prompt-validator.agent.md`         | No        | Valida si un prompt tiene suficiente informacion para arrancar un flujo.                                                      |
| ProjectPlanner         | `project-planner.agent.md`          | No        | Genera un plan de proyecto completo con stack, alcance MVP y arquitectura.                                                    |
| SprintPlanner          | `sprint-planner.agent.md`           | No        | Descompone un plan de proyecto en sprints iterativos con backlog.                                                             |
| TestStrategy           | `test-strategy.agent.md`            | No        | Define la estrategia de testing, herramientas y cobertura minima.                                                             |
| CISetup                | `ci-setup.agent.md`                 | No        | Genera workflows de GitHub Actions y politica de CI/CD completa.                                                              |

> Los agentes con `Invocable: No` solo pueden ser llamados por un orquestador (handoff). No aparecen en el desplegable de Copilot Chat.

## Instalacion

Usa el script `scripts/install.sh` para copiar agentes al workspace o al perfil de usuario:

```bash
# Instalar un agente suelto en el repo actual
./scripts/install.sh --agent <nombre> --repo

# Instalar un agente suelto en el perfil de usuario
./scripts/install.sh --agent <nombre> --profile

# Instalar desde una carpeta local (sin clonar este repo)
./scripts/install.sh --agent <nombre> --repo --source /ruta/fuente

# Instalar desde un paquete local (.zip/.tar.*)
./scripts/install.sh --agent <nombre> --repo --archive /ruta/paquete.tar.gz
```

Para instalar flujos completos (orquestador + sub-agentes), consulta [`../handoffs/README.md`](../handoffs/README.md).

## Como anadir un nuevo agente

1. Crea `<nombre>.agent.md` en esta carpeta con el frontmatter correcto.
2. Pon `user-invocable: false` si el usuario puede invocarlo directamente, `false` si es sub-agente.
3. Actualiza la tabla de este README.
4. Si el agente forma parte de un handoff, añadelo al `config.yaml` del handoff correspondiente.

### Plantilla

```markdown
---
name: NombreAgente
description: Descripcion de una linea de que hace el agente.
tools:
  - search/codebase
model: gpt-4o
user-invocable: false
disable-model-invocation: false
---

Descripcion del rol y comportamiento del agente...
```

### Herramientas disponibles

| Herramienta       | Descripcion                                |
| ----------------- | ------------------------------------------ |
| `agent`           | Invocar otros agentes (solo orquestadores) |
| `search/codebase` | Buscar en el codigo del workspace          |
| `search/usages`   | Buscar usos de un simbolo                  |
| `web/fetch`       | Obtener contenido de URLs                  |
| `run/terminal`    | Ejecutar comandos en terminal              |
| `create/file`     | Crear ficheros en el workspace             |
| `edit/file`       | Editar ficheros existentes                 |
