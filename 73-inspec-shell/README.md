# Lab 73: Exploring Resources with the InSpec Shell

## Goal
Use `inspec shell`, an interactive REPL, to explore resources and try
assertions against a live target before you put them in a profile.

```bash
bash ../71-inspec-basics/install-inspec.sh
echo "StrictHostKeyChecking accept-new" >> ~/.ssh/config
inspec shell -t ssh://root@$PROD_HOST -i ~/.ssh/id_rsa --chef-license accept
```

Inside the shell:

```ruby
help
help resources                                  # every available resource
file('/tmp').class.superclass.instance_methods(false).sort   # methods on the file resource (it's Ruby)

file('/tmp').directory?                         # predicate methods end in ? -> true/false
file('/tmp').exist?
file('/tmp').content

describe file('/tmp') do                        # run a test interactively
  it { should be_directory }
end

os_env('PATH')
os_env('PATH').content
os_env('PATH').split                             # array of path entries

os.name ; os.release ; os.family                 # facts about the target
package('openssh-server').version
service('ssh').running?
port(22).listening?
command('id').stdout
sshd_config.PermitRootLogin
exit
```

Arrow keys / Page Up / Page Down scroll long output. Press **q** to leave the pager.

Workflow: prototype an assertion in the shell, then paste the same
`describe` block into `controls/*.rb`.

`inspec shell -c "os_env('PATH').split"` runs a single command non-interactively.
