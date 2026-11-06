describe file('/etc/shadow') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
end
