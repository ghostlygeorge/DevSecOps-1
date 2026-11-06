# Lab 74: InSpec Resources and Matchers — `command`, `file`, and Custom Matchers

## Goal
Turn CIS benchmark audit steps into InSpec controls three ways: with the
**command** resource, the **file** resource, and **file properties +
matchers** (`eq`, `cmp`). Learn when to use each.

Setup for all three parts:
```bash
bash ../71-inspec-basics/install-inspec.sh
mkdir cis-ubuntu && cd cis-ubuntu
inspec init profile ubuntu --chef-license accept
```

CIS benchmark PDF: CIS Ubuntu Linux 18.04 LTS Benchmark (cisecurity.org).

## Part A: command resource (CIS 1.3.2 "sudo commands use pty")

1. **Understand the audit command first**, locally:
   ```bash
   grep -Ei "^\s*Defaults\s+([^#]+,\s*)?use_pty(,\s+\S+\s*)*(\s+#.*)?$" /etc/sudoers /etc/sudoers.d/*
   # (nothing) -> not compliant
   cp /etc/sudoers /etc/sudoers.bak
   cat ../74-inspec-resources-and-matchers/sudoers.hardened > /etc/sudoers    # course appends with >>; replacing is cleaner
   visudo -c                                         # ALWAYS validate sudoers syntax
   grep -Ei "..." /etc/sudoers /etc/sudoers.d/*      # /etc/sudoers:Defaults        use_pty
   ```
   An **absence** of output means a control failure.
2. Control: `profiles/command-resource/controls/example.rb`
   ```bash
   cp ../74-inspec-resources-and-matchers/profiles/command-resource/controls/example.rb ubuntu/controls/
   inspec check ubuntu && inspec exec ubuntu         # 1 successful (box was fixed)
   inspec exec ubuntu -t ssh://root@$PROD_HOST -i ~/.ssh/id_rsa --chef-license accept
   # × expected "" to match /Defaults(\s*)use_pty/   -> prod not hardened
   ```

**Why regex?** `Defaults<TAB>use_pty` and `Defaults use_pty` are both
valid sudoers syntax. `/Defaults(\s*)use_pty/` matches any whitespace.
Practice at <https://rubular.com>.

## Part B: file resource (same control)
`profiles/file-resource/controls/example.rb`:
```ruby
describe file('/etc/sudoers') do
  its('content') { should match /Defaults(\s*)use_pty/ }
end
```
On failure the file resource shows the **whole file as a diff**, which is
handy for debugging. "More than one way to do it."

| | command resource | file resource |
|---|---|---|
| Expressiveness | any shell pipeline, the benchmark's audit verbatim | only file properties/content |
| Portability | depends on target having grep etc. | resource-level, transport-independent |
| Quoting pain | yes (Ruby string + shell + regex) | no |
| Prefer when | no resource exists for the check | a resource exists (almost always) |

## Part C: properties + matchers (CIS 5.2.1 sshd_config permissions)

```bash
stat /etc/ssh/sshd_config              # Access: (0666/-rw-rw-rw-)  -> too loose
chown root:root /etc/ssh/sshd_config
chmod og-rwx /etc/ssh/sshd_config      # -> 0600
```
`profiles/custom-matchers/controls/example.rb`:
```ruby
describe file('/etc/ssh/sshd_config') do
  its('owner') { should eq 'root' }
  its('group') { should eq 'root' }
  its('mode')  { should cmp '0600' }
end
```
```bash
inspec exec ubuntu                                    # 3 successful
inspec exec ubuntu -t ssh://root@$PROD_HOST -i ~/.ssh/id_rsa --chef-license accept
# × mode expected: 0600 got: 0666 (compared using `cmp` matcher)
```

`eq` is strict equality (type and value). `cmp` is a "common sense"
comparison: it compares `'0600'` with the integer mode, `'root'` with
`'ROOT'`, version strings, and so on. Use `cmp` for modes and numbers
coming from configs.

## Fixing prod
Run the Ansible hardening role ([lab 62](../62-ansible-hardening)), or the two
commands above over SSH, then rescan. **Detect with InSpec, remediate with
Ansible, rescan continuously.**

## More matchers
`be_installed`, `be_running`, `be_enabled`, `be_listening`, `be_owned_by`,
`be_readable.by('others')`, `include`, `be <`, `cmp >=`, `exist`,
`be_directory`, `match`.
