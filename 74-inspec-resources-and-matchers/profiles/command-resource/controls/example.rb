# CIS Ubuntu 18.04 benchmark p.83 — "Ensure sudo commands use pty"
control 'ubuntu-1.3.2' do
  title 'Ensure sudo commands use pty'
  desc 'Attackers can run a malicious program using sudo, which would again fork a background process that remains even when the main program has finished executing.'

  # run the exact audit command from the benchmark, assert on its stdout
  describe command('grep -Ei "^\s*Defaults\s+([^#]+,\s*)?use_pty(,\s+\S+\s*)*(\s+#.*)?$" /etc/sudoers /etc/sudoers.d/*') do
    # regex: tolerate any whitespace (space or tab) between Defaults and use_pty
    its('stdout') { should match /Defaults(\s*)use_pty/ }
  end
end
