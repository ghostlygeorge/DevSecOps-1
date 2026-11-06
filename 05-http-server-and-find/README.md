# Lab 05: Serving Files over HTTP and Finding Files

## Goal
Two utilities you'll use for practical reasons: a throwaway HTTP server
to **download reports** (HTML scan reports, KICS results) from the
DevSecOps-Box to your laptop, and `find` to locate things.

## Python HTTP server

```bash
cat > home_page.html <<EOL
<html><body><p>Welcome to the home page!</p></body></html>
EOL
python3 -m http.server &            # serves CWD on 0.0.0.0:8000 (& = background)
# python 2: python -m SimpleHTTPServer
```

Browse: `https://devsecops-box-<id>-8000.lab.practical-devsecops.training`
(the lab proxies `<host>-<port>`). Right-click a file → *Save as*. Port
80 is reachable at `$DSO_BOX_URL` directly (lab 70 uses
`python -m http.server 80`).

Only files under the directory you started it in are served. Stop it with
`kill %1` or `fg` then Ctrl+C. Never leave it running on a real host:
it serves everything under the CWD, `.git` and `.env` included.

## find

```bash
mkdir -p /home/user/documents
touch /home/user/documents/{file1.txt,file2.txt,important.txt,document.doc}

find /home/user/documents -name "*.txt"     # by name/glob (quote it!)
find /home/user/documents -type d           # directories (f=file, l=symlink)
find /home/user/documents -size +1M         # bigger than 1 MiB
find / -name "*.json" -newer /tmp/marker 2>/dev/null   # recently written reports
find /home/user/documents -name "*.txt" -delete        # DESTRUCTIVE
```

**Run destructive `find` without `-delete` / `-exec rm` first** and read
the list. Deletion is irreversible.

### Security uses
```bash
find / -perm -4000 -type f 2>/dev/null            # SUID binaries (privesc review)
find / -xdev -type f -perm -0002 2>/dev/null      # world-writable files (InSpec/Lynis flag these)
find . -name "id_rsa*" -o -name "*.pem"           # stray keys in a repo before commit
```
