# Lab 38: SAST for Go with Gosec (local, GitLab, Jenkins)

## Goal
Scan a vulnerable Go web app with **gosec**, cut noise with rule
include/exclude and severity filters, and embed it in GitLab and Jenkins.

## Install

```bash
git clone https://gitlab.practical-devsecops.training/pdso/golang.git webapp && cd webapp
curl -s https://dl.google.com/go/go1.17.4.linux-amd64.tar.gz | tar xvz -C /usr/local
export GOROOT=/usr/local/go GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# course method (curl | sh):
curl -sfL https://raw.githubusercontent.com/securego/gosec/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v2.4.0
# better, using native tooling instead of piping a remote script into a shell:
go install github.com/securego/gosec/v2/cmd/gosec@v2.9.4    # last line that builds on go1.17. (course: go get -u ..., deprecated for installs)
gosec --help
```

> **Course erratum:** `sh -s ---b` has three dashes. It should be `sh -s -- -b`.

**Why is `curl | sh` a security issue?** You execute whatever the server
returns at that moment, unreviewed and unpinned, and a truncated download
can run half a script. Prefer the package manager or a verified,
checksummed release binary.

## Scan

```bash
gosec ./...                                 # ~20 issues across 20 files / 1573 lines
gosec -fmt=json -out=results.json ./...
gosec -exclude=G104 ./...                    # drop "errors unhandled" noise
gosec -include=G201,G202 ./...               # SQL injection rules only
gosec -severity high -confidence high ./...
```

Findings to recognise:

| Rule | Example in this app |
|---|---|
| **G201** SQL string formatting | `fmt.Sprintf("... and u.id=%s", uid)` in `vulnerability/sqli/function.go:37`. **Real.** |
| **G501** import crypto/md5 | `idor.go`, `csa.go`, `user.go` |
| **G104** errors unhandled | `p.GetData(sid)`, `w.Write(b)`. Low severity, noisy. |

**Does `-exclude=G104` remove real issues?** It removes a whole rule
class. Unchecked errors *can* matter (a failed auth check whose error is
ignored), so prefer `#nosec G104 -- justification` on specific lines, or
exclude G104 only in reporting, not in the gate.

## GitLab CI (golang project)

```bash
git clone https://gitlab.practical-devsecops.training/pdso/golang.git golang && cd golang
git remote rename origin old-origin
git remote add origin git@${GITLAB_HOST}:root/golang.git
git push -u origin --all
```
Paste `ci/gitlab-ci.yml`.

## Jenkins
Job `golang`, webhook `/project/golang`
([common/JENKINS-JOB-SETUP.md](../common/JENKINS-JOB-SETUP.md)). The course
pushes with `git checkout -b main && git push -u origin main` over HTTP.
`ci/Jenkinsfile` passes `/src/...` as the target with `-w /src`.

## Notes
- The `./...` pattern means "this package and all sub-packages".
- `#nosec` (and `-nosec` to ignore those comments) plus `-track-suppressions`
  for auditing suppressions.
- Formats: json, yaml, csv, junit-xml, html, sonarqube, sarif, golint, text.
