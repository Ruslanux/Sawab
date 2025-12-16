class NotificationMailer < ApplicationMailer
  default from: -> { ENV.fetch("MAILER_SENDER", "notifications@sawab.com") }

  def new_offer_notification(offer)
    @offer = offer
    @request = offer.request
    @recipient = @request.user
    @actor = offer.user
    mail(to: @recipient.email, subject: "New offer on '#{@request.title}'")
  end

  def offer_accepted_notification(offer)
    @offer = offer
    @request = offer.request
    @recipient = offer.user
    mail(to: @recipient.email, subject: "Your offer was accepted!")
  end

  def offer_rejected_notification(offer)
    @offer = offer
    @request = offer.request
    @recipient = offer.user
    mail(to: @recipient.email, subject: "Your offer was rejected")
  end
end
