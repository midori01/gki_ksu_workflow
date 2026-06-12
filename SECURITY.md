# Security Policy

## Supported Versions

Security updates are provided for the following kernel versions currently built by this workflow:

| Kernel Version | Supported          |
| :------------- | :----------------: |
| 6.12.x         | :white_check_mark: |
| 6.6.x          | :white_check_mark: |
| 6.1.x          | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in the kernel images distributed through this repository, please **do not** open a public issue.

Instead, report it privately via one of the following channels:

- **GitHub Security Advisory**: Use the [Private Vulnerability Reporting](https://github.com/midori01/gki_ksu_workflow/security/advisories/new) feature.
- **Telegram**: Contact [@midori](https://t.me/midori) directly.

Please include the following details in your report:

- Affected kernel version(s) and variant(s)
- Clear description of the vulnerability
- Steps to reproduce (if applicable)
- Any proposed fix or mitigation (optional)

## Disclosure Policy

- The report will be acknowledged within **48 hours**.
- A fix will be prepared and released as soon as reasonably possible, typically within **7 days**.
- A public advisory will be published once the fix is available.
- Credit will be given to the reporter unless anonymity is requested.

## Scope

This security policy covers:

- Precompiled kernel images and modules distributed via this repository's releases.
- The CI/CD build pipeline configuration within this repository.

This policy does **not** cover:

- Upstream Linux kernel vulnerabilities.
- Upstream Android GKI kernel vulnerabilities.
- Upstream KernelSU vulnerabilities.
- Third-party modules bundled alongside the kernel (refer to their respective projects).

---

*Last updated: 2026-06-12*
