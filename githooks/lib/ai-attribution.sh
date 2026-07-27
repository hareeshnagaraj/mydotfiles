#!/usr/bin/env sh
# ai-attribution.sh — detect AI authorship-attribution trailers in text.
#
# Single source of truth for the pattern. Sourced by the git commit-msg hook and
# executed directly by CI, so laptop and server can never disagree.
#
# DESIGN: match BOT IDENTITIES, not model names.
#   A bare token match on "claude" rejects legitimate work — "add Claude SDK
#   integration", or a human co-author named Claude. Every real bot trailer
#   observed in this history carries a distinctive machine email domain, while
#   every real human co-author carries an ordinary one. Keying on the domain
#   separates them exactly.
#
#   Verified against 130 real attributed commits across three repos: catches all
#   of them, flags none of the human co-authors (gmail.com / personal
#   users.noreply.github.com).
#
# Usage:
#   ai_attribution_scan <file>     # sourced: prints offending lines, returns 1 if any
#   ai-attribution.sh <file>       # executed: same, exit 1 if any
#   ... | ai-attribution.sh -      # read stdin

# Machine identities. An address here means a tool authored it, never a person.
_AI_BOT_EMAILS='noreply@anthropic\.com|@oh-my-codex\.dev|factory-droid\[bot\]@|codex@openai\.com'

# Tool names, used ONLY where there is no email to key on, or as the display
# name attached to a bot address. Never matched as a bare word in prose.
_AI_TOOL_NAMES='claude|codex|omx|gemini|copilot|chatgpt|gpt-[0-9]|factory-droid|devin|cursor'

# PRODUCT names for the generated-by footer. Deliberately narrower than
# _AI_TOOL_NAMES: "Claude Code" is a product credit, bare "Claude" is a word
# that appears in legitimate engineering prose.
_AI_PRODUCTS='claude code|codex cli|copilot|cursor|devin|gemini cli|chatgpt|oh-my-codex|omx'

ai_attribution_scan() {
    _src="${1:--}"
    if [ "$_src" = "-" ]; then
        _txt=$(cat)
    else
        [ -f "$_src" ] || { printf 'ai-attribution: no such file: %s\n' "$_src" >&2; return 2; }
        _txt=$(cat "$_src")
    fi

    # 1. Co-Authored-By whose address is a known machine identity.
    # 2. Co-Authored-By naming a known tool with NO email at all
    #    (observed: "Co-authored-by: Codex").
    # 3. Co-Authored-By naming a known tool at a noreply/bot address.
    # 4. A generated-by FOOTER: must START the line (optionally after the robot
    #    emoji) and name an AI *product* — "Claude Code", not bare "Claude".
    #    Anchoring here is what keeps "Fixtures generated with Claude SDK mock
    #    server" legitimate: it is prose mid-sentence, not a trailer.
    # 5. A tool URL, which only ever appears in a generated-by footer.
    _hits=$(printf '%s\n' "$_txt" | grep -nEi \
"^[[:space:]]*co-authored-by:.*<[^>]*($_AI_BOT_EMAILS)[^>]*>\
|^[[:space:]]*co-authored-by:[[:space:]]*($_AI_TOOL_NAMES)[[:space:]]*\$\
|^[[:space:]]*co-authored-by:[[:space:]]*($_AI_TOOL_NAMES)[^<]*<[^>]*(noreply|bot)[^>]*>\
|^[[:space:]]*(🤖[[:space:]]*)?(generated|assisted|authored|written)[[:space:]]+(with|by)[[:space:]]+\[?($_AI_PRODUCTS)\
|(claude\.com/claude-code|claude\.ai/code|github\.com/openai/codex)" 2>/dev/null)

    [ -z "$_hits" ] && return 0
    printf '%s\n' "$_hits"
    return 1
}

# Executed directly (CI path) rather than sourced.
case "${0##*/}" in
ai-attribution.sh)
    ai_attribution_scan "$@"
    exit $?
    ;;
esac
