# Lab 75: Reusing Profiles — InSpec Dependencies and Profile Inheritance

## Goal
Build an organisation profile that **inherits** the dev-sec SSH and Linux
baselines, then skips or tweaks individual controls. This is how real
compliance programmes avoid rewriting CIS from scratch.

## Setup

```bash
bash ../71-inspec-basics/install-inspec.sh
mkdir cis-ubuntu && cd cis-ubuntu
inspec init profile ubuntu --chef-license accept
cp ../75-inspec-dependencies/profile/inspec.yml ubuntu/inspec.yml
cp ../75-inspec-dependencies/profile/controls/example.rb ubuntu/controls/example.rb
```

## 1. Declare dependencies (`inspec.yml`)
```yaml
depends:
  - name: SSH baseline
    url: https://github.com/dev-sec/ssh-baseline/archive/master.tar.gz
  - name: Linux Baseline
    url: https://github.com/dev-sec/linux-baseline/archive/master.tar.gz
```
Sources: `url`, `git` (+ `branch`/`tag`), `path`, `supermarket`, `compliance`.

## 2. Vendor them
```bash
cd ubuntu && inspec vendor && cd ..     # downloads into vendor/ and writes inspec.lock
```
`inspec.lock` pins exactly what was fetched. Commit it so CI runs the same
controls every time (`master.tar.gz` moves).

## 3. Include controls
```ruby
include_controls 'SSH baseline'
include_controls 'Linux Baseline' do
  skip_control 'os-10'
  control 'os-05' do
    impact 1.0
  end
end
```
- `include_controls`: inherit **all** controls (optionally skip or modify some).
- `require_controls 'X' do control 'id' end`: inherit **only** the listed ones.

## 4. Run against prod
```bash
echo "StrictHostKeyChecking accept-new" >> ~/.ssh/config
inspec exec ubuntu -t ssh://root@$PROD_HOST -i ~/.ssh/id_rsa --chef-license accept
```
Output groups results per profile: your `tmp-1.0`, then all `ssh-*`
/`sshd-*` controls, then `os-*`/`package-*`/`sysctl-*`.

## Notes
- The course `cat >>` appends to the generated `example.rb`, so the
  scaffolded example control stays in the file too. Harmless, but untidy.
- Override inputs (thresholds, allowed users) of inherited profiles with
  `--input-file inputs.yml` instead of forking them.
