class Admin::BadgesController < Admin::BaseController
  load_resource :badge, only: %i[edit update destroy]

  def index
    @badges = paginate(Badge.order(:name))
  end

  def new
    @badge = Badge.new
  end

  def create
    @badge = Badge.new(badge_params)
    if @badge.save
      redirect_to admin_badges_path, notice: "Badge was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @badge.update(badge_params)
      redirect_to admin_badges_path, notice: "Badge was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @badge.user_badges.any?
      redirect_to admin_badges_path, alert: "Cannot delete badge: users already have this badge."
    else
      @badge.destroy
      redirect_to admin_badges_path, notice: "Badge was successfully deleted."
    end
  end

  private

  def badge_params
    params.require(:badge).permit(:name, :description, :icon_name)
  end
end
