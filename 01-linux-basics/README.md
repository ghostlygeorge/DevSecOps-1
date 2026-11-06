# Lab 01: Linux Basics for CI/CD

## Goal
The handful of shell techniques every later lab and pipeline relies on:
creating files non-interactively (heredocs), redirection, pipes, file
permissions, and `sudo`.

## 1. Here documents — create files without an editor

CI jobs cannot open `vim`. Heredocs are how this whole course writes files:

```bash
cat > filename <<EOL
Some text content
Some text content 2
Some text content 3
EOL
```

- `cat >` creates/overwrites the file.
- `<<EOL ... EOL` feeds everything between the markers to `cat`'s stdin.
- **Quoting gotcha (used later in Ansible/Semgrep labs)**: with `<<EOL`
  the shell still expands `$VAR` and `$(cmd)` inside the body, so the
  course escapes `\$host`. With `<<'EOL'` (quoted marker) nothing is
  expanded, so you don't have to escape anything.

## 2. Redirection

```bash
cat /etc/passwd > mypasswd.txt      # overwrite
cat /etc/passwd >> mypasswd.txt     # append
echo "this is a string" > file.txt
echo $HOSTNAME
cat file.txt                        # -> this is a string
```

- `cmd 2>&1` merges stderr into stdout (important when a tool prints its
  report to stderr — e.g. `nginx -v`, which the Ansible lab captures as `.stderr`).
- `cmd | tee out.json` prints **and** saves the output. Every scanner lab uses this.

## 3. Pipes

```bash
cat mypasswd.txt | cut -d ':' -f 1     # usernames only (field 1, ':' delimiter)
ps -aux | grep bash                    # filter processes
```

## 4. Permissions

```bash
cat > myfile <<EOL
ls
EOL
ls -l myfile          # -rw-r--r--
stat myfile
chmod +x myfile
ls -l myfile          # -rwxr-xr-x   <- note the x bits
./myfile              # ./ = "this directory"; . is not in $PATH
```

Octal refresher, used in the hardening/InSpec labs:
`r=4 w=2 x=1`, so `0600` = owner rw only, `0644` = owner rw + others r, `0755` = rwx/r-x/r-x.

## 5. sudo

```bash
echo -e "pdevsecops\npdevsecops" | adduser --gecos "" john   # --gecos "" skips name/phone prompts
usermod -aG sudo john              # -a append, -G supplementary group
sudo su - john
cat /etc/shadow                    # Permission denied
echo pdevsecops | sudo -S cat /etc/shadow   # -S reads the password from stdin
exit
```

`sudo -S` lets a script pipe the password in. That's convenient for a lab,
but in real automation use NOPASSWD rules scoped to specific commands
instead of putting passwords in pipelines.

## Practice
`practice.sh` in this directory runs every step above in a throwaway
directory:

```bash
bash practice.sh
```

## Notes
- **Permission groups**: owner / group / others. Read them in `ls -l`
  output as `-rwx` (owner) `r-x` (group) `r-x` (others).
- Everything above shows up again: heredocs in pipelines, `tee` for
  scanner reports, `chmod +x` for downloaded binaries (snyk, hadolint,
  tfsec), `chmod 600` for SSH keys in CD jobs.
