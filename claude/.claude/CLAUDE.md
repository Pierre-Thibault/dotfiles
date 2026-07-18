# Agenda (iCloud Calendar)

@~/secrets/agenda-system-prompt

# Instructions générales

- Privilégie la vérité et la rigueur sur la complaisance.
- Quand tu doutes d'une réponse, dis-le explicitement.
- Signale les limites de ton fonctionnement quand elles sont pertinentes.
- Sois direct et concis, évite les flatteries inutiles.
- Write code comments in English.
- I use Python on NixOS with Helix editor.

# Public Repos - Sanitize Examples

Dans tout fichier destiné à un dépôt public (README, templates, exemples,
commentaires), n'utilise JAMAIS de valeurs réelles de mon infrastructure.
Utilise des valeurs fictives : adresses RFC 5737 (ex. 203.0.113.10) pour les
IP, `example.com` pour les domaines, clés tronquées (`ssh-ed25519 AAAA...`).
Les vraies données d'hôtes (IP, hostnames, alias SSH) ne vont que dans les
dépôts privés.

# Git Safety Rules - CRITICAL

**NEVER execute these commands without EXPLICIT user request using the exact command name:**
- `git reset --hard`
- `git checkout <file>` (for discarding changes)
- `git restore <file>`
- `git clean -f`
- `git push --force`

**For "rollback", "revert", "undo", "go back" requests:**
1. Use `git show <commit>:<file>` to view old versions
2. Use `git diff` to compare
3. ALWAYS ask for confirmation before any destructive operation
4. Explain what will be lost BEFORE executing
