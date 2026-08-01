# Sofenx AI Store Auditor

An embedded Shopify app that turns store and storefront evidence into a prioritized merchant action plan.

## Implemented MVP

The first slice follows the product brief’s recommended launch workflow:

1. OAuth installation stores a per-shop offline session.
2. A background job scans up to 100 recently updated products, 50 collections, online-store navigation, store profile data, and the public homepage.
3. Deterministic rules generate evidence-backed findings across homepage, product pages, collections, SEO, trust, navigation, and accessibility.
4. The dashboard shows a 0–100 store score, category scores, critical issues, quick wins, and a capped monthly opportunity scenario.
5. Optional OpenAI Responses API enrichment adds exact copy and implementation steps to the top ten findings. The audit still works without OpenAI.
6. Weekly audits are scheduled through Solid Queue in production.

No customers, orders, payments, or checkout data are requested by the MVP scopes.

## Stack

- Ruby 4.0.3 and Rails 8.1
- PostgreSQL
- Hotwire, Stimulus, import maps, and server-rendered embedded UI
- `shopify_app` with Shopify Admin GraphQL API `2026-07`
- Solid Queue, Solid Cache, and Solid Cable
- OpenAI Responses API with strict JSON Schema outputs
- Minitest, RuboCop, Brakeman, Docker, and Kamal

This mirrors the proven shape of `shopify_cod_guard` while keeping its COD, OTP, messaging, checkout-extension, and credentials out of this repository.

## Local setup

Requirements: Ruby 4.0.3, PostgreSQL, Node.js/npm, and a Shopify Partner development app.

```bash
cp .env.example .env
bundle install
npm install
bin/rails db:prepare
bin/rails test
bin/dev
```

The checked-in `shopify.app.toml` is the production app configuration. For local Shopify development, link a separate config filename instead of allowing the CLI to replace production URLs. Never copy credentials from another app.

`SHOPIFY_MANAGED_WEBHOOKS=false` is useful when webhook subscriptions are managed declaratively in `shopify.app.toml`. Set only one lifecycle owner in production to avoid duplicate subscriptions.

## OpenAI boundary

`OPENAI_API_KEY` is optional. When configured, the app sends only the top finding titles, resource titles, deterministic explanations, recommendations, and evidence. It uses `store: false` and strict structured output. The default model is `gpt-5.6-terra`, chosen for a balanced background-workload cost/quality role; override it with `OPENAI_MODEL` after representative evaluations.

The AI layer cannot create a finding, alter scores, or change evidence. It only adds merchant-facing explanation, suggested copy, implementation steps, and a caution.

## Verification

```bash
bin/rails db:prepare
bin/rails test
bin/rubocop
bin/rails zeitwerk:check
bin/brakeman --no-pager
npm run shopify:build
```

The Shopify CLI build requires a linked `shopify.app.toml`; it is separate from Rails verification.

## Production deployment

Production runs at `https://ssa.sofenx.com` on the same VPS as Profit Dashboard, but uses separate Kamal web/job containers, a separate PostgreSQL accessory, and a separate storage volume.

The `main` branch deploys only after CI passes. Configure these GitHub Actions repository secrets:

- `DEPLOY_SSH_PRIVATE_KEY`: private key authorized for `root@169.58.64.224`
- `RAILS_MASTER_KEY`: contents of this repository's ignored `config/master.key`
- `SHOPIFY_API_KEY`: client ID of the Sofenx AI Store Auditor Partner app
- `SHOPIFY_API_SECRET`: client secret of that same Partner app
- `AI_STORE_AUDITOR_DATABASE_PASSWORD`: unique strong password for this app's PostgreSQL role
- `OPENAI_API_KEY`: optional project-specific key; omit it to use deterministic audits only

Do not reuse Profit Dashboard's Shopify, database, Rails, or OpenAI credentials. The workflow maps the app database password to PostgreSQL's initial password, so a separate `POSTGRES_PASSWORD` GitHub secret is not required.

## Explicitly deferred

- Lighthouse/PageSpeed performance scoring
- Theme-file/Liquid analysis (`read_themes` is not requested yet)
- Checkout analysis
- Competitor comparison
- Predicted heatmaps
- Theme app extension fixes
- Automatic write-back of generated copy
- Shopify subscription billing and plan limits
- Weekly email delivery
- Analytics proving which recommendations led to measured outcomes

These are not included in the current score or presented as complete. Billing, legal text, provider agreements, production infrastructure, monitoring, backup retention, and Shopify App Store QA remain launch gates.
