class ReviewsController < ApplicationController
  before_action :set_request

  def new
    @review = @request.reviews.new
    # Определяем, кого мы оцениваем
    @reviewee = determine_reviewee
    authorize @review # (Нужно будет создать ReviewPolicy)
  end

  def create
    @reviewee = determine_reviewee
    @review = @request.reviews.new(review_params)
    @review.reviewer = current_user
    @review.reviewee = @reviewee
    authorize @review

    if @review.save
      redirect_to @request, notice: "Спасибо за ваш отзыв!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_request
    @request = Request.find(params[:request_id])
  end

  def determine_reviewee
    # Если я автор запроса, я оцениваю хелпера.
    # Если я хелпер, я оцениваю автора запроса.
    if @request.user == current_user
      @request.accepted_offer&.user
    else
      @request.user
    end
  end

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end
