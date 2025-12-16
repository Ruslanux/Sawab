class Admin::ReportsController < Admin::BaseController
  load_resource :report, only: %i[show investigate resolve dismiss]

  def index
    @reports = Report.includes(:reporter, :reported_user, :reportable, :resolver)
                     .order(created_at: :desc)

    @reports = filter_by_status(@reports)
    @reports = @reports.where(report_type: params[:type]) if params[:type].present?
    @reports = paginate(@reports)
  end

  def show
    @reportable = @report.reportable
  end

  def investigate
    @report.update(status: "investigating", resolver: current_user)
    redirect_to admin_report_path(@report), notice: "Report status updated to investigating."
  end

  def resolve
    if @report.resolve!(current_user, params[:resolution_note])
      NotificationService.notify_report_resolved(@report)

      case params[:action_type]
      when "delete_content"
        @report.reportable&.destroy
      when "ban_user"
        @report.reported_user&.update(banned_at: Time.current, banned_reason: params[:resolution_note])
      when "warn_user"
        NotificationService.notify_user_warned(@report)
      end

      redirect_to admin_reports_path, notice: "Report resolved successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def dismiss
    if @report.dismiss!(current_user, params[:resolution_note])
      NotificationService.notify_report_dismissed(@report)
      redirect_to admin_reports_path, notice: "Report dismissed."
    else
      render :show, status: :unprocessable_entity
    end
  end
end
