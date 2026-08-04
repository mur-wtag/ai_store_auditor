# Sofenx AI Store Auditor — App Store submission package

Use this document as the source of truth when completing the Shopify App Store listing and review form. Confirm every dashboard field against the current production release before clicking **Submit for review**.

## App identity

- App name: **Sofenx AI Store Auditor**
- Developer: **Sofenx**
- App URL: `https://ssa.sofenx.com`
- Privacy policy: `https://ssa.sofenx.com/privacy`
- Terms of service: `https://ssa.sofenx.com/terms`
- Support URL: `https://ssa.sofenx.com/support`
- Support email: `support@sofenx.com`
- Primary language: English
- Sales-channel requirement: Merchant must have an Online Store

## Listing copy

### App card subtitle

Find and prioritize storefront fixes

### App introduction

Turn store and storefront evidence into a clear improvement plan.

### App details

Sofenx AI Store Auditor reviews the parts of your Shopify store that shape product discovery, trust, accessibility, search visibility, and conversion readiness. It brings the most important issues into one embedded dashboard so you can decide what to fix next.

Run an audit to review your public homepage together with product, collection, and navigation information available through Shopify. Each finding includes the evidence behind it, an explanation of why it matters, and a practical recommendation. Paid plans add AI-assisted copy and implementation guidance while deterministic checks remain the source of every finding and score.

The app is designed for merchants who want a repeatable storefront-review routine without granting access to customers, orders, payments, or checkout data.

### Feature list

- Audit the homepage, products, collections, and store navigation
- See prioritized findings with store-specific evidence
- Review category scores, critical issues, and quick wins
- Get practical fixes and AI-assisted guidance on paid plans
- Schedule recurring audits within the selected plan allowance
- Change paid plans or downgrade to Free inside the app

## Pricing details

Enter prices only in Shopify's designated pricing section; do not put prices in listing images or general listing copy.

- Free: one audit every 30 days; top five prioritized findings
- Starter: USD 9.99 every 30 days; seven-day trial for first-time paid subscribers; four audits per period
- Growth: USD 19.99 every 30 days; seven-day trial for first-time paid subscribers; fifteen audits per period
- Pro: USD 39.99 every 30 days; seven-day trial for first-time paid subscribers; thirty-one audits per period
- Failed audits do not use an allowance
- Paid plan changes require Shopify approval
- Downgrading to Free ends paid access immediately and does not issue a prorated refund

## Reviewer instructions

The app does not require a separate Sofenx account or external login. Install it from the Shopify review surface and complete Shopify OAuth.

1. Install the app on a review store that has an Online Store, published products, at least one collection, and navigation links.
2. Approve the requested `read_products` and `read_online_store_navigation` scopes.
3. Confirm that the embedded dashboard opens immediately after OAuth.
4. Wait for the installation audit to complete, then open the audit and review its score, evidence, findings, and recommendations.
5. Open **Settings**, change the monthly revenue baseline, save, reload, and confirm the value persists.
6. Open **Plans** and select a paid plan. Shopify development/review stores use a test charge. Approve it and confirm the selected plan becomes active.
7. Switch to another paid plan and approve the replacement test charge.
8. Click **Downgrade to Free**, confirm cancellation, and verify that Free becomes active without contacting support or reinstalling.
9. Run another audit if the allowance permits and verify that completed and failed states are communicated in the UI.
10. Uninstall and reinstall the app to confirm OAuth is required again and the app returns to a usable dashboard.

No customer, order, payment, or checkout data is requested or required. The OpenAI key is managed by Sofenx in production; reviewers do not need to configure one.

## Demo screencast shot list

Record one continuous English-language video or add English subtitles. Do not expose tokens, credentials, browser bookmarks, unrelated stores, or private merchant information.

1. Install and approve scopes.
2. Show the embedded dashboard and installation audit.
3. Open a finding and show its evidence and recommendation.
4. Save and reload Settings.
5. Open Plans, approve a Shopify test charge, switch plans, then downgrade to Free.
6. Show Privacy, Terms, and Support URLs.
7. Uninstall and reinstall to demonstrate the OAuth flow.

## Listing media checklist

- Square app icon without Shopify trademarks or pricing
- Feature image focused on the product experience
- Dashboard overview screenshot
- Audit results and prioritized findings screenshot
- Finding evidence and implementation guidance screenshot
- Plans and allowances screenshot without promotional pricing text added to the image
- Settings screenshot
- Every image must be unique, cropped to the app UI, and exclude browser chrome or desktop backgrounds

## Final Partner Dashboard checklist

- App name matches `Sofenx AI Store Auditor`
- All pricing and trial details match this document and production
- Privacy, Terms, and Support URLs return HTTP 200
- Mandatory compliance-webhook automated checks pass
- Emergency developer contact is configured
- Demo screencast URL is accessible without requesting permission
- Reviewer instructions are pasted and current
- No external credentials are requested because the app uses Shopify OAuth only
- Listing claims only describe behavior verified in production
- Full install, audit, billing, downgrade, uninstall, and reinstall rehearsal passes on a development store
