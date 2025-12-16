module Offers
  class RejectService < ApplicationService
    attr_reader :offer

    def initialize(offer)
      super()
      @offer = offer
    end

    def call
      with_transaction do
        offer.update!(status: "rejected")
      end

      return false unless success?

      NotificationService.notify_offer_rejected(offer)
      true
    end
  end
end
