#!/bin/sh
# Build a flat JSON object describing Claude Code's effective configuration:
# ~/.claude.json, ~/.claude/settings.json (or $CLAUDE_CONFIG_DIR/...), the
# global gitignore, and Claude Desktop Native Messaging manifests.
# Consumed by obacht's Rego policies — every field name maps to a rule.

# === helpers ===

# Escape a string for embedding inside a JSON double-quoted literal.
json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Read stdin; emit "true"|"false" for the first match of "key": <bool>, else
# "unset". Pattern-matches at any depth; relies on key uniqueness for nested
# fields (e.g. sandbox.failIfUnavailable in .claude.json).
extract_bool() {
  key=$1
  value=$(grep -o "\"$key\"[[:space:]]*:[[:space:]]*\(true\|false\)" 2>/dev/null \
          | head -1 | sed 's/.*:[[:space:]]*//')
  [ -z "$value" ] && printf 'unset' || printf '%s' "$value"
}

# Read stdin; emit the string value of "key": "<value>", or "unset" if missing.
# Distinguishes missing (-> "unset") from explicit empty (-> "") because the
# attribution.commit/pr rule (CLD026) expects "" as the hardened state.
# Does NOT handle escaped quotes inside JSON strings.
extract_string() {
  key=$1
  content=$(cat)
  if printf '%s' "$content" | grep -Eq "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\""; then
    printf '%s' "$content" | grep -Eo "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
      | head -1 | sed 's/.*:[[:space:]]*"\(.*\)"[[:space:]]*$/\1/'
  else
    printf 'unset'
  fi
}

# Read stdin; emit the {...} body of a "key": {...} object via balanced-brace
# counting, so nested objects are included verbatim. Empty output if not found.
extract_block() {
  awk -v key="$1" '
    { data = data $0 "\n" }
    END {
      pat = "\""key"\"[[:space:]]*:[[:space:]]*\\{"
      if (match(data, pat)) {
        start = RSTART + RLENGTH - 1
        depth = 1
        for (i = start + 1; i <= length(data); i++) {
          c = substr(data, i, 1)
          if (c == "{") depth++
          else if (c == "}") {
            depth--
            if (depth == 0) {
              printf "%s", substr(data, start, i - start + 1)
              exit
            }
          }
        }
      }
    }
  '
}

# Read stdin; emit "true" if the flat string array at <key> contains <needle>,
# else "false". Handles only flat string arrays (no nested objects/arrays).
array_contains() {
  key=$1
  needle=$2
  arr=$(tr '\n' ' ' | grep -Eo "\"$key\"[[:space:]]*:[[:space:]]*\\[[^]]*\\]" | head -1)
  if [ -n "$arr" ] && printf '%s' "$arr" | grep -Fq "\"$needle\""; then
    printf 'true'
  else
    printf 'false'
  fi
}

# Read stdin; emit space-separated needles missing from the flat string array
# at <key>. Empty output means all present (or array missing -> all reported).
array_missing() {
  key=$1
  shift
  arr=$(tr '\n' ' ' | grep -Eo "\"$key\"[[:space:]]*:[[:space:]]*\\[[^]]*\\]" | head -1)
  missing=
  for needle in "$@"; do
    if [ -z "$arr" ] || ! printf '%s' "$arr" | grep -Fq "\"$needle\""; then
      missing="${missing:+$missing }$needle"
    fi
  done
  printf '%s' "$missing"
}

# === defaults ===

installed=false
gitignore_excludes_settings=false

config_present=false
auto_compact_enabled=unset
pr_status_footer_enabled=unset
claude_in_chrome_default_enabled=unset
sandbox_fail_if_unavailable=unset

settings_present=false
env_disable_compact=unset
env_disable_telemetry=unset
env_disable_bug_command=unset
env_disable_auto_compact=unset
env_disable_login_command=unset
env_disable_logout_command=unset
env_disable_error_reporting=unset
env_disable_upgrade_command=unset
env_disable_feedback_command=unset
env_disable_extra_usage_command=unset
env_claude_code_disable_fast_mode=unset
env_disable_install_github_app_command=unset
env_claude_code_disable_cron=unset
env_claude_code_disable_feedback_survey=unset
env_claude_code_disable_file_checkpointing=unset
env_claude_code_disable_experimental_betas=unset
env_force_autoupdate_plugins=unset
env_is_demo=unset

settings_disable_auto_mode=unset
settings_disable_deep_link_registration=unset
settings_auto_memory_directory=unset
settings_plans_directory=unset
settings_respect_gitignore=unset
settings_skip_web_fetch_preflight=unset
settings_attribution_commit=unset
settings_attribution_pr=unset

sandbox_enabled=unset
sandbox_auto_allow_bash_if_sandboxed=unset
sandbox_allow_unsandboxed_commands=unset
sandbox_network_allow_managed_domains_only=unset
sandbox_network_allowed_domains_has_github=false
sandbox_network_denied_domains_has_uploads_github=false
sandbox_filesystem_allow_write_has_npm_logs=false
sandbox_filesystem_allow_write_has_claude_debug=false

permissions_present=false
permissions_disable_bypass_mode=unset
permissions_deny_network_missing=
permissions_deny_destructive_fs_missing=
permissions_deny_git_missing=
permissions_deny_home_secrets_missing=
permissions_deny_project_secrets_missing=

# === Claude Desktop Native Messaging manifests ===
# Detect com.anthropic.claude_browser_extension.json under ~/Library/Application
# Support. Mitigated = file ≤1 byte AND user-immutable (uchg) flag set, so
# Claude Desktop cannot rewrite it on next launch (tolerates both `: > f`
# (0 bytes) and `echo "" > f` (1-byte newline) variants).
claude_desktop_native_messaging_manifests='[]'
manifest_search_dir="$HOME/Library/Application Support"
if [ -d "$manifest_search_dir" ]; then
  # Bounded depth — manifests live at <browser>/[<profile>/]NativeMessagingHosts/
  # so 5 levels is enough; avoids walking the whole Application Support tree.
  manifest_files=$(find "$manifest_search_dir" -maxdepth 5 -type f \
    -name "com.anthropic.claude_browser_extension.json" 2>/dev/null)
  if [ -n "$manifest_files" ]; then
    saved_ifs=$IFS
    IFS='
'
    json='['
    first=1
    for mf in $manifest_files; do
      stat_out=$(stat -f "%z %Sf" "$mf" 2>/dev/null || printf '0 ')
      mf_size=${stat_out% *}
      mf_flags=${stat_out#* }
      if [ "$mf_size" -le 1 ] && [ "$mf_flags" = uchg ]; then
        continue
      fi
      mf_escaped=$(json_escape "$mf")
      if [ "$first" = 1 ]; then
        json="${json}\"${mf_escaped}\""
        first=0
      else
        json="${json},\"${mf_escaped}\""
      fi
    done
    IFS=$saved_ifs
    claude_desktop_native_messaging_manifests="${json}]"
  fi
fi

# === Claude Code installed? ===
if command -v claude >/dev/null 2>&1; then
  installed=true

  # Global gitignore excludes Claude Code's local settings file?
  excludes_file=$(git config --global core.excludesfile 2>/dev/null || true)
  if [ -n "$excludes_file" ]; then
    excludes_file=$(eval echo "$excludes_file")
    if [ -f "$excludes_file" ] && grep -Fxq '**/.claude/settings.local.json' "$excludes_file" 2>/dev/null; then
      gitignore_excludes_settings=true
    fi
  fi

  # ~/.claude.json (read once, then probe)
  config_file="${CLAUDE_CONFIG_DIR:-$HOME}/.claude.json"
  if [ -f "$config_file" ]; then
    config_present=true
    config_content=$(cat "$config_file")
    auto_compact_enabled=$(printf '%s' "$config_content" | extract_bool autoCompactEnabled)
    pr_status_footer_enabled=$(printf '%s' "$config_content" | extract_bool prStatusFooterEnabled)
    claude_in_chrome_default_enabled=$(printf '%s' "$config_content" | extract_bool claudeInChromeDefaultEnabled)
    # failIfUnavailable lives nested under "sandbox"; the flat regex picks
    # it up because no other key in .claude.json shares the name.
    sandbox_fail_if_unavailable=$(printf '%s' "$config_content" | extract_bool failIfUnavailable)
  fi

  # ~/.claude/settings.json (read once, then probe)
  settings_file="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
  if [ -f "$settings_file" ]; then
    settings_present=true
    settings_content=$(cat "$settings_file")

    # env block — driven by a single list so adding a key is one line.
    env_keys="DISABLE_COMPACT DISABLE_TELEMETRY DISABLE_BUG_COMMAND
              DISABLE_AUTO_COMPACT DISABLE_LOGIN_COMMAND DISABLE_LOGOUT_COMMAND
              DISABLE_ERROR_REPORTING DISABLE_UPGRADE_COMMAND
              DISABLE_FEEDBACK_COMMAND DISABLE_EXTRA_USAGE_COMMAND
              CLAUDE_CODE_DISABLE_FAST_MODE DISABLE_INSTALL_GITHUB_APP_COMMAND
              CLAUDE_CODE_DISABLE_CRON CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY
              CLAUDE_CODE_DISABLE_FILE_CHECKPOINTING
              CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS
              FORCE_AUTOUPDATE_PLUGINS IS_DEMO"
    for k in $env_keys; do
      lk=$(printf '%s' "$k" | tr '[:upper:]' '[:lower:]')
      v=$(printf '%s' "$settings_content" | extract_string "$k")
      eval "env_$lk=\$v"
    done

    settings_disable_auto_mode=$(printf '%s' "$settings_content" | extract_string disableAutoMode)
    settings_disable_deep_link_registration=$(printf '%s' "$settings_content" | extract_string disableDeepLinkRegistration)
    settings_auto_memory_directory=$(printf '%s' "$settings_content" | extract_string autoMemoryDirectory)
    settings_plans_directory=$(printf '%s' "$settings_content" | extract_string plansDirectory)
    settings_respect_gitignore=$(printf '%s' "$settings_content" | extract_bool respectGitignore)
    settings_skip_web_fetch_preflight=$(printf '%s' "$settings_content" | extract_bool skipWebFetchPreflight)

    attribution_block=$(printf '%s' "$settings_content" | extract_block attribution)
    if [ -n "$attribution_block" ]; then
      settings_attribution_commit=$(printf '%s' "$attribution_block" | extract_string commit)
      settings_attribution_pr=$(printf '%s' "$attribution_block" | extract_string pr)
    fi

    sandbox_block=$(printf '%s' "$settings_content" | extract_block sandbox)
    if [ -n "$sandbox_block" ]; then
      sandbox_enabled=$(printf '%s' "$sandbox_block" | extract_bool enabled)
      sandbox_auto_allow_bash_if_sandboxed=$(printf '%s' "$sandbox_block" | extract_bool autoAllowBashIfSandboxed)
      sandbox_allow_unsandboxed_commands=$(printf '%s' "$sandbox_block" | extract_bool allowUnsandboxedCommands)

      network_block=$(printf '%s' "$sandbox_block" | extract_block network)
      if [ -n "$network_block" ]; then
        sandbox_network_allow_managed_domains_only=$(printf '%s' "$network_block" | extract_bool allowManagedDomainsOnly)
        sandbox_network_allowed_domains_has_github=$(printf '%s' "$network_block" | array_contains allowedDomains 'github.com')
        sandbox_network_denied_domains_has_uploads_github=$(printf '%s' "$network_block" | array_contains deniedDomains 'uploads.github.com')
      fi

      filesystem_block=$(printf '%s' "$sandbox_block" | extract_block filesystem)
      if [ -n "$filesystem_block" ]; then
        sandbox_filesystem_allow_write_has_npm_logs=$(printf '%s' "$filesystem_block" | array_contains allowWrite '~/.cache/npm/logs')
        sandbox_filesystem_allow_write_has_claude_debug=$(printf '%s' "$filesystem_block" | array_contains allowWrite '~/.config/claude/debug')
      fi
    fi

    permissions_block=$(printf '%s' "$settings_content" | extract_block permissions)
    if [ -n "$permissions_block" ]; then
      permissions_present=true
      permissions_disable_bypass_mode=$(printf '%s' "$permissions_block" | extract_string disableBypassPermissionsMode)
      permissions_deny_network_missing=$(printf '%s' "$permissions_block" | array_missing deny \
        'Bash(nc:*)' 'Bash(netcat:*)' 'Bash(socat:*)' \
        'Bash(ssh:*)' 'Bash(scp:*)' 'Bash(rsync:*)')
      permissions_deny_destructive_fs_missing=$(printf '%s' "$permissions_block" | array_missing deny \
        'Bash(chmod 777:*)' 'Bash(chown:*)' \
        'Bash(rm -rf /:*)' 'Bash(rm -rf ~:*)' \
        'Bash(dd:*)' 'Bash(mkfs:*)')
      permissions_deny_git_missing=$(printf '%s' "$permissions_block" | array_missing deny \
        'Bash(git push:*)' 'Bash(git tag:*)' 'Bash(git reset --hard:*)')
      permissions_deny_home_secrets_missing=$(printf '%s' "$permissions_block" | array_missing deny \
        'Read(~/.ssh/**)' 'Read(~/.aws/**)' 'Read(~/.gnupg/**)' \
        'Read(~/.config/gh/**)' 'Read(~/.kube/**)' 'Read(~/.docker/config.json)')
      permissions_deny_project_secrets_missing=$(printf '%s' "$permissions_block" | array_missing deny \
        'Read(./.env)' 'Read(./.env.*)' 'Read(./*.pem)' 'Read(./*.key)' \
        'Read(./**/.env)' 'Read(./**/.env.*)' 'Read(./**/*.pem)' 'Read(./**/*.key)' \
        'Read(./**/id_rsa*)' 'Read(./**/id_ed25519*)' 'Read(./**/credentials*)')
    fi
  fi
fi

# === emit ===
# User-supplied paths get JSON-escaped; sentinel values
# ("unset"/"true"/"false"/"1"/"disable"/"") need no escaping.
amd_esc=$(json_escape "$settings_auto_memory_directory")
plans_esc=$(json_escape "$settings_plans_directory")
attr_commit_esc=$(json_escape "$settings_attribution_commit")
attr_pr_esc=$(json_escape "$settings_attribution_pr")

printf '{"installed": %s, "gitignore_excludes_settings": %s, "config_present": %s, "auto_compact_enabled": "%s", "pr_status_footer_enabled": "%s", "claude_in_chrome_default_enabled": "%s", "sandbox_fail_if_unavailable": "%s", "settings_present": %s, "env_disable_compact": "%s", "env_disable_telemetry": "%s", "env_disable_bug_command": "%s", "env_disable_auto_compact": "%s", "env_disable_login_command": "%s", "env_disable_logout_command": "%s", "env_disable_error_reporting": "%s", "env_disable_upgrade_command": "%s", "env_disable_feedback_command": "%s", "env_disable_extra_usage_command": "%s", "env_claude_code_disable_fast_mode": "%s", "env_disable_install_github_app_command": "%s", "env_claude_code_disable_cron": "%s", "env_claude_code_disable_feedback_survey": "%s", "env_claude_code_disable_file_checkpointing": "%s", "env_claude_code_disable_experimental_betas": "%s", "env_force_autoupdate_plugins": "%s", "env_is_demo": "%s", "settings_disable_auto_mode": "%s", "settings_disable_deep_link_registration": "%s", "settings_auto_memory_directory": "%s", "settings_plans_directory": "%s", "settings_respect_gitignore": "%s", "settings_skip_web_fetch_preflight": "%s", "settings_attribution_commit": "%s", "settings_attribution_pr": "%s", "sandbox_enabled": "%s", "sandbox_auto_allow_bash_if_sandboxed": "%s", "sandbox_allow_unsandboxed_commands": "%s", "sandbox_network_allow_managed_domains_only": "%s", "sandbox_network_allowed_domains_has_github": "%s", "sandbox_network_denied_domains_has_uploads_github": "%s", "sandbox_filesystem_allow_write_has_npm_logs": "%s", "sandbox_filesystem_allow_write_has_claude_debug": "%s", "permissions_present": %s, "permissions_disable_bypass_mode": "%s", "permissions_deny_network_missing": "%s", "permissions_deny_destructive_fs_missing": "%s", "permissions_deny_git_missing": "%s", "permissions_deny_home_secrets_missing": "%s", "permissions_deny_project_secrets_missing": "%s", "claude_desktop_native_messaging_manifests": %s}' \
  "$installed" "$gitignore_excludes_settings" "$config_present" \
  "$auto_compact_enabled" "$pr_status_footer_enabled" \
  "$claude_in_chrome_default_enabled" "$sandbox_fail_if_unavailable" \
  "$settings_present" \
  "$env_disable_compact" "$env_disable_telemetry" "$env_disable_bug_command" \
  "$env_disable_auto_compact" "$env_disable_login_command" "$env_disable_logout_command" \
  "$env_disable_error_reporting" "$env_disable_upgrade_command" "$env_disable_feedback_command" \
  "$env_disable_extra_usage_command" "$env_claude_code_disable_fast_mode" "$env_disable_install_github_app_command" \
  "$env_claude_code_disable_cron" "$env_claude_code_disable_feedback_survey" "$env_claude_code_disable_file_checkpointing" \
  "$env_claude_code_disable_experimental_betas" "$env_force_autoupdate_plugins" "$env_is_demo" \
  "$settings_disable_auto_mode" "$settings_disable_deep_link_registration" \
  "$amd_esc" "$plans_esc" \
  "$settings_respect_gitignore" "$settings_skip_web_fetch_preflight" \
  "$attr_commit_esc" "$attr_pr_esc" \
  "$sandbox_enabled" "$sandbox_auto_allow_bash_if_sandboxed" "$sandbox_allow_unsandboxed_commands" \
  "$sandbox_network_allow_managed_domains_only" "$sandbox_network_allowed_domains_has_github" "$sandbox_network_denied_domains_has_uploads_github" \
  "$sandbox_filesystem_allow_write_has_npm_logs" "$sandbox_filesystem_allow_write_has_claude_debug" \
  "$permissions_present" "$permissions_disable_bypass_mode" \
  "$permissions_deny_network_missing" "$permissions_deny_destructive_fs_missing" \
  "$permissions_deny_git_missing" "$permissions_deny_home_secrets_missing" \
  "$permissions_deny_project_secrets_missing" \
  "$claude_desktop_native_messaging_manifests"
