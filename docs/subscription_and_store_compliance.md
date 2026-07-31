# ShadowScan Mobile Subscription and Store Compliance Requirements

## Product model

ShadowScan Mobile will remain useful without payment. Advanced scanning and continuous monitoring are premium services.

### Free tier

- Initial personal cybersecurity assessment
- Basic Shadow Score
- Cyber Tip of the Day
- Awareness lessons and limited quizzes
- Basic remediation guidance

### ShadowScan Plus

- Verified email exposure monitoring
- Suspicious-link analysis
- Message and phishing analysis
- QR-code destination analysis
- Compromised-password checking using privacy-preserving methods
- Device security checkup
- Wi-Fi risk assessment
- Multiple monitored identities
- Continuous alerts
- Detailed findings, remediation plans, history, and reports

## Seven-day free trial

- Offer a seven-day free trial only to store-eligible users.
- Configure the trial in App Store Connect and Google Play Console rather than implementing a local countdown as the source of truth.
- Validate subscription entitlement through StoreKit on Apple platforms and Google Play Billing on Android.
- The paywall must clearly display:
  - Trial duration: 7 days
  - Subscription name and billing period
  - Full price charged after the trial
  - Automatic renewal disclosure
  - Cancellation instructions
  - Feature availability differences by platform
  - Restore purchases on Apple platforms
  - A visible option to continue using the free tier
- Do not claim that every user is eligible for the trial. Eligibility is determined by the applicable store.
- Trial access must end or convert based on verified store entitlement, not a device-local date.

### Required paywall language template

> Start your 7-day free trial of ShadowScan Plus. Unless canceled at least as required by your app store before the trial ends, your subscription automatically renews at the localized price and billing period shown above. Manage or cancel through your Apple App Store or Google Play subscription settings. Eligibility and feature availability may vary.

The application must render the real localized price and billing period received from the store API. Do not hardcode a price into production paywall copy.

## iOS platform notice

Display this notice during onboarding, on the paywall, and before affected checks when iOS is detected:

> Some ShadowScan features may be limited or unavailable on iPhone because Apple restricts the device, application, and network information available to third-party apps. Each result will identify checks that were completed, manually confirmed, unavailable, permission-restricted, or inconclusive.

Users must not lose Shadow Score points for checks that the operating system prevents ShadowScan from performing.

## Capability statuses

Every scan result must classify each check as one of:

- Checked
- User confirmed
- Unavailable on this device
- Permission denied
- Not included in current plan
- Failed
- Inconclusive

A low-risk result is not a guarantee of safety.

## Store and legal controls

### Privacy and data handling

- Provide a public, non-PDF privacy policy and link it in the app and both store listings.
- Disclose all data collected, transmitted, retained, and shared by ShadowScan and every third-party SDK.
- Collect only data necessary for the requested feature.
- Obtain affirmative consent before collecting personal or sensitive data.
- Encrypt sensitive data in transit and at rest.
- Never sell personal or sensitive user data.
- Provide in-app and web-based account deletion.
- Define retention periods and permanently delete associated data when required.
- Keep provider secrets and API keys off the mobile client.

### Security scanner claims

Do not use claims such as:

- Guaranteed safe
- Complete protection
- Detects every threat or breach
- Prevents identity theft
- Antivirus protection, unless the product actually qualifies

Use accurate language such as:

- Checks supported risk indicators
- Uses available device signals and supported intelligence sources
- Results may contain false positives, false negatives, or incomplete information
- A low-risk result does not guarantee safety

### Authorized use

- Verify email addresses before continuous monitoring.
- Require the user to confirm ownership or authorization for submitted identifiers, devices, and networks.
- Do not probe neighboring devices, capture unrelated traffic, bypass OS protections, inspect other apps' private data, or perform unauthorized network scanning.

### Permissions

- Request permissions only at the moment the related feature is used.
- Explain why each permission is needed before triggering the system prompt.
- Provide a reduced-function path when permission is denied.
- Do not make unrelated features conditional on unnecessary permissions.

### Subscription management

- Include Manage Subscription and Restore Purchases controls where applicable.
- Clearly disclose renewal, cancellation, refund handling, and post-cancellation data behavior.
- Keep the free tier accessible without forcing trial enrollment.
- Use Apple and Google billing systems for digital premium features distributed through their stores, subject to applicable store rules.

## Release gate

A release cannot be submitted until all of the following are complete:

- Store billing products and seven-day introductory offers configured
- Entitlement verification implemented and tested
- Localized paywall terms verified
- Privacy Policy and Terms of Service published
- Apple privacy details completed
- Google Play Data safety form completed
- Account deletion available in-app and on the web
- Permission prompts and denial paths tested
- iOS limitation notice verified
- Subscription cancellation and restore flows tested
- Third-party SDK and provider data practices audited
- Legal review completed by qualified counsel
