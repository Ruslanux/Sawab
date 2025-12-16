# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer/new_offer
  def new_offer
    NotificationMailer.new_offer
  end

  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer/offer_accepted
  def offer_accepted
    NotificationMailer.offer_accepted
  end

  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer/request_completed
  def request_completed
    NotificationMailer.request_completed
  end
end
