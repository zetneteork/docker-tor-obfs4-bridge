# Security Policy

## Supported versions

Only the **latest release** is actively supported with security fixes.

| Version | Supported |
|---|---|
| Latest (`main` branch) | yes |
| Older releases | no |

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Instead, report privately via one of:

- **GitHub Security Advisories** — use the
  [Report a vulnerability](https://github.com/zetneteork/docker-tor-obfs4-bridge/security/advisories/new)
  button on the Security tab of this repository.
- **E-mail** — `tor@opentree.cz` (PGP not required, but appreciated).

Please include:
- A clear description of the vulnerability.
- Steps to reproduce or a proof-of-concept.
- Potential impact (what can an attacker achieve?).

We aim to acknowledge reports within **48 hours** and release a fix within
**14 days** for critical issues.

## Upstream security

This image bundles Tor and obfs4proxy from Debian's official repositories.
Monitor the following for upstream advisories:

- [Tor security advisories](https://www.torproject.org/security/advisories/)
- [Debian security tracker – tor](https://security-tracker.debian.org/tracker/source-package/tor)
- [Debian security tracker – obfs4proxy](https://security-tracker.debian.org/tracker/source-package/obfs4proxy)

The base image (`debian:stable-slim`) is updated automatically via Dependabot.
