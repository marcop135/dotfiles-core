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
#   6. every <title> is 30-65 characters, every meta description 70-160, and
#      no two pages share a description
#   7. every JSON-LD block parses as JSON, and every {"@id": ...} reference
#      names a node in the same page
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

for f in llms.txt sitemap.xml robots.txt index.md privacy.md .well-known/api-catalog .well-known/security.txt; do
  [ -f "$f" ] || { fail "$f: missing"; continue; }
  for url in $(grep -oE "$CANON/[^\"<>) ]*" "$f" | sort -u); do
    [ -f "$(resolve "${url#"$CANON"}")" ] || fail "$f: canonical URL does not resolve: $url"
  done
done

# ---------- 5. no em-dash ----------
dash=$(grep -rl "$(printf '\342\200\224')" . 2>/dev/null)
[ -z "$dash" ] || for f in $dash; do fail "${f#./}: contains an em-dash"; done

# ---------- 6. title and description ----------
# Characters, not bytes: UTF-8 continuation bytes are dropped before counting.
chars() {
  printf '%s' "$1" |
    sed -e 's/&amp;/\&/g' -e 's/&quot;/"/g' -e "s/&#39;/'/g" -e 's/&lt;/</g' -e 's/&gt;/>/g' |
    LC_ALL=C tr -d '\200-\277' | wc -c | tr -d ' '
}
descs=''
for page in $pages; do
  flat=$(tr '\n' ' ' <"$page")
  title=$(printf '%s' "$flat" | sed -n 's/.*<title>\([^<]*\)<\/title>.*/\1/p')
  n=$(chars "$title")
  { [ "$n" -ge 30 ] && [ "$n" -le 65 ]; } || fail "$page: title is $n characters, not 30-65"
  desc=$(printf '%s' "$flat" | sed -n 's/.*<meta name="description" content="\([^"]*\)">.*/\1/p')
  if [ -z "$desc" ]; then
    fail "$page: no meta description"
    continue
  fi
  n=$(chars "$desc")
  { [ "$n" -ge 70 ] && [ "$n" -le 160 ]; } || fail "$page: description is $n characters, not 70-160"
  descs="$descs$desc
"
done
printf '%s' "$descs" | sort | uniq -d | while IFS= read -r d; do
  echo "FAIL: site/: description used on more than one page: $d"
done | grep . && status=1

# ---------- 7. JSON-LD ----------
# Every ld+json block parses as JSON, and every {"@id": ...} reference names a
# node (an object with @id and other keys) in the same page.
for page in $pages; do
  grep -q 'type="application/ld+json"' "$page" || continue
  ld=$(awk '
    /<script type="application\/ld\+json">/ { on = 1; n++; sub(/.*<script type="application\/ld\+json">/, "") }
    on && /<\/script>/ { sub(/<\/script>.*/, ""); print; print "\001"; on = 0; next }
    on { print }
  ' "$page" | awk '
    function bad(m) { if (!err) err = m " at character " pos; return "" }
    function ws() { while (pos <= n && index(" \t\r\n", substr(s, pos, 1))) pos++ }
    function str(   c, e, out) {
      if (substr(s, pos, 1) != "\"") return bad("expected a string")
      pos++; out = ""
      while (pos <= n) {
        c = substr(s, pos, 1)
        if (c == "\\") {
          e = substr(s, pos + 1, 1)
          if (index("\"\\/bfnrt", e)) { out = out c e; pos += 2; continue }
          if (e == "u" && substr(s, pos + 2, 4) ~ /^[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]$/) { pos += 6; continue }
          return bad("bad escape")
        }
        if (c == "\"") { pos++; return out }
        if (c == "\n" || c == "\t") return bad("raw control character in a string")
        out = out c; pos++
      }
      return bad("unterminated string")
    }
    function value(   c, t) {
      ws(); vstr = ""; c = substr(s, pos, 1)
      if (c == "{") return obj()
      if (c == "[") return arr()
      if (c == "\"") { vstr = str(); return }
      t = substr(s, pos)
      if (match(t, /^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?/)) { pos += RLENGTH; return }
      if (substr(t, 1, 4) == "true" || substr(t, 1, 4) == "null") { pos += 4; return }
      if (substr(t, 1, 5) == "false") { pos += 5; return }
      bad("unexpected " (c == "" ? "end of input" : "\"" c "\""))
    }
    function arr() {
      pos++; ws()
      if (substr(s, pos, 1) == "]") { pos++; return }
      while (!err) {
        value(); ws()
        if (substr(s, pos, 1) == ",") { pos++; continue }
        if (substr(s, pos, 1) == "]") { pos++; return }
        bad("expected , or ]")
      }
    }
    function obj(   k, id, keys) {
      pos++; ws(); keys = 0; id = ""
      if (substr(s, pos, 1) == "}") { pos++; return }
      while (!err) {
        ws(); k = str(); ws()
        if (err) return
        if (substr(s, pos, 1) != ":") { bad("expected :"); return }
        pos++; value(); keys++
        if (k == "@id") id = vstr
        ws()
        if (substr(s, pos, 1) == ",") { pos++; continue }
        if (substr(s, pos, 1) == "}") { pos++; break }
        bad("expected , or }")
      }
      if (id != "") { if (keys > 1) node[id] = 1; else ref[id] = 1 }
    }
    function check() {
      n = length(s); pos = 1; err = ""
      value(); ws()
      if (!err && pos <= n) bad("trailing content")
      if (err) print "block " ++blocks ": " err
      s = ""
    }
    $0 == "\001" { check(); next }
    { s = s $0 "\n" }
    END { for (id in ref) if (!(id in node)) print "@id does not resolve: " id }
  ')
  [ -z "$ld" ] || printf '%s\n' "$ld" | while IFS= read -r line; do fail "$page: JSON-LD $line"; done
  [ -z "$ld" ] || status=1
done

if [ $status -eq 0 ]; then
  echo "site: $(printf '%s\n' "$pages" | wc -l | tr -d ' ') pages, structure balanced, every internal link resolves, metadata in bounds, JSON-LD resolves."
fi
exit $status
