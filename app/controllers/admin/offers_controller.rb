module Admin
  class OffersController < BaseController
    load_resource :offer, only: %i[show edit update destroy accept reject]

    def index
      @offers = Offer.includes(:user, request: :category)
                     .order(created_at: :desc)

      @offers = filter_by_search(@offers, :message)
      @offers = filter_by_status(@offers)

      if params[:category_id].present?
        @offers = @offers.joins(:request).where(requests: { category_id: params[:category_id] })
      end

      @offers = paginate(@offers)
    end

    def show
      @related_offers = Offer.where(user_id: @offer.user_id)
                             .where.not(id: @offer.id)
                             .order(created_at: :desc)
                             .limit(5)
    end

    def edit
    end

    def update
      if @offer.update(offer_params)
        redirect_to admin_offer_path(@offer), notice: "Offer was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @offer.destroy
      redirect_to admin_offers_path, notice: "Offer was successfully deleted."
    end

    def accept
      if @offer.update(status: "accepted")
        NotificationService.notify_offer_accepted(@offer)
        redirect_to admin_offers_path, notice: "Offer was accepted."
      else
        redirect_to admin_offers_path, alert: "Failed to accept offer."
      end
    end

    def reject
      if @offer.update(status: "rejected")
        NotificationService.notify_offer_rejected(@offer)
        redirect_to admin_offers_path, notice: "Offer was rejected."
      else
        redirect_to admin_offers_path, alert: "Failed to reject offer."
      end
    end

    private

    def offer_params
      params.require(:offer).permit(:message, :status)
    end
  end
end
