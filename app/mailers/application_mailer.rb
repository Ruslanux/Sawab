class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_SENDER", "noreply@sawabapp.org")
  layout "mailer"
end
