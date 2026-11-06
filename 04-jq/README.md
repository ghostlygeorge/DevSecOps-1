# Lab 04: jq — Processing JSON from the Command Line

## Goal
Every scanner in this course emits JSON. `jq` is how you count findings,
filter by severity, and build ignore files. Learn the filters you'll use
again in the RetireJS, Bandit, Checkov, and Nuclei labs.

## Files
- `learnjq.json`: three cloud providers, each with `details` and a `services` array.
- `solutions.sh`: every filter and challenge answer, runnable.

## Core filters

```bash
echo '{"cloudprovider":{"name":"AWS","url":"www.aws.com"}}' | jq '.'   # pretty-print
curl -s https://randomuser.me/api/ | jq '.'                            # API responses
jq '.' learnjq.json

jq '.[] | .details' learnjq.json                                       # iterate array, pick field
jq '.[] | {name: .details.name, url: .details.url}' learnjq.json       # build new objects
jq '.[1] | {name: .details.name, url: .details.url}' learnjq.json      # index -> Azure
jq '[.[] | {name: .details.name, url: .details.url}]' learnjq.json     # wrap in [] -> one array
```

### Nested arrays

```bash
# .services[] fans out -> one object PER service (AWS appears twice)
jq '.[] | {name: .details.name, services: .services[]}' learnjq.json
# collect them back -> one object per provider
jq '.[] | {name: .details.name, url: .details.url, services: [.services[]]}' learnjq.json
jq '.[] | {name: .details.name, url: .details.url, services: .services}' learnjq.json   # same thing
```

### Functions

```bash
jq '.[] | {name: .details.name, servicecount: (.services | length)}' learnjq.json
jq '.[] | select(.details.name=="AWS")' learnjq.json
```

## Challenge: providers offering CI-CD, and their CI-CD service names

```bash
jq '.[] | select(.services[].type=="CI-CD") | .details.name' learnjq.json
jq '.[].services[] | select(.type=="CI-CD")' learnjq.json
jq '.[].services[] | select(.type=="CI-CD") | .name' learnjq.json
```

`select(.services[].type=="CI-CD")` emits the parent **once per matching
child**. If a provider had two CI-CD services it would be printed twice.
Use `select(any(.services[]; .type=="CI-CD"))` to dedupe.

## Flags worth knowing

| Flag | Use |
|---|---|
| `-r` | raw strings (no quotes). Use it to capture into a shell var, e.g. `API_KEY=$(... \| jq -r .token)` |
| `-c` | compact one-line output |
| `-s` | slurp. Turns JSON Lines (nuclei, trufflehog) into one array, e.g. `jq -s length` |
| `-e` | exit code reflects output (false/null gives 1). Handy for CI gates. |
| `--arg n v` | pass shell values safely: `jq --arg s high '.[] \| select(.severity==$s)'` |

## Scanner one-liners you'll use later

```bash
jq '.results | length' bandit-output.json
jq '[.results[] | select(.issue_severity=="HIGH")] | length' bandit-output.json
jq '.data[].results[] | select(.vulnerabilities[]?.severity=="high") | .component,.version' retire_output.json
jq '.[0].summary.failed' checkov-output.json            # checkov -d with several frameworks emits an array
jq -s 'group_by(.info.severity) | map({sev: .[0].info.severity, n: length})' nuclei-output.json
```
