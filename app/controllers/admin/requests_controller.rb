class Admin::RequestsController < Admin::BaseController
  load_resource :request, only: %i[show destroy complete cancel]

  def index
    @requests = Request.includes(:user, :category, :offers)
                       .order(created_at: :desc)

    @requests = filter_by_status(@requests)
    @requests = filter_by_category(@requests)
    @requests = filter_by_search(@requests, :title, :description)
    @requests = paginate(@requests)
  end

  def show
    @offers = @request.offers.includes(:user).order(created_at: :desc)
    @conversation = @request.conversation
    @messages = @conversation ? @conversation.messages.includes(:user).order(:created_at) : []
  end

  def destroy
    @request.destroy
    redirect_to admin_requests_path, notice: "Request was successfully deleted."
  end

  def complete
    authorize @request

    ApplicationRecord.transaction do
      locked_request = Request.lock.find(@request.id)

      unless locked_request.pending_completion? || locked_request.disputed?
        redirect_to admin_request_path(locked_request), alert: "This request is not awaiting resolution."
        return
      end

      accepted_offer = locked_request.offers.find_by(status: "accepted")
      unless accepted_offer
        redirect_to admin_request_path(locked_request), alert: "No accepted offer found."
        return
      end

      locked_request.update!(status: "completed")

      helper = accepted_offer.user
      helper.increment!(:sawab_balance)

      BadgeService.award_badges_for(helper, locked_request)
      NotificationService.notify_request_completed(locked_request)
    end

    redirect_to admin_request_path(@request), notice: t("requests.flash.dispute_completed")
  end

  def cancel
    authorize @request

    if @request.update(status: "cancelled")
      redirect_to admin_request_path(@request), notice: t("requests.flash.dispute_cancelled")
    else
      redirect_to admin_request_path(@request), alert: t("requests.flash.cancel_failed")
    end
  end
end
