class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "Sofenx AI Store Auditor <no-reply@example.com>")
  layout "mailer"
end
