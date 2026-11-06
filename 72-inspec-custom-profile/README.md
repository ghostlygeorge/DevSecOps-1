# Lab 72: Writing a Custom InSpec Profile (+ PCI/DSS challenge in CI)

## Goal
Scaffold a profile, write controls, validate, and run them locally and
against prod. Then build a PCI/DSS-style profile, commit it, and run it in
GitLab CI.

## Profile structure

```bash
bash ../71-inspec-basics/install-inspec.sh
mkdir inspec-profile && cd inspec-profile
inspec init profile ubuntu --chef-license accept
# Creating new profile at /inspec-profile/ubuntu
#  • README.md  • controls/example.rb  • inspec.yml
```

`inspec.yml` holds metadata (name, version, supports, **depends**).
`controls/*.rb` holds the tests.

## First control

`profiles/ubuntu/controls/example.rb`:
```ruby
describe file('/etc/shadow') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
end
```

```bash
cp ../72-inspec-custom-profile/profiles/ubuntu/controls/example.rb ubuntu/controls/example.rb
inspec check ubuntu        # Valid: true, No errors, warnings, or offenses
inspec exec ubuntu         # local: 3 successful
inspec exec ubuntu -t ssh://root@$PROD_HOST -i ~/.ssh/id_rsa --chef-license accept   # remote: 3 successful
```

`-t ssh://`, `winrm://`, or `docker://` selects the transport. `-i` is the key
path, and `--chef-license accept` accepts the licence without a prompt.

A bare `describe` works, but wrap it in `control 'id' do impact/title/desc ... end`
for proper reporting ([lab 74](../74-inspec-resources-and-matchers)). Impact
0.0–1.0 maps to none/low/medium/high/critical.

## Challenge: PCI/DSS profile

```bash
cd /inspec-profile
inspec init profile challenge --chef-license accept                 # 1
cp ../72-inspec-custom-profile/profiles/challenge/controls/example.rb challenge/controls/   # 2
inspec check challenge                                              # 3: Controls: 4, Valid: true
inspec exec challenge                                               #    Test Summary: 4 successful, 5 failures
```

Four areas: **system-auth** and **password-auth** PAM password quality
(`pam_pwquality` with `try_first_pass`, `retry ≤ 3`), **useradd** inactivity
lock ≤ 30 days, and **sshd_config** owned by root with `PasswordAuthentication no`.

Why the 5 failures? `/etc/pam.d/system-auth` and `password-auth` are
**RHEL paths**, so on Ubuntu they don't exist and all four `content`
matchers fail (plus `INACTIVE` isn't set). The profile was copied from a
RHEL benchmark. `controls/ubuntu_pam.rb` shows an Ubuntu-correct control
with `only_if { os.debian? }`. Always check a benchmark's target OS.

**4. Commit it**
```bash
cd ~ && git clone git@${GITLAB_HOST}:root/django-nv.git && cd django-nv
cp -r /inspec-profile/challenge challenge
git config --global user.email "you@example.com"; git config --global user.name "Your Name"
git add challenge && git commit -m "Add custom inspec profile" && git push origin main
```

**5. `compliance` job in the test stage**: `gitlab-ci.yml` here (replace
`.gitlab-ci.yml`, commit, push). The official `chef/inspec` image uses
`/share` as its working dir, so `check challenge` / `exec challenge` find the
committed profile.

## Notes
- `its('content') { should match /regex/ }` is the workhorse for config files.
  For key/value configs, prefer typed resources (`sshd_config`,
  `login_defs`, `parse_config_file`). They handle whitespace and comments
  correctly.
