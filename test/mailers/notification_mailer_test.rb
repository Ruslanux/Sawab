require "test_helper"

class NotificationMailerTest < ActionMailer::TestCase
  test "new_offer_notification" do
    offer = offers(:one)
    # Используем правильное имя метода: new_offer_notification
    mail = NotificationMailer.new_offer_notification(offer)
    assert_equal "New offer on '#{offer.request.title}'", mail.subject
    assert_equal [ offer.request.user.email ], mail.to
    assert_equal [ "notifications@sawab.com" ], mail.from
  end
end
