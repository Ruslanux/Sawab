module Requests
  class CancelService < ApplicationService
    attr_reader :request, :user

    def initialize(request, user)
      super()
      @request = request
      @user = user
    end

    def call
      return add_error(I18n.t("requests.errors.cannot_cancel")) unless request.cancellable_by?(user)

      if request.mark_cancelled!
        true
      else
        add_errors(request.errors.full_messages)
        false
      end
    end
  end
end
