#!/usr/bin/env bash
# The gate for site/, the static page at dotfiles.marcopontili.com.
#
#   bash ./scripts/check-site.sh
#
#   1. every page has the doctype, lang, charset, viewport, one <title>,
#      one <h1>, a <main>, and a skip link as its first focusable element
#   2. every non-void element is closed, in order, and no id repeats
#   3. no inline style attribute and no inline script, so the CSP holds
#      without 'unsafe-inline' (JSON-LD data blocks are allowed)
#   4. every internal href and src, every same-page #anchor, every manifest
#      icon, and every canonical URL in llms.txt and sitemap.xml resolves to a
#      file in site/
#   5. no em-dash anywhere in site/
#
# Same rules as check.sh: bash 3.2, POSIX awk, nothing to install. It is a
# structural check, not the W3C validator.
set -uo pipefail

case ${1-} in
  '') ;;
  -h | --help)
    awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "${BASH_SOURCE[0]}"
    exit 0
    ;;
  *) echo "check-site.sh: unknown option: $1" >&2; exit 2 ;;
esac

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/site" || exit 1

CANON='https://dotfiles.marcopontili.com'
status=0
fail() { echo "FAIL: site/$*"; status=1; }

# A site path, as written in a link, to the file that serves it.
resolve() {
  local p=${1%%[?#]*}
  case $p in
    ('' | /) p=index.html ;;
    (*/) p=${p#/}index.html ;;
    (/*) p=${p#/} ;;
  esac
  printf '%s' "$p"
}

pages=$(find . -name '*.html' -not -path './.git/*' | sed 's|^\./||' | sort)
[ -n "$pages" ] || { echo 'FAIL: site/ has no html'; exit 1; }

for page in $pages; do
  # One line per file makes the attribute greps immune to wrapping.
  flat=$(tr '\n' ' ' <"$page")

  # ---------- 1. required document structure ----------
  head -n 1 "$page" | grep -qi '^<!doctype html>$' || fail "$page: first line is not <!DOCTYPE html>"
  grep -q '<html lang="[a-z][a-z-]*"' "$page" || fail "$page: <html> has no lang"
  grep -qi '<meta charset="utf-8">' "$page" || fail "$page: no <meta charset=\"utf-8\">"
  grep -q '<meta name="viewport" content="width=device-width, initial-scale=1">' "$page" ||
    fail "$page: no viewport meta"
  n=$(grep -o '<title>[^<][^<]*</title>' "$page" | wc -l | tr -d ' ')
  [ "$n" = 1 ] || fail "$page: expected one non-empty <title>, found $n"
  n=$(printf '%s' "$flat" | grep -o '<h1[ >]' | wc -l | tr -d ' ')
  [ "$n" = 1 ] || fail "$page: expected one <h1>, found $n"
  grep -q '<main id="main"' "$page" || fail "$page: no <main id=\"main\">"
  first=$(printf '%s' "$flat" | sed 's/.*<body>//' | grep -oE '<(a|button|input|select|textarea|summary)[ >][^>]*' | head -n 1)
  case $first in
    (*'href="#main"'*) ;;
    (*) fail "$page: first focusable element is not the skip link to #main" ;;
  esac

  # ---------- 2. balanced elements, unique ids ----------
  balance=$(awk '
    BEGIN {
      split("area base br col embed hr img input link meta source track wbr", v, " ")
      for (i in v) void[v[i]] = 1
    }
    { doc = doc $0 "\n" }
    END {
      # Comments and script bodies are not markup.
      while ((s = index(doc, "<!--")) > 0) {
        e = index(substr(doc, s), "-->")
        if (e == 0) { print "unclosed comment"; exit }
        doc = substr(doc, 1, s - 1) substr(doc, s + e + 2)
      }
      out = ""
      while (match(doc, /<script[^>]*>/)) {
        out = out substr(doc, 1, RSTART + RLENGTH - 1)
        doc = substr(doc, RSTART + RLENGTH)
        e = index(doc, "</script>")
        if (e == 0) { print "unclosed <script>"; exit }
        doc = substr(doc, e)
      }
      doc = out doc
      depth = 0
      while (match(doc, /<\/?[A-Za-z][A-Za-z0-9-]*/)) {
        tag = tolower(substr(doc, RSTART, RLENGTH))
        doc = substr(doc, RSTART + RLENGTH)
        if (substr(tag, 2, 1) == "/") {
          name = substr(tag, 3)
          if (depth == 0 || stack[depth] != name) {
            print "</" name "> does not close <" (depth ? stack[depth] : "nothing") ">"
            exit
          }
          depth--
        } else {
          name = substr(tag, 2)
          if (name in void) continue
          # A self-closing tag such as <path ... /> inside inline SVG.
          gt = index(doc, ">")
          if (gt > 1 && substr(doc, gt - 1, 1) == "/") continue
          stack[++depth] = name
        }
      }
      if (depth) print "<" stack[depth] "> is never closed"
    }' "$page")
  [ -z "$balance" ] || fail "$page: $balance"

  dup_ids=$(printf '%s' "$flat" | grep -oE ' id="[^"]+"' | sort | uniq -d)
  [ -z "$dup_ids" ] || fail "$page: repeated$(printf ' %s' $dup_ids)"

  # ---------- 3. nothing the CSP would block ----------
  printf '%s' "$flat" | grep -qE '<[a-z][^>]* style="' && fail "$page: inline style attribute"
  printf '%s' "$flat" | grep -oE '<script[^>]*>' | grep -v ' src="' | grep -qv 'type="application/ld+json"' &&
    fail "$page: inline script"

  # ---------- 4. internal links ----------
  refs=$(printf '%s' "$flat" | grep -oE ' (href|src)="[^"]*"' | sed -E 's/^ (href|src)="//; s/"$//')
  for ref in $refs; do
    case $ref in
      (http://* | https://* | mailto:* | data:*) continue ;;
      ('#'*)
        id=${ref#\#}
        printf '%s' "$flat" | grep -q " id=\"$id\"" || fail "$page: no element with id \"$id\""
        continue
        ;;
    esac
    f=$(resolve "$ref")
    [ -f "$f" ] || fail "$page: link does not resolve: $ref"
  done
done

for icon in $(grep -oE '"src": *"[^"]+"' site.webmanifest | sed -E 's/.*"([^"]+)"$/\1/'); do
  [ -f "$(resolve "$icon")" ] || fail "site.webmanifest: icon does not resolve: $icon"
done

for f in llms.txt sitemap.xml robots.txt index.md .well-known/api-catalog .well-known/security.txt; do
  [ -f "$f" ] || { fail "$f: missing"; continue; }
  for url in $(grep -oE "$CANON/[^\"<>) ]*" "$f" | sort -u); do
    [ -f "$(resolve "${url#"$CANON"}")" ] || fail "$f: canonical URL does not resolve: $url"
  done
done

# ---------- 5. no em-dash ----------
dash=$(grep -rl "$(printf '\342\200\224')" . 2>/dev/null)
[ -z "$dash" ] || for f in $dash; do fail "${f#./}: contains an em-dash"; done

if [ $status -eq 0 ]; then
  echo "site: $(printf '%s\n' "$pages" | wc -l | tr -d ' ') pages, structure balanced, every internal link resolves."
fi
exit $status
