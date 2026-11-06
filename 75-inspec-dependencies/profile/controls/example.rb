# copyright: 2018, The Authors

title "sample section"

# you can also use plain tests
describe file("/tmp") do
  it { should be_directory }
end

# you add controls here
control "tmp-1.0" do                # A unique ID for this control
  impact 0.7                        # The criticality, if this control fails.
  title "Create /tmp directory"     # A human-readable title
  desc "An optional description..."
  describe file("/tmp") do          # The actual test
    it { should be_directory }
  end
end

# pull in every control from the dependencies (names must match inspec.yml depends: names)
include_controls 'SSH baseline'

include_controls 'Linux Baseline' do
  # inherit, but tailor:
  skip_control 'os-10'              # e.g. not applicable in containers
  control 'os-05' do
    impact 1.0                      # raise criticality for our org
  end
end
