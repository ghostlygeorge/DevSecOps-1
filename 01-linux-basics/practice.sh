#!/usr/bin/env bash
# Walks through lab 01 non-destructively in a temp directory.
set -euo pipefail
work=$(mktemp -d)
cd "$work"
echo "[*] working in $work"

cat > filename <<EOL
Some text content
Some text content 2
EOL
echo "[*] heredoc file:"; cat filename

name="world"
cat > expanded.txt <<EOL
hello $name
EOL
cat > literal.txt <<'EOL'
hello $name
EOL
echo "[*] unquoted marker expands -> $(cat expanded.txt)"
echo "[*] quoted marker is literal -> $(cat literal.txt)"

cat /etc/passwd > mypasswd.txt
cat /etc/passwd >> mypasswd.txt
echo "[*] passwd lines after append: $(wc -l < mypasswd.txt)"
echo "[*] first 5 usernames:"; cut -d ':' -f 1 mypasswd.txt | head -5

printf 'ls\n' > myfile
ls -l myfile
chmod +x myfile
ls -l myfile
echo "[*] running ./myfile:"; ./myfile

echo "[*] tee demo:"; echo '{"ok": true}' | tee out.json
rm -rf "$work"
echo "[*] cleaned up"
