# Lab 76: Building an InSpec Profile from the CIS Benchmark

## Goal
Convert a CIS benchmark section ("1.3 Configure sudo") into an InSpec
profile, scan prod, and **remediate prod until all controls pass**.

Turning benchmark audit steps into automated checks is what people mean by
**Compliance as Code**. With hundreds of servers you can't check them by hand.

## Method
For each benchmark recommendation:
1. Find the **audit** command/check in the PDF.
2. Express it with an InSpec resource.

## Build

```bash
bash ../71-inspec-basics/install-inspec.sh
mkdir cis-ubuntu && cd cis-ubuntu
inspec init profile ubuntu --chef-license accept
cp ../76-inspec-cis-benchmark/profile/controls/configure_sudo.rb ubuntu/controls/
rm ubuntu/controls/example.rb
inspec check ubuntu        # Controls: 3, Valid: true
inspec exec ubuntu         # local: 1 successful (sudo installed), 2 failures
```

| Control | Resource | Checks |
|---|---|---|
| ubuntu-1.3.1 | `package('sudo')` | `be_installed` |
| ubuntu-1.3.2 | `command(grep ... use_pty)` | stdout includes `Defaults use_pty` |
| ubuntu-1.3.3 | `command(grep ... logfile=)` | stdout includes `Defaults logfile=` |

**Could you check the package with `command`?** Yes
(`command('dpkg -s sudo').exit_status` should eq 0), but `package` is
portable across apt/yum/apk and states the intent clearly. Prefer resources.

## Scan prod

```bash
echo "StrictHostKeyChecking accept-new" >> ~/.ssh/config     # TOFU, not "disable checks"
inspec exec ubuntu -t ssh://root@$PROD_HOST -i ~/.ssh/id_rsa --chef-license accept
# ✔ ubuntu-1.3.1  × ubuntu-1.3.2  × ubuntu-1.3.3
# Profile Summary: 1 successful control, 2 control failures
```

**Why is disabling host key checks a bad idea in production?** It removes
MITM protection. Your compliance scanner would happily report "compliant"
for an attacker's host. `accept-new` trusts only the **first** contact and
then enforces it.

## Challenge: make prod fully compliant
Read the OS resources docs and the difference between the `command` and
`service` resources, then fix prod:

```bash
../76-inspec-cis-benchmark/remediate-prod-sudoers.sh
inspec exec ubuntu -t ssh://root@$PROD_HOST -i ~/.ssh/id_rsa --chef-license accept
# Profile Summary: 3 successful controls, 0 control failures, 0 controls skipped
```

Target `/etc/sudoers` (hint from the course):
```
Defaults        env_reset
Defaults        mail_badpass
Defaults        secure_path="..."
Defaults use_pty
Defaults logfile="/var/log/sudo.log"
```

Watch the whitespace. The control uses `include 'Defaults use_pty'`
(exact substring), so `Defaults<TAB>use_pty` would still **fail**. Either
write it with one space, or improve the control to
`should match /Defaults\s+use_pty/`. Always validate with `visudo -c`.

`command` vs `service`: `command` runs arbitrary shell and asserts on
stdout/stderr/exit_status. `service('x')` abstracts systemd/upstart/sysv
for `be_installed`, `be_enabled`, `be_running`.
