class Admin::BaseController < ApplicationController
  include Admin::ResourceLoader
  include Admin::Filtering

  before_action :authenticate_user!
  before_action :authorize_admin!

  layout "admin"

  private

  def authorize_admin!
    unless current_user&.staff?
      flash[:alert] = "You are not authorized to access the admin panel."
      redirect_to root_path
    end
  end

  def require_admin!
    unless current_user&.admin?
      flash[:alert] = "This action requires admin privileges."
      redirect_to admin_root_path
    end
  end
end
