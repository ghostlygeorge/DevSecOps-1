// Renovate self-hosted config for the lab GitLab.
// Replace LABID (or run `labify renovate-config.js`) and paste your PAT.
// NEVER commit a real token — in CI use the RENOVATE_TOKEN env var instead.
module.exports = {
  endpoint: 'https://gitlab-ce-LABID.lab.practical-devsecops.training/api/v4/',
  token: '<your_gitlab_token>',
  platform: 'gitlab',
  onboardingConfig: {
    extends: ['config:recommended'],
  },
  repositories: ['root/django-nv'],
};
