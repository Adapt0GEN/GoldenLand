\# GoldenLand Gemini Context



\## Project



GoldenLand / "Золотая земля" is a Roblox/Rojo single-player RPG/survival/island development game.



\## Required workflow



Before changing anything:



1\. Run:

&#x20;  git status --short



2\. If the working tree is not clean:

&#x20;  - stop immediately;

&#x20;  - show the git status result;

&#x20;  - do not edit files.



3\. If the working tree is clean, read:

&#x20;  - docs/00\_codex\_context.md

&#x20;  - docs/05\_current\_state.md

&#x20;  - docs/06\_development\_rules.md

&#x20;  - docs/planning/05\_next\_codex\_task.md



4\. Execute only the task described in:

&#x20;  docs/planning/05\_next\_codex\_task.md



\## Hard rules



\- Edit code only in src/.

\- Do not create src/Workspace.

\- Do not map Workspace through Rojo.

\- Do not edit default.project.json unless the task explicitly requires it.

\- Do not touch R15/R6/avatar/player rig/avatar settings.

\- Do not add combat, classes, backpack, food/fatigue, automation, or unrelated systems unless the task explicitly requires it.

\- Do not make broad refactors.

\- Keep each MVP step small.

\- Do not change files outside the requested task scope.

\- Use existing services and patterns where possible.

\- All resource changes must happen on the server.

\- Check that no Git conflict markers remain:

&#x20; <<<<<<<

&#x20; =======

&#x20; >>>>>>>



\## Expected response format



At the end provide:



1\. git status result from before changes;

2\. files changed;

3\. short explanation of what changed;

4\. diff summary;

5\. Roblox Studio test checklist;

6\. any risks or things I should verify manually.

