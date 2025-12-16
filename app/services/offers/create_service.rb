module Offers
  class CreateService < ApplicationService
    attr_reader :request, :user, :offer_params, :offer

    def initialize(request, user, offer_params)
      super()
      @request = request
      @user = user
      @offer_params = offer_params
    end

    def call
      @offer = request.offers.build(offer_params)
      @offer.user = user

      if @offer.save
        NotificationService.notify_new_offer(@offer)
        true
      else
        add_errors(@offer.errors.full_messages)
        false
      end
    end
  end
end
