module Requests
  class CompleteService < ApplicationService
    attr_reader :request

    def initialize(request)
      super()
      @request = request
    end

    def call
      return false unless validate_request

      ApplicationRecord.transaction do
        locked_request = Request.lock.find(request.id)
        accepted_offer = locked_request.offers.find_by(status: "accepted")

        unless accepted_offer
          add_error(I18n.t("requests.errors.no_accepted_offer"))
          raise ActiveRecord::Rollback
        end

        locked_request.update!(status: "completed")

        helper = accepted_offer.user
        helper.increment!(:sawab_balance)

        BadgeService.award_badges_for(helper, locked_request)
        NotificationService.notify_request_completed(locked_request)
      end

      success?
    end

    private

    def validate_request
      return true if request.in_progress? || request.pending_completion?

      add_error(I18n.t("requests.errors.already_completed_or_cancelled"))
    end
  end
end
