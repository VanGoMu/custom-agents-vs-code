# VS Code Custom Agents

[![Release](https://img.shields.io/badge/release-v1.0.0-blue)](https://github.com/epicuro/vs-code-custom-agents/releases)
[![Handoff Smoke CI](https://github.com/epicuro/vs-code-custom-agents/actions/workflows/handoff-install-smoke.yml/badge.svg)](https://github.com/epicuro/vs-code-custom-agents/actions/workflows/handoff-install-smoke.yml)
[![License](https://img.shields.io/github/license/epicuro/vs-code-custom-agents)](LICENSE)

Coleccion de agentes y handoffs listos para usar con GitHub Copilot Chat en VS Code.

Esta primera release esta enfocada en productividad de equipos que trabajan con TDD y automatizacion por stacks:

- Shell
- Python
- Node.js
- Next.js
- LangChain
- CrewAI

## Que incluye esta release

- Biblioteca de agentes especializados por rol en `agents/`.
- Handoffs orquestados en `handoffs/` para ejecutar flujos multiagente.
- Scripts de instalacion, validacion y ejecucion asistida en `scripts/`.

## Estructura del repositorio

```text
.
├── agents/                 # Agentes atomicos reutilizables
├── handoffs/               # Orquestadores + config de flujo
├── scripts/                # Utilidades CLI para instalar y validar
├── LICENSE
└── README.md
```

## Requisitos

- VS Code con GitHub Copilot Chat habilitado.
- bash (Linux/macOS o WSL en Windows).
- Herramientas opcionales segun flujo (por ejemplo Python, Docker, pytest).

## Inicio rapido

1. Clona este repositorio.
2. Instala un agente individual o un handoff completo.
3. Valida la instalacion.
4. Ejecuta tu flujo.

### Instalar un agente

```bash
./scripts/install.sh --agent shell-developer --repo
```

### Instalar un handoff

```bash
./scripts/install.sh --handoff python --repo
```

### Validar un handoff instalado

```bash
./scripts/validate-handoff.sh --handoff python --repo
```

### Preparar ejecucion guiada de handoff

```bash
./scripts/run-handoff.sh --handoff python --repo --prompt "Crear una API CRUD de tareas"
```

## Instalacion por alcance

- `--repo`: instala en `.github/agents/` del workspace actual.
- `--profile`: instala en `~/.github/agents/` para reutilizar en todos tus workspaces.

## Catalogos

- Agentes disponibles: `agents/README.md`
- Handoffs disponibles: `handoffs/README.md`

## Convenciones de diseno

- Cada agente vive en un archivo `.agent.md`.
- Cada handoff define orden de subagentes en `config.yaml`.
- El orquestador de handoff es `user-invocable: true`.
- Los subagentes de handoff son `user-invocable: false`.

## Flujo recomendado para adopcion

1. Empieza con un agente atomico para validar estilo de salida.
2. Migra a un handoff cuando necesites cadena completa (organizacion, RED, GREEN, VERIFY, DevOps).
3. Crea tus variantes a partir de este repo manteniendo nombres y contratos estables.

## Desarrollo y contribucion

1. Crea o modifica agentes en `agents/`.
2. Si aplica, define su handoff en `handoffs/<nombre>/`.
3. Actualiza los README correspondientes.
4. Prueba instalacion y validacion con scripts antes de abrir PR.

## Compatibilidad de esta release

Version inicial orientada a VS Code + Copilot Chat y al esquema de herramientas usado por este repositorio.

Si tu entorno reporta validaciones de modelo/herramientas, revisa la configuracion de custom agents y adapta frontmatter a tu runtime.

## Licencia

Este proyecto se distribuye bajo la licencia indicada en `LICENSE`.
