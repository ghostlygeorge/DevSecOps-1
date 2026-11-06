# Ubuntu-correct version of the password-quality checks above (bonus).
control 'pci-8.2.3-ubuntu' do
  impact 0.7
  title 'Password quality is enforced via pam_pwquality (Ubuntu)'
  only_if('Debian family only') { os.debian? }
  describe file('/etc/pam.d/common-password') do
    its('content') { should match(/^\s*password\s+requisite\s+pam_pwquality\.so/) }
  end
end
