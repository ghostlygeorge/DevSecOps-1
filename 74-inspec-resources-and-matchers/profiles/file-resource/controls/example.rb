# Same CIS control, implemented with the file resource instead of a shell command:
# no grep, no shell quoting, works identically over ssh/docker/winrm.
control 'ubuntu-1.3.2' do
  title 'Ensure sudo commands use pty'
  desc 'Attackers can run a malicious program using sudo, which would again fork a background process that remains even when the main program has finished executing.'

  describe file('/etc/sudoers') do
    its('content') { should match /Defaults(\s*)use_pty/ }
  end
end
