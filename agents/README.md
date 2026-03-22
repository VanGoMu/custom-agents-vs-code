# Agentes

Catalogo de agentes atomicos reutilizables. Cada archivo `.agent.md` define un rol especializado con instrucciones, herramientas y reglas de uso.

## Como usar este catalogo

1. Elige el agente por stack y fase de trabajo.
2. Instala el agente con `scripts/install.sh`.
3. Si necesitas un flujo completo multiagente, usa un handoff (ver `../handoffs/README.md`).

## Agentes disponibles

| Agente | Archivo | Invocable | Descripcion |
| --- | --- | --- | --- |
| ShellDeveloper | `shell-developer.agent.md` | Si | Escribe y revisa scripts Bash con shellcheck, separacion de funciones y SOLID. |
| ShellProjectOrganizer | `shell-project-organizer.agent.md` | Si | Organiza proyectos shell en un framework con OCP (plugins/hooks) y separacion de dependencias. |
| ShellTestEngineer | `shell-test-engineer.agent.md` | Si | Genera y ejecuta suites de tests para scripts shell via Docker con bats-core y stubs de dependencias. |
| ShellDevOps | `shell-devops.agent.md` | Si | CI local (pre-commit: shellcheck nativo + bats Docker) y GitHub Actions con matriz Ubuntu/Alpine. |
| PythonProjectOrganizer | `python-project-organizer.agent.md` | Si | Decide OOP o Funcional con justificacion, scaffoldea src-layout con SOLID y valida con ruff + mypy. |
| PythonDeveloper | `python-developer.agent.md` | Si | Fase GREEN del ciclo TDD: implementa el minimo codigo para pasar los tests en rojo. Type hints + SOLID. |
| PythonTestEngineer | `python-test-engineer.agent.md` | Si | Fase RED y VERIFY del ciclo TDD: escribe tests con pytest contra contratos de API y verifica cobertura en Docker. |
| PythonDevOps | `python-devops.agent.md` | Si | CI local (pre-commit: ruff nativo + mypy+pytest Docker) y GitHub Actions con cobertura >= 80%. |
| NodeProjectOrganizer | `node-project-organizer.agent.md` | Si | Decide OOP/Funcional y Jest/Vitest con justificacion, scaffoldea TypeScript src-layout con SOLID y valida con tsc + eslint. |
| NodeDeveloper | `node-developer.agent.md` | Si | Fase GREEN del ciclo TDD: implementa el minimo TypeScript para pasar los tests en rojo. Strict types + SOLID. |
| NodeTestEngineer | `node-test-engineer.agent.md` | Si | Fase RED y VERIFY del ciclo TDD: escribe tests con Jest o Vitest contra contratos TypeScript y verifica cobertura en Docker. |
| NodeDevOps | `node-devops.agent.md` | Si | CI local (pre-commit: tsc+eslint nativos + tests Docker) y GitHub Actions. Detecta Jest o Vitest. Cobertura >= 80%. |
| NextProjectOrganizer | `next-project-organizer.agent.md` | Si | App Router: decide OOP/Funcional para negocio y estrategia Server/Client. Framework fijo: Jest + next/jest + RTL. |
| NextDeveloper | `next-developer.agent.md` | Si | Fase GREEN: implementa Server Components, Client Components, Server Actions y servicios con TypeScript strict + SOLID. |
| NextTestEngineer | `next-test-engineer.agent.md` | Si | Fase RED y VERIFY: patrones de test por tipo de artefacto Next.js (servicio, action, server/client component, route handler). |
| NextDevOps | `next-devops.agent.md` | Si | CI local (pre-commit: tsc+next lint nativos + jest Docker) y GitHub Actions con next build dockerizado. Cobertura >= 80%. |
| LangChainProjectOrganizer | `langchain-project-organizer.agent.md` | Si | Define arquitectura LangChain (LCEL/Chains o Agent+Tools) y scaffoldea contratos tipados. |
| LangChainDeveloper | `langchain-developer.agent.md` | Si | Fase GREEN del ciclo TDD para LangChain: implementa el minimo codigo por contratos para pasar tests RED. |
| LangChainTestEngineer | `langchain-test-engineer.agent.md` | Si | Fase RED y VERIFY para LangChain: tests con doubles de LLM/tools y cobertura final en Docker. |
| LangChainDevOps | `langchain-devops.agent.md` | Si | CI local/remota para LangChain en Python: pre-commit, Docker CI y GitHub Actions con cobertura minima del 80%. |
| CrewAIProjectOrganizer | `crewai-project-organizer.agent.md` | Si | Define arquitectura CrewAI (secuencial o jerarquica) y scaffoldea contratos tipados para agents, tasks y crew. |
| CrewAIDeveloper | `crewai-developer.agent.md` | Si | Fase GREEN del ciclo TDD para CrewAI: implementa el minimo codigo por contratos para pasar tests RED. |
| CrewAITestEngineer | `crewai-test-engineer.agent.md` | Si | Fase RED y VERIFY para CrewAI: tests con doubles de LLM/tools y cobertura final en Docker. |
| CrewAIDevOps | `crewai-devops.agent.md` | Si | CI local/remota para CrewAI en Python: pre-commit, Docker CI y GitHub Actions con cobertura minima del 80%. |
| PromptValidator | `prompt-validator.agent.md` | No | Valida si un prompt de inicializacion contiene informacion suficiente para arrancar un flujo. |
| ProjectPlanner | `project-planner.agent.md` | No | Genera un plan de proyecto completo con stack, alcance MVP y arquitectura. |
| SprintPlanner | `sprint-planner.agent.md` | No | Descompone un plan de proyecto en sprints iterativos con backlog. |
| TestStrategy | `test-strategy.agent.md` | No | Define la estrategia de testing, herramientas y cobertura minima. |
| CISetup | `ci-setup.agent.md` | No | Genera workflows de GitHub Actions y politica de CI/CD completa. |

Nota: los agentes con `Invocable: No` se usan como subagentes dentro de orquestadores y no aparecen en el selector de Copilot Chat.

## Instalacion

```bash
# Instalar en el repo actual (.github/agents/)
./scripts/install.sh --agent <nombre> --repo

# Instalar en el perfil de usuario (~/.github/agents/)
./scripts/install.sh --agent <nombre> --profile

# Instalar desde fuente local
./scripts/install.sh --agent <nombre> --repo --source /ruta/fuente

# Instalar desde paquete .zip/.tar.*
./scripts/install.sh --agent <nombre> --repo --archive /ruta/paquete.tar.gz
```

## Crear un nuevo agente

1. Crea `<nombre>.agent.md` en esta carpeta.
2. Define `user-invocable: true` si el usuario lo invoca directamente.
3. Define `user-invocable: false` si es solo subagente.
4. Actualiza esta tabla.
5. Si participa en un handoff, agregalo al `config.yaml` correspondiente.

### Plantilla minima

```markdown
---
name: NombreAgente
description: Descripcion de una linea de que hace el agente.
tools:
  - search/codebase
model: gpt-4o
user-invocable: true
disable-model-invocation: false
---

Descripcion del rol y comportamiento del agente...
```

## Checklist previo a PR

1. Frontmatter valido.
2. Nombre de archivo consistente con el rol.
3. Instrucciones sin ambiguedad.
4. README actualizado.
5. Instalacion probada con `scripts/install.sh`.
