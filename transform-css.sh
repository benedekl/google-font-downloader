#!/bin/sh

set -e
set -u

SRC_CSS=$1

awk -f- "${SRC_CSS}" <<'EOF'
/^\/\* .* \*\// {
  subset = $2
}

/^  font-family: / {
  family = $0
  sub(/^  font-family: '/, "", family)
  sub(/'.*$/, "", family)
  sub(/'/, "\"", $0)
  sub(/'/, "\"", $0)
}

/^  font-style: / {
  style = $0
  sub(/^  font-style: /, "", style)
  sub(/;$/, "", style)
  sub(/^normal$/, "roman", style)
}

/^  src: url\(/ {
  url = $0
  sub(/^  src: url\(/, "", url)
  sub(/\).*$/, "", url)
 
  format = $0
  sub(/^.* format\('/, "", format)
  sub(/'\);$/, "", format)

  filename = tolower(family)
  sub(/ /, "-", filename)
  filename = filename "-" style "-" subset "." format

  print "curl \"" url "\" -o \"" filename "\"" > "download-fonts.sh"

  buff[buffix++] = "  src: url({{asset \"fonts/" filename "\"}}) format(\"" format "\");"
  if (subset == "latin") {
    link[linkix] = "{{asset \"fonts/" filename "\"}}"
    fmt[linkix++] = format
  }
  next
}

{
  buff[buffix++] = $0
}

BEGIN {
  delete buff[0]
  delete link[0]
  delete fmt[0]
  buffix = 0
  linkix = 0
}

END {
  for ( i = 0; i < linkix; i++ ) {
    print "<link rel=\"preload\" as=\"font\" type=\"font/" fmt[i] "\" href=\"" link[i] "\" crossorigin=\"anonymous\">"
  }
  print "<style>"
  for ( i = 0; i < buffix; i++ ) {
    sub(/^  /, "    ", buff[i])
    print "    " buff[i]
  }
  print "</style>"
}

EOF
