# Session Initialization

At the start of each session, initialize the MCP servers:

1. **GitHub MCP** - Call `mcp__github__get_me` to verify authentication
2. **Serena MCP** - Call `mcp__plugin_serena_serena__activate_project` with project `omarchy`

Serena may take a moment to start up, so check both are responsive before proceeding.

3. **Serena Memories** - Read relevant Serena project memories (especially `suggested_commands`) before exploring the codebase or running commands. Serena lists available memories on activation — use them.
