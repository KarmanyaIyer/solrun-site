#!/bin/zsh
# Rebuilds the solrun.app static site from the legal drafts.
# Source of truth: PROD-REPO/development_scratch/legal/{privacy,terms}.md
set -euo pipefail
here=${0:A:h}
site=${here:h}
legal=${site:h}/development_scratch/legal
tpl=$here/template.html

render() { # $1 source md, $2 output dir, $3 title, $4 description
  mkdir -p "$2"
  pandoc "$1" --from gfm --to html5 --standalone --template "$tpl" \
    --metadata pagetitle="$3" --metadata description="$4" \
    --output "$2/index.html"
}

render "$here/index.md" "$site" "Solrun" "Solrun: walk to unlock your apps."
render "$legal/privacy.md" "$site/privacy" "Solrun Privacy Policy" "How Solrun handles your data."
render "$legal/terms.md" "$site/terms" "Solrun Terms of Use" "The terms for using Solrun."

# Washington's My Health My Data Act wants the consumer health policy behind its own link,
# so the matching privacy.md section is also published as a standalone page.
health_md=$here/health.generated.md
{
  print "# Solrun Consumer Health Data Privacy Policy\n"
  grep -m1 '^Effective date:' "$legal/privacy.md"
  print ""
  awk '/^## Consumer health data/{f=1; next} f && /^## /{exit} f' "$legal/privacy.md"
  print "\nThis page repeats the consumer health data section of our [Privacy Policy](/privacy/). ClankerMode LLC, [support@clankermode.com](mailto:support@clankermode.com)."
} > "$health_md"
render "$health_md" "$site/health" "Solrun Consumer Health Data Privacy Policy" "How Solrun handles consumer health data."
cp "$site/index.html" "$site/404.html"
print -n "solrun.app" > "$site/CNAME"
touch "$site/.nojekyll"
if grep -l -E "—|–" "$site"/index.html "$site"/privacy/index.html "$site"/terms/index.html "$site"/health/index.html; then
  print "Found em/en dashes in the output above" >&2; exit 1
fi
print "Built: $site"
