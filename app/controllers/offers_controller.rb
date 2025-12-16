class OffersController < ApplicationController
  before_action :set_request, only: [ :create ]
  before_action :set_offer, only: [ :update ]

  def create
    @offer = @request.offers.build(offer_params.merge(user: current_user))
    authorize @offer

    service = Offers::CreateService.new(@request, current_user, offer_params)

    if service.call
      redirect_to @request, notice: t("offers.flash.created")
    else
      @offer = service.offer

      # Загружаем данные для страницы requests/show
      @offers = @request.offers.includes(:user).order(created_at: :desc)
      @accepted_offer = @offers.find { |o| o.accepted? }
      @reviews = @request.reviews.includes(:reviewer, :reviewee).order(created_at: :asc)

      flash.now[:alert] = t("offers.flash.create_error")
      render "requests/show", status: :unprocessable_entity
    end
  end

  def update
    @request_of_offer = @offer.request
    authorize @offer

    new_status = params[:status]

    unless %w[accepted rejected].include?(new_status)
      redirect_to @request_of_offer, alert: t("offers.flash.invalid_status")
      return
    end

    service = if new_status == "accepted"
      Offers::AcceptService.new(@offer)
    else
      Offers::RejectService.new(@offer)
    end

    if service.call
      message = new_status == "accepted" ? t("offers.flash.accepted") : t("offers.flash.rejected")
      redirect_to @request_of_offer, notice: message
    else
      redirect_to @request_of_offer, alert: service.error_message
    end
  end

  private

  def set_request
    @request = Request.find(params[:request_id])
  end

  def set_offer
    @offer = Offer.find(params[:id])
  end

  def offer_params
    params.require(:offer).permit(:message)
  end
end
