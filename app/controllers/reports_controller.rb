class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reportable, only: [ :new, :create ]

  def new
    @report = Report.new(reportable: @reportable)
  end

  def create
    @report = Report.new(report_params)
    @report.reporter = current_user
    @report.reportable = @reportable # @reportable был установлен 'set_reportable'

    if @report.save
      # Отправляем уведомление админам (можно через NotificationService)
      redirect_to root_path, notice: "Ваша жалоба отправлена. Администрация рассмотрит ее."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_reportable
    # === ИСПРАВЛЕНИЕ 1 ===
    # Ищем параметры в правильном месте в зависимости от экшена (new или create)

    type = params[:reportable_type] || params.dig(:report, :reportable_type)
    id = params[:reportable_id] || params.dig(:report, :reportable_id)

    # === КОНЕЦ ИСПРАВЛЕНИЯ 1 ===

    if type == "User"
      @reportable = User.find(id)
    elsif type == "Request"
      @reportable = Request.find(id)
    # Ты можешь добавить сюда 'Offer', если захочешь добавить жалобы на офферы
    # elsif type == 'Offer'
    #   @reportable = Offer.find(id)
    else
      redirect_to root_path, alert: "Неверный тип жалобы."
    end
  end

  def report_params
    # === ИСПРАВЛЕНИЕ 2: Добавляем :report_type из enum ===
    params.require(:report).permit(:reason, :details, :report_type)
  end
end
