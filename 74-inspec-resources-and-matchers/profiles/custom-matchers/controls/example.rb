# CIS Ubuntu 18.04 p.384 — "Ensure permissions on /etc/ssh/sshd_config are configured"
control 'ubuntu-5.2.1' do
  title 'Ensure permissions on /etc/ssh/sshd_config are configured'
  desc 'The /etc/ssh/sshd_config file contains configuration specifications for sshd. The command below checks whether the owner and group of the file is root.'

  describe file('/etc/ssh/sshd_config') do
    its('owner') { should eq 'root' }      # eq: exact equality
    its('group') { should eq 'root' }
    its('mode')  { should cmp '0600' }     # cmp: type-aware compare ('0600' string vs integer mode 384)
  end
end
