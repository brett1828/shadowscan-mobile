# ShadowScan Mobile

ShadowScan Mobile is a personal cybersecurity awareness and digital-risk posture app by **Quantum Shadow BlackOps**.

## MVP direction

The first release is being designed around four core outcomes:

- Show a transparent personal **Shadow Score**
- Surface prioritized security actions and exposure findings
- Evaluate permitted Wi-Fi safety signals without claiming guaranteed safety
- Build individual awareness through a **Cyber Tip of the Day**, lessons, and micro-quizzes

## Current prototype

The current Flutter prototype includes:

- Dark ShadowScan visual theme
- Dashboard navigation shell
- Shadow Score card
- Priority-action cards
- Cyber Tip of the Day card
- Exposure, Wi-Fi, and Learn placeholders

The displayed findings and score are mock data for interface development only.

## Run locally

Install Flutter, then run:

```bash
flutter pub get
flutter run
```

This repository currently contains the shared Dart application layer. Native platform folders can be generated locally with:

```bash
flutter create --org com.quantumshadowblackops --project-name shadowscan_mobile .
```

Review generated platform files before committing them.

## Planned build stages

1. Complete dashboard and design system
2. Add onboarding and personal security assessment
3. Add local findings and remediation workflow
4. Integrate verified identity and breach-monitoring backend
5. Add platform-appropriate Wi-Fi checks
6. Add managed awareness content, quizzes, and notifications
7. Add privacy controls, deletion workflows, and production hardening

## Security principles

- Never collect or store plaintext passwords
- Keep provider API secrets on the backend
- Minimize personal-data collection
- Encrypt sensitive data in transit and at rest
- Explain scores and findings clearly
- Avoid exaggerated protection or network-safety claims
