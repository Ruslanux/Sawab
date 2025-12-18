# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :google_oauth2

  def google_oauth2
    handle_auth("Google")
  end

  def failure
    redirect_to root_path, alert: t("devise.omniauth_callbacks.failure", reason: failure_message)
  end

  private

  def handle_auth(provider)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      flash[:notice] = t("devise.omniauth_callbacks.success", kind: provider)
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.oauth_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

  def failure_message
    exception = request.env["omniauth.error"]
    error = exception.respond_to?(:message) ? exception.message : exception.to_s
    error.presence || "Unknown error"
  end
end
