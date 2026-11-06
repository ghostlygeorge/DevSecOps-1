# CIS Ubuntu 18.04 Benchmark, section 1.3 "Configure sudo" (p.370 in the course's PDF)
control 'ubuntu-1.3.1' do
  title 'Ensure sudo is installed'
  desc 'sudo allows a permitted user to execute a command as the superuser or another user, as specified by the security policy.'
  describe package('sudo') do
    it { should be_installed }
  end
end

control 'ubuntu-1.3.2' do
  title 'Ensure sudo commands use pty'
  desc 'Attackers can run a malicious program using sudo, which would again fork a background process that remains even when the main program has finished executing.'
  describe command('grep -Ei "^\s*Defaults\s+([^#]+,\s*)?use_pty(,\s+\S+\s*)*(\s+#.*)?$" /etc/sudoers').stdout do
    # NB: include is a literal substring match — "Defaults<TAB>use_pty" would FAIL this.
    # A sturdier assertion: it { should match /Defaults\s+use_pty/ }
    it { should include 'Defaults use_pty' }
  end
end

control 'ubuntu-1.3.3' do
  title 'Ensure sudo log file exists'
  desc 'A sudo log file simplifies auditing of sudo commands.'
  describe command('grep -Ei "^\s*Defaults\s+logfile=\S+" /etc/sudoers').stdout do
    it { should include 'Defaults logfile=' }
  end
end
