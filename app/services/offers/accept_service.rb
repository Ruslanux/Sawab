module Offers
  class AcceptService < ApplicationService
    attr_reader :offer

    def initialize(offer)
      super()
      @offer = offer
    end

    def call
      # Quick pre-check before acquiring lock (better UX for obvious failures)
      return false unless validate_offer

      with_transaction do
        # Pessimistic lock prevents race condition: two concurrent accepts
        # could both pass the pre-check above, so we re-validate inside
        # the transaction after acquiring the lock.
        @locked_request = Request.lock.find(offer.request.id)

        unless @locked_request.open?
          add_error(I18n.t("offers.errors.request_not_open"))
          raise ActiveRecord::Rollback
        end

        reject_other_pending_offers
        accept_current_offer
        update_request_status
      end

      return false unless success?

      send_notifications
      true
    end

    private

    def validate_offer
      return true if offer.request.open?

      add_error(I18n.t("offers.errors.request_not_open"))
    end

    def reject_other_pending_offers
      @rejected_offers = @locked_request.offers
                                        .includes(:user, :request)
                                        .where(status: "pending")
                                        .where.not(id: offer.id)
                                        .to_a

      return if @rejected_offers.empty?

      @locked_request.offers
                     .where(status: "pending")
                     .where.not(id: offer.id)
                     .update_all(status: "rejected", updated_at: Time.current)
    end

    def accept_current_offer
      offer.update!(status: "accepted")
    end

    def update_request_status
      @locked_request.update!(status: "in_progress")
    end

    def send_notifications
      @rejected_offers&.each do |rejected_offer|
        NotificationService.notify_offer_rejected(rejected_offer)
      end

      NotificationService.notify_offer_accepted(offer)
    end
  end
end
