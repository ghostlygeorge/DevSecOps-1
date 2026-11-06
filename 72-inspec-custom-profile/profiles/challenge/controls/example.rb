# PCI/DSS-inspired checks (password policy, account inactivity, SSH).
# NOTE: /etc/pam.d/system-auth and password-auth are RHEL/CentOS paths. On
# Ubuntu they don't exist, so those describes FAIL — that's the "5 failures"
# in the course output. Ubuntu's equivalent is /etc/pam.d/common-password.
describe file('/etc/pam.d/system-auth') do
  its('content') {
    should match(/^\s*password\s+requisite\s+pam_pwquality\.so\s+(\S+\s+)*try_first_pass/)
  }
  its('content') {
    should match(/^\s*password\s+requisite\s+pam_pwquality\.so\s+(\S+\s+)*retry=[3210]/)
  }
end

describe file('/etc/pam.d/password-auth') do
  its('content') {
    should match(/^\s*password\s+requisite\s+pam_pwquality\.so\s+(\S+\s+)*try_first_pass/)
  }
  its('content') {
    should match(/^\s*password\s+requisite\s+pam_pwquality\.so\s+(\S+\s+)*retry=[3210]/)
  }
end

# accounts locked after <= 30 days of inactivity
describe file('/etc/default/useradd') do
  its('content') {
    should match(/^\s*INACTIVE\s*=\s*(30|[1-2][0-9]|[1-9])\s*(\s+#.*)?$/)
  }
end

describe file('/etc/ssh/sshd_config') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  its('content') { should match 'PasswordAuthentication no' }
end
