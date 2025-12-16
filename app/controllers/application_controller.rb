class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :check_if_banned, if: :user_signed_in?
  after_action :set_cable_identifier, if: :user_signed_in?
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_locale

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def check_if_banned
    if current_user.banned?
      reason = current_user.banned_reason.presence || "Без указания причины"
      sign_out current_user
      flash[:alert] = "Ваш аккаунт был заблокирован. Причина: #{reason}"
      redirect_to root_path
    end
  end

  def set_cable_identifier
    cookies.encrypted[:user_id] = current_user.id
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def set_locale
    I18n.locale = params[:locale] || session[:locale] || I18n.default_locale
    session[:locale] = I18n.locale
  end

  def default_url_options
    { locale: I18n.locale }
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :username, :location ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :username, :location ])
  end
end
