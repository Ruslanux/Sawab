class RequestsController < ApplicationController
  include Filterable

  skip_before_action :authenticate_user!, only: [ :index, :show ]
  before_action :set_request, only: [ :show, :edit, :update, :destroy, :complete ]
  before_action :load_categories, only: [ :new, :create, :edit, :update, :index ]

  # ============================================
  # INDEX - Главная страница с фильтрами
  # ============================================
  def index
    # Определяем тип просмотра (requests или offers)
    @type = params[:type].presence || "requests"

    # Устанавливаем переменные для фильтров
    @status = params[:status]
    @time_period = params[:time_period]
    @category_id = params[:category_id]
    @region = params[:region]
    @city = params[:city]

    if @type == "requests"
      # Фильтруем запросы
      @items = apply_request_filters
      @stats = calculate_request_stats
    else
      # Фильтруем отклики (только для авторизованных пользователей)
      if user_signed_in?
        @items = apply_offer_filters
        @stats = calculate_offer_stats
      else
        redirect_to requests_path(type: "requests"), alert: "Вы должны войти, чтобы просматривать отклики"
        return
      end
    end

    # Пагинация
    @items = @items.page(params[:page]).per(20)

    respond_to do |format|
      format.html
      format.json { render json: { items: @items, stats: @stats, pagination: pagination_meta(@items) } }
    end
  end

  # ============================================
  # SHOW - Детальная страница запроса
  # ============================================
  def show
    authorize @request

    # Создаем @offer для формы
    if user_signed_in?
      temp_offer = Offer.new(request: @request, user: current_user)
      @offer = policy(temp_offer).create? ? Offer.new : nil
    else
      @offer = nil
    end

    # Загружаем offers с eager loading
    @offers = @request.offers.includes(:user).order(created_at: :desc)

    # Кешируем accepted offer для использования в view
    @accepted_offer = @offers.find { |o| o.accepted? }

    @reviews = @request.reviews.includes(:reviewer, :reviewee).order(created_at: :asc)
  end

  # ============================================
  # NEW - Форма создания запроса
  # ============================================
  def new
    @request = Request.new

    # Если создаем запрос от имени учреждения
    if params[:institution_id].present?
      @institution = Institution.find(params[:institution_id])
      unless current_user.can_create_institution_request?(@institution)
        redirect_to @institution, alert: t("institutions.cannot_create_request")
        return
      end
      @request.institution = @institution
      @request.region = @institution.region
      @request.city = @institution.city
    end

    authorize @request
  end

  # ============================================
  # CREATE - Создание нового запроса
  # ============================================
  def create
    @request = current_user.requests.build(request_params)
    authorize @request

    if @request.save
      redirect_to @request, notice: "Request was successfully created."
    else
      load_categories
      render :new, status: :unprocessable_entity
    end
  end

  # ============================================
  # EDIT - Форма редактирования запроса
  # ============================================
  def edit
    authorize @request
  end

  # ============================================
  # UPDATE - Обновление запроса
  # ============================================
  def update
    authorize @request
    if @request.update(request_params)
      redirect_to @request, notice: "Request was successfully updated."
    else
      load_categories
      render :edit, status: :unprocessable_entity
    end
  end

  # ============================================
  # DESTROY - Удаление запроса
  # ============================================
  def destroy
    authorize @request
    @request.destroy
    redirect_to requests_url, notice: "Request was successfully destroyed.", status: :see_other
  end

  # ============================================
  # COMPLETE - Завершение запроса
  # ============================================
  def complete
    authorize @request

    service = Requests::CompleteService.new(@request)

    if service.call
      redirect_to @request, notice: t("requests.flash.completed")
    else
      redirect_to @request, alert: service.error_message
    end
  end

  # ============================================
  # НОВЫЙ МЕТОД: ОЖИДАНИЕ ЗАВЕРШЕНИЯ (ХЕЛПЕРОМ)
  # ============================================
  def mark_pending_completion
    @request = Request.find(params[:id])
    authorize @request

    service = Requests::MarkPendingService.new(@request)

    if service.call
      redirect_to @request, notice: t("requests.flash.pending")
    else
      redirect_to @request, alert: service.error_message
    end
  end

  # ============================================
  # CANCEL - Отмена запроса
  # ============================================
  def cancel
    @request = Request.find(params[:id])
    authorize @request

    service = Requests::CancelService.new(@request, current_user)

    if service.call
      redirect_to @request, notice: "Request has been cancelled."
    else
      redirect_to @request, alert: service.error_message || "Could not cancel request."
    end
  end

  # ============================================
  # STATS - API для получения статистики
  # ============================================
  def stats
    authorize Request, :index?

    @request_stats = {
      total: Request.count,
      open: Request.open_requests.count,
      in_progress: Request.in_progress.count,
      completed: Request.completed.count,
      cancelled: Request.cancelled.count,
      by_category: Request.category_counts,
      by_region: Request.region_counts
    }

    @offer_stats = {
      total: Offer.count,
      pending: Offer.pending.count,
      accepted: Offer.accepted.count,
      rejected: Offer.rejected.count
    }

    render json: { requests: @request_stats, offers: @offer_stats }
  end

  private

  # ============================================
  # BEFORE ACTION МЕТОДЫ
  # ============================================
  def set_request
    @request = Request.find(params[:id])
  end

  def load_categories
    @categories = Category.cached_all
  end

  def request_params
    params.require(:request).permit(
      :title, :description, :category_id, :region, :city,
      :institution_id, :help_type, :beneficiary_name, :beneficiary_age, :author_name
    )
  end

  # ============================================
  # МЕТОДЫ ФИЛЬТРАЦИИ ДЛЯ ЗАПРОСОВ
  # ============================================
  def apply_request_filters
    requests = policy_scope(Request).includes(:offers, :category, :user)
    apply_filters(requests)
  end

  # ============================================
  # МЕТОДЫ ФИЛЬТРАЦИИ ДЛЯ ОТКЛИКОВ
  # ============================================
  def apply_offer_filters
    offers = current_user.offers.includes(:request, :user)
    apply_filters(offers)
  end

  # ============================================
  # РАСЧЕТ СТАТИСТИКИ ДЛЯ ЗАПРОСОВ
  # ============================================
  def calculate_request_stats
    base_scope = apply_filters(Request.all).reorder(nil)

    {
      total: base_scope.count,
      status_breakdown: base_scope.status_counts,
      category_breakdown: base_scope.category_counts,
      region_breakdown: base_scope.region_counts
    }
  end

  # ============================================
  # РАСЧЕТ СТАТИСТИКИ ДЛЯ ОТКЛИКОВ
  # ============================================
  def calculate_offer_stats
    base_scope = apply_filters(current_user.offers).reorder(nil)

    {
      total: base_scope.count,
      status_breakdown: base_scope.status_counts
    }
  end

  # ============================================
  # МЕТАДАННЫЕ ПАГИНАЦИИ
  # ============================================
  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      next_page: collection.next_page,
      prev_page: collection.prev_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count
    }
  end
end
