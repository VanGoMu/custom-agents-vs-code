# Custom agents en Visual Studio Code

Los **custom agents en Visual Studio Code** son “personas” o roles especializados que le puedes definir a la IA (por ejemplo GitHub Copilot) para que responda y actúe de forma específica según tu flujo de trabajo: code‑reviewer, planner, security‑analyst, etc. [code.visualstudio](https://code.visualstudio.com/docs/copilot/customization/custom-agents)

---

## Qué es un custom agent

Un custom agent es un fichero (normalmente `.agent.md`) que define:

- **Nombre y descripción** del agente (por ej. “Reviewer”, “Planner”).
- **Instrucciones** que guían cómo debe comportarse la IA (siempre en modo “plan”, sin tocar ficheros, centrado en seguridad, etc.).
- **Herramientas** a las que puede acceder (`search/codebase`, `search/usages`, `agent`, `web/fetch`, etc.).
- **Modelo** (o modelos alternativos) que debe usar.
- **Handoffs** (transiciones) hacia otros agents para encadenar flujos. [code.visualstudio](https://code.visualstudio.com/docs/copilot/concepts/agents)

En resumen: un custom agent es un “perfil de IA” con un rol, unas reglas y un conjunto de herramientas limitado o extendido.

---

### Dónde se guardan y cómo se crean

En VS Code usas el panel de **GitHub Copilot Chat** (o el agente de Copilot integrado):

1. Abre el chat de Copilot en VS Code.
2. En el desplegable de agents, selecciona **“Configure Custom Agents…”**.
3. Elige **“Create new custom agent”**.
4. Elige ubicación:
   - **Workspace** (por ejemplo `.github/agents/` del proyecto), solo para ese repo.
   - **User profile** (perfil de usuario), para usarlo en todos los workspaces. En este caso se almacena en la ruta `~/.github/agents/`. [docs.github](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents)

El editor crea un fichero `.agent.md` con un _frontmatter_ en YAML y un cuerpo en Markdown donde defines el comportamiento del agente. [code.visualstudio](https://code.visualstudio.com/docs/copilot/guides/customize-copilot-guide)

---

### Estructura típica de un .agent.md

Un ejemplo muy básico (por ejemplo, un “Reviewer”):

```markdown
---
name: Reviewer
description: Revisa código buscando bugs, errores de diseño y seguridad.
tools: ["search/codebase", "search/usages"]
model: "GPT-4o"
user-invocable: true
disable-model-invocation: false
---

Eres un revisor de código muy estricto.  
Sigue estas reglas:

- Solo analiza el código, no generes cambios automáticamente.
- Comenta en detalle:
  - Posibles bugs.
  - Vulnerabilidades de seguridad.
  - Violaciones de estilo o convenciones del proyecto.
- Siempre devuelves un Markdown con secciones:
  - "Problemas encontrados".
  - "Recomendaciones".
```

Campos relevantes:

- `name` / `description`: nombre visible en el dropdown de agents.
- `tools`: herramientas que puede usar (búsqueda de código, uso de web, otros agents). [code.visualstudio](https://code.visualstudio.com/docs/copilot/agents/agent-tools)
- `model`: modelo o lista de modelos (se intenta en orden).
- `user-invocable`: si aparece en el menú de agentes.
- `disable-model-invocation`: si puede ser llamado como _subagent_ por otro agent.

---

### Handoffs y subagents

Los **handoffs** permiten que un agente invoque a otro agente con un prompt específico, creando flujos encadenados:

```markdown
---
name: Feature Builder
tools: ["agent"]
agents: ["Researcher", "Implementer"]
---

Para cada tarea:

1. Usa el agent 'Researcher' para entender el contexto y el código existente.
2. Usa el agent 'Implementer' para aplicar los cambios.
```

Características de los subagents:

- Cada subagent tiene su propio contexto (no hereda todo el historial del agente principal).
- Se ejecutan de forma **sincrónica** (el agente padre espera el resultado).
- Pueden ejecutarse en paralelo si el agente lo orquesta así (por ejemplo, análisis de seguridad, rendimiento y accesibilidad a la vez).

---

### Cómo usar un custom agent en la práctica

1. **Seleccionar el agente**:
   - En el chat de Copilot, cambia el agente usando el dropdown y elige tu custom agent. [code.visualstudio](https://code.visualstudio.com/docs/copilot/agents/overview)
2. **Llamarlo por comando**:
   - También puedes llamar al agente desde el **Command Palette** (`Ctrl+Shift+P`):
     - `Chat: New Custom Agent` para crear uno.
     - Otros comandos según el sistema de agents de tu extensión. [code.visualstudio](https://code.visualstudio.com/docs/copilot/guides/customize-copilot-guide)
3. **Usar /create‑agent** (si tu versión lo soporta):
   - En modo de chat puedes escribir `/create‑agent` y describir el rol (por ejemplo “un agente de revisión de seguridad”) y VS Code te genera un `.agent.md` con herramientas e instrucciones razonables. [code.visualstudio](https://code.visualstudio.com/docs/copilot/guides/customize-copilot-guide)

En tu flujo diario suele ser útil tener al menos:

- Un **Planner** que solo genera planes de implementación.
- Un **Reviewer** que solo revisa código sin tocar ficheros.
- Un **SecurityReviewer** que priorice encontrar vulnerabilidades. [code.visualstudio](https://code.visualstudio.com/docs/copilot/guides/customize-copilot-guide)

---

### Trasfondo conceptual: por qué son útiles

- **Especialización**: cada agente se ajusta a un rol concreto, lo que reduce sesgos y ruido en la respuesta.
- **Control de herramientas**: limitas qué puede hacer (solo leer, solo navegar, solo invocar otros agents), mejorando la seguridad y predictibilidad. [code.visualstudio](https://code.visualstudio.com/docs/copilot/agents/agent-tools)
- **Flujos orquestados**: con handoffs puedes encadenar investigar → implementar → revisar → desplegar, simular workflows de CI/CD o “pair programming” con IA. [code.visualstudio](https://code.visualstudio.com/docs/copilot/agents/agents-tutorial)

Para tu perfil DevOps / Platform‑Engineering, puedes, por ejemplo, crear agents del tipo:

- **Cluster‑Reviewer**: revisa manifests de Kubernetes buscando errores de seguridad y de diseño.
- **Infra‑Reviewer**: revisa Terraform / Ansible contra reglas de tu organización.
- **CI/CD‑Reviewer**: revisa pipelines de GitHub Actions o Jenkins. [code.visualstudio](https://code.visualstudio.com/docs/copilot/agents/local-agents)

## Custom agents de la comunidad

Los **custom agents de la comunidad** se agrupan principalmente en un repositorio central y en algunos repos propios de terceros; no hay un “marketplace único”, pero sí zonas bastante consolidadas para VS Code / GitHub Copilot. [github](https://github.com/github/awesome-copilot)

### Repositorio principal de agents de la comunidad

El sitio más completo es:

- **Awesome‑Copilot (GitHub)**
  - URL: `https://github.com/github/awesome-copilot` [github](https://github.com/github/awesome-copilot/blob/main/docs/README.agents.md)
  - Tiene una sección dedicada a **custom agents** en:
    - `https://awesome‑copilot.github.com/agents/` (listado web con categorías por tecnología y flujo). [awesome-copilot.github](https://awesome-copilot.github.com/agents/)
  - Cómo usarlo:
    - En la página de agents, pincha sobre el agente que te interesa.
    - Haz clic en el botón **“VS Code”** o **“VS Code Insiders”**.
    - Se descargará el fichero `*.agent.md`; lo copias dentro de tu repo, típicamente en `.github/agents/` o en la carpeta de agents que tengas en tu workspace. [docs.github](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents)

### Repositorios de ejemplo y patrones de agentes

Además de Awesome‑Copilot, puedes encontrar repos donde la gente comparte patrones de custom agents:

- **`github/awesome‑copilot`** (también documenta MCP servers y ejemplos de agentes para observabilidad, seguridad, etc.). [github](https://github.com/github/awesome-copilot)
- **Ejemplos específicos de agents** (por ejemplo, Terraform, seguridad, CI/CD) aparecen en otros repos abiertos, como el mencionado en vídeos de formación (por ejemplo, repos enfocados en Terraform modules o security‑review) que se publican en GitHub. [youtube](https://www.youtube.com/watch?v=hY1v3yaaA1c)

En general, buscas:

- Repos con `awesome‑copilot`, `copilot‑agents`, `custom‑agents`, `copilot‑archetype` en el nombre. [github](https://github.com/microsoft/vscode-ai-toolkit)

---

## Tools para navegación y análisis de código

Las herramientas `tools: ['search/codebase', 'search/usages']` son **funcionalidades que el agente de IA puede invocar en VS Code** para navegar y entender tu código. No son instrucciones genéricas, sino nombres concretos de herramientas integradas dentro de GitHub Copilot / VS Code. [code.visualstudio](https://code.visualstudio.com/docs/copilot/agents/agent-tools)

### `search/codebase`

- Es la herramienta que permite al agente **buscar y leer archivos del workspace** (TODO el proyecto, no solo el fichero abierto). [auto-intellect](https://auto-intellect.org/blog/vs-code-copilot-agent-tools)
- Con ella el agente puede:
  - Encontrar archivos por nombre o contenido.
  - Leer el contenido relevante para entender contexto, estructura, convenciones, etc.
- En la práctica, si tu agente tiene `search/codebase` habilitada, puede “ver” tu códigobase completo y usarlo para análisis, refactorizaciones o reviews, siempre que no le hayas restringido permisos. [code.visualstudio](https://code.visualstudio.com/docs/copilot/concepts/tools)

### `search/usages`

- Es la herramienta que permite **buscar referencias/uso de símbolos** (funciones, clases, variables, etc.) en el código. [code.visualstudio](https://code.visualstudio.com/docs/copilot/agents/agent-tools)
- Con ella el agente puede responder preguntas como:
  - “¿Dónde se usa esta función?”
  - “¿Cómo se está llamando esta clase?”
  - “¿Qué módulos dependen de este servicio?”
- Es una herramienta de **navegación semántica**, equivalente a “Find all references” pero desde el agente, no solo desde el editor manual. [learn.microsoft](https://learn.microsoft.com/es-es/visualstudio/ide/visual-studio-search?view=vs-2022)

### Cómo las usas en la práctica

- En el fichero `.agent.md` declaras esas herramientas en el array `tools`, y el agente las usará automáticamente cuando el prompt lo requiera (por ejemplo, “revisa todo el códigobase buscando…”, “mira dónde se usa X”). [code.visualstudio](https://code.visualstudio.com/docs/copilot/concepts/tools)
- También puedes “forzar” su uso en el chat escribiendo `#search/codebase` o `#search/usages` dentro del prompt, para indicar que el agente debe usar específicamente esa capacidad. [auto-intellect](https://auto-intellect.org/blog/vs-code-copilot-agent-tools)

Si quieres, te preparo un ejemplo de `.agent.md` de un agente para revisar Terraform o Kubernetes con `search/codebase` y `search/usages` bien configurados.

`search/usages` sirve para **encontrar y analizar dónde se usan símbolos concretos** (funciones, clases, variables, etc.) en tu código. [code.visualstudio](https://code.visualstudio.com/docs/copilot/agents/agent-tools)

Aquí van ejemplos muy prácticos de cómo podrías usarlo en el chat o en un agente:

---

### 1. Localizar todos los usos de una función

Prompt en el chat de Copilot:

> “Usando `search/usages`, busca todas las llamadas a la función `handleUserLogin` en el proyecto y dímelas en formato lista.  
> Indica también el archivo donde aparece cada uso.”

Resultado que obtienes:

- Una lista de archivos: `auth/service.ts`, `routes/auth.ts`, `tests/auth.test.ts`.
- Líneas donde se llama a `handleUserLogin`, para que puedas ver contextos, parámetros y posibles cambios de API. [code.visualstudio](https://code.visualstudio.com/docs/copilot/concepts/tools)

---

### 2. Ver impacto de borrar o cambiar una clase

Prompt:

> “Usa `search/usages` para encontrar todas las referencias a la clase `ConfigService`.  
> Quiero saber qué módulos dependen de ella antes de refactorizarla.”

Resultado:

- La IA devuelve todos los ficheros donde se instancia o se hace `import` de `ConfigService`.
- Puedes ver si hay módulos críticos (por ejemplo, `database/config.ts`, `logger.ts`) y así decidir si hacer un cambio suave o preparar un plan de migración. [youtube](https://www.youtube.com/watch?v=KRh1_ZU2g8E)

---

### 3. Comprobar si una variable se usa realmente

Prompt:

> “Usa `search/usages` para ver si la variable `tempApiKey` se usa en algún sitio del proyecto.  
> Si no se usa, propón un agente que nos limpie esos usos.”

Resultado típico:

- La IA confirma que `tempApiKey` solo aparece en un fichero de prueba `temp-secrets.ts` como ejemplo.
- Puedes decidir borrarla o convertirla en un placeholder de documentación, sin riesgo de romper código. [docs.github](https://docs.github.com/en/copilot/get-started/best-practices)

---

### 4. Flujos dentro de un custom agent

En un `.agent.md` con `search/usages` habilitado:

```markdown
---
name: Security Checker
description: Busca usos de funciones peligrosas o secretos.
tools: ["search/codebase", "search/usages"]
---

Cuando te pido revisar una función peligrosa:

1. Usa `search/usages` para encontrar todos los llamados a `eval`, `exec`, `process.env.SECRET`, etc.
2. Para cada uso, indica:
   - archivo y línea;
   - si se pasa texto generado por usuario;
   - si hay riesgo de inyección.
```

En la práctica, basta que escribas en el chat:

> “Revisa el proyecto buscando todos los usos de `eval` y `process.env.SECRET` usando `search/usages`.”

## Otras herramientas útiles

En VS Code (GitHub Copilot / agents de VS Code) hay varias **“tools” built‑in** que puedes hacer disponibles en tus agentes además de `search/codebase` y `search/usages`. [code.visualstudio](https://code.visualstudio.com/docs/copilot/agents/agent-tools)

A continuación tienes las más usadas a nivel de custom‑agent, con ejemplos prácticos de cuándo las usarías.

---

### Herramientas de búsqueda y código

- **`search/codebase`**  
  Busca y lee archivos en el workspace.  
  Útil para: revisar todo el código, buscar por nombre o contenido, entender arquitectura. [docs.github](https://docs.github.com/en/copilot/reference/custom-agents-configuration)

- **`search/usages`**  
  Busca referencias/usos de un símbolo (función, clase, variable).  
  Útil para: refactorizar, analizar impacto, limpiar código muerto. [code.visualstudio](https://code.visualstudio.com/docs/copilot/agents/agent-tools)

- **`edit` (tool set)**  
  Permite que el agente **modifique ficheros** (crear, editar, mover, borrar).  
  Útil para: aplicar cambios multi‑fichero, refactorizaciones, migraciones. [code.visualstudio](https://code.visualstudio.com/docs/copilot/reference/copilot-vscode-features)

- **`read_file` / `read_directory`**  
  Herramientas de bajo nivel para leer contenido de ficheros o directorios desde el workspace.  
  Útil para agents que necesitan procesar metadatos, estructura de carpetas, etc. [github](https://github.blog/ai-and-ml/github-copilot/agent-mode-101-all-about-github-copilots-powerful-mode/)

---

### Herramientas de terminal y ejecución

- **`run_in_terminal`**  
  Permite ejecutar comandos en el terminal de VS Code.  
  Útil para: lanzar tests, linters, `terraform plan`, `kubectl apply`, o cualquier comando de infra/CI. [code.visualstudio](https://code.visualstudio.com/docs/copilot/reference/copilot-vscode-features)

- **`todo` / `todoWrite`**  
  Crea y gestiona listas de tareas estructuradas.  
  Útil para agents de planificación: descomponer tareas grandes en una lista de pasos ejecutables. [docs.github](https://docs.github.com/en/copilot/reference/custom-agents-configuration)

---

### Herramientas de agente y orquestación

- **`agent` / `runSubagent`**  
  Permite que un agente invoque otro **subagente** (handoff) con un contexto aislado.  
  Útil para: encadenar flujos (research → implement → review → security) sin que el padre se “contamine” del historial del subagente. [code.visualstudio](https://code.visualstudio.com/docs/copilot/concepts/agents)

- **`agent/setToolApprovals`**  
  Permite configurar qué herramientas se pueden usar (o no) en una sesión de agente.  
  Útil para agents de seguridad/review que solo deben leer código, nunca editar ni ejecutar. [github](https://github.blog/ai-and-ml/github-copilot/agent-mode-101-all-about-github-copilots-powerful-mode/)

---

### Herramientas de web y navegación

- **`web` / `web/fetch`**  
  Permite hacer **búsquedas web** y **descargar contenido de URLs**.  
  Útil para agents que necesitan consultar documentación oficial, changelogs, RFCs, etc. [docs.github](https://docs.github.com/en/copilot/reference/custom-agents-configuration)

- **`browser` (tool set, experimental)**  
  Interactuar con páginas en el navegador integrado de VS Code (navegar, leer, capturas, etc.).  
  Útil para agents que analizan interfaces web, documentación interactiva o dashboards. [code.visualstudio](https://code.visualstudio.com/docs/copilot/reference/copilot-vscode-features)

---

### Cómo verlas tú mismo en VS Code

- En el chat de Copilot:
  - Escribe `#` en el campo de entrada para ver el listado de **todas las tools disponibles** (built‑in, MCP, extensiones, etc.). [code.visualstudio](https://code.visualstudio.com/docs/copilot/agents/agent-tools)
- En un `.agent.md`:
  - En el campo `tools` puedes listar alias como `search`, `agent`, `web`, `todo`, etc., que se resuelven a las herramientas internas equivalentes. [code.visualstudio](https://code.visualstudio.com/docs/copilot/customization/custom-agents)

---

Si quieres, dime qué tipo de agentes estás pensando (por ejemplo: “security reviewer”, “Terraform planner”, “CI/CD refactor agent”) y te armo un `.agent.md` con un conjunto de tools bien elegido para ese caso concreto.

## Como cargar el agente en tu VS Code

### Handoffs: flujos de agentes encadenados

Carga el agente como custom agent normal (pasos descritos en la sección de Custom Agents), pero ten en cuenta que:

- El agente principal (orquestador) es el que debe ser `user-invocable: true` para que puedas seleccionarlo en el dropdown de agents.
- Los sub-agentes que forman parte del flujo deben tener `user-invocable: false` para que no aparezcan en el menú, ya que solo deben ser llamados por el orquestador. [code.visualstudio](https://code.visualstudio.com/docs/copilot/concepts/agents)

Recarga copilot para comprobar que es seleccionable.

## DEVOPS

### Artefactos y configuración

- Dockerfiles multi-distro:
  - `docker/Dockerfile.ubuntu`
  - `docker/Dockerfile.alpine`
- Orquestación local:
  - `docker-compose.yml` con servicios `lint`, `test-ubuntu` y `test-alpine`
- CI/CD:
  - `.github/workflows/ci.yml`
- Variables de entorno:
  - `.env.example`
  - `conf/defaults.sh`
  - `conf/local.sh.sample`
- Guía de deployment:
  - `docs/deployment.md`

### Evidencia de portabilidad Ubuntu/Alpine

La portabilidad se valida en dos capas:

1. **Local con Docker Compose**
   - `docker compose run --rm test-ubuntu`
   - `docker compose run --rm test-alpine`
2. **CI en GitHub Actions**
   - Job `tests-portability` construye y ejecuta tests en contenedores Ubuntu y Alpine usando matriz `distro: [ubuntu, alpine]`.

Con esto, los mismos tests Bats se ejecutan sobre ambas bases Linux para detectar incompatibilidades de shell, utilidades GNU/BSD y empaquetado.

### Variables de entorno

Variables principales para operación y pipeline:

- `DOCKER_IMAGE_PREFIX`: prefijo de imágenes Docker.
- `DOCKER_UID`: UID para ejecutar tests Docker sin privilegios.
- `DOCKER_GID`: GID para ejecutar tests Docker sin privilegios.
- `SHELLCHECK_SEVERITY`: severidad de ShellCheck (`error`, `warning`, `info`, `style`).
- `AGENT_NAME`: agent para smoke tests de instalación.
- `HANDOFF_NAME`: handoff para smoke tests de instalación.
- `INSTALL_SCOPE`: ámbito de instalación (`repo` o `profile`).

Puedes definirlas en `.env` (basado en `.env.example`) o en `conf/local.sh` (basado en `conf/local.sh.sample`).

### Guía rápida de deployment

1. Ejecutar validaciones locales (`lint`, `test-ubuntu`, `test-alpine`).
2. Abrir PR y esperar verde en workflow `.github/workflows/ci.yml`.
3. Hacer merge y crear tag de release.
4. Ejecutar smoke test post-release:

```bash
bash bin/install-agents.sh --agent "${AGENT_NAME:-shell-developer}" --repo
bash bin/install-agents.sh --handoff "${HANDOFF_NAME:-shell}" --repo
```

Referencia completa: `docs/deployment.md`.
