class Admin::DashboardController < Admin::BaseController
  def index
    # Cache stats for 5 minutes to reduce database load
    @stats = Rails.cache.fetch("admin_dashboard_stats", expires_in: 5.minutes) do
      {
        total_users: User.count,
        new_users_today: User.where("created_at >= ?", Time.current.beginning_of_day).count,
        active_users: User.active.count,

        total_requests: Request.count,
        open_requests: Request.where(status: "open").count,
        completed_requests: Request.where(status: "completed").count,

        total_offers: Offer.count,
        pending_offers: Offer.where(status: "pending").count,
        accepted_offers: Offer.where(status: "accepted").count,

        pending_reports: Report.pending.count,
        investigating_reports: Report.investigating.count,
        disputed_requests: Request.where(status: "disputed").count,

        total_sawab_distributed: User.sum(:sawab_balance)
      }
    end

    @recent_users = User.order(created_at: :desc).limit(5)
    @recent_requests = Request.includes(:user, :category).order(created_at: :desc).limit(5)
    @pending_reports = Report.pending.includes(:reporter, :reportable).order(created_at: :desc).limit(10)

    # Chart data for last 7 days - optimized with single GROUP BY query instead of N queries
    date_range = 6.days.ago.beginning_of_day..Time.current.end_of_day
    dates = (6.days.ago.to_date..Date.today).to_a

    users_by_date = User.where(created_at: date_range)
                        .group("DATE(created_at)")
                        .count
    requests_by_date = Request.where(created_at: date_range)
                              .group("DATE(created_at)")
                              .count

    @chart_data = {
      labels: dates.map { |d| d.strftime("%b %d") },
      users: dates.map { |d| users_by_date[d] || 0 },
      requests: dates.map { |d| requests_by_date[d] || 0 }
    }
  end
end
