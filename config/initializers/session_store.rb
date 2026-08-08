# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

Rails.application.config.session_store(
  :cookie_store,
  key: "_ai_store_auditor_session",
  expire_after: 14.days,
  secure: Rails.env.production?,
  same_site: Rails.env.production? ? :none : :lax
)
