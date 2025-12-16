class LeaderboardsController < ApplicationController
  def index
    @period = params.fetch(:period, "all_time")

    case @period
    when "week"
      @range = 1.week.ago..Time.current
      @title = t("leaderboard.title_week")
    when "month"
      @range = 1.month.ago..Time.current
      @title = t("leaderboard.title_month")
    else
      @range = nil
      @title = t("leaderboard.title_all_time")
    end

    @top_helpers = fetch_top_helpers(@range)
  end

  private

  def fetch_top_helpers(range)
    if range.nil?
      # Для "Все время" мы просто используем sawab_balance
      User.where("sawab_balance > 0")
          .order(sawab_balance: :desc)
          .limit(10)
    else
      # Для "Неделя/Месяц" мы считаем завершенные запросы в этот период
      # (Так как 1 завершенный запрос = 1 Sawab)
      User.joins(offers: :request)
          .where(requests: { status: "completed", updated_at: range })
          .where(offers: { status: "accepted" })
          .group("users.id")
          .select("users.*, COUNT(offers.id) as sawab_earned")
          .order("sawab_earned DESC, users.sawab_balance DESC")
          .limit(10)
    end
  end
end
