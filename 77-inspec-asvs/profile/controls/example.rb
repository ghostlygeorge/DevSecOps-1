# OWASP ASVS 4.0 — V14.4 HTTP Security Headers, as InSpec http() checks.
# URL comes from the profile input (override: --input target_url=https://...)
url = input('target_url')

control 'ASVS-14.4.1' do
  impact 0.7
  title 'Safe character set'
  desc 'HTTP response contains content type header with safe character set'
  describe http(url) do
    its('headers.Content-type') { should cmp 'text/html; charset=utf-8' }
  end
end

control 'ASVS-14.4.2' do
  impact 0.7
  title 'Contain Content Disposition header attachment'
  desc "Add Content-Disposition header to the server's configuration, Add 'attachment' directive to the header."
  # NB: ASVS 14.4.2 applies to API responses/downloads — on an HTML page this
  # is expected to fail; scope it to API endpoints in a real profile.
  describe http(url) do
    its('headers.content-disposition') { should cmp 'attachment' }
  end
end

control 'ASVS-14.4.3' do
  impact 0.7
  title 'Content Security Policy Options != none / contain unsafe-inline;unsafe-eval;\*'
  desc "Ensure that CSP is not configured with the directives: 'unsafe-inline', 'unsafe-eval' and wildcards."
  describe http(url) do
    its('headers.content-security-policy') { should_not cmp 'none' }
    its('headers.content-security-policy') { should_not include 'unsafe-inline;unsafe-eval;\*' }
  end
end

control 'ASVS-14.4.4' do
  impact 0.7
  title 'Content type Options = no sniff'
  desc 'All responses should contain X-Content-Type-Options=nosniff'
  describe http(url) do
    its('headers.x-content-type-options') { should cmp 'nosniff' }
  end
end

control 'ASVS-14.4.5' do
  impact 0.7
  title 'HSTS is using directives max-age=15724800'
  desc 'Verify that HTTP Strict Transport Security headers are included on all responses and for all subdomains, such as Strict-Transport-Security: max-age=15724800; includeSubDomains.'
  describe http(url) do
    its('headers.Strict-Transport-Security') { should match /\d/ }
  end
end

control 'ASVS-14.4.6' do
  impact 0.7
  title "'Referrer-Policy' header is included"
  desc "HTTP requests may include Referrer header, which may expose sensitive information. Referrer-Policy restricts how much information is sent in the Referer header."
  describe http(url) do
    its('headers.referrer-policy') { should cmp 'no-referrer; same-origin' }
  end
end
