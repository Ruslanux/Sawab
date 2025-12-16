module Admin
  module Filtering
    extend ActiveSupport::Concern

    DEFAULT_PER_PAGE = 20

    def paginate(scope, per_page: DEFAULT_PER_PAGE)
      scope.page(params[:page]).per(per_page)
    end

    def filter_by_status(scope, status_param = params[:status])
      return scope if status_param.blank?

      scope.where(status: status_param)
    end

    def filter_by_category(scope, category_param = params[:category_id])
      return scope if category_param.blank?

      scope.where(category_id: category_param)
    end

    def filter_by_search(scope, *columns)
      return scope if params[:search].blank?

      search_term = "%#{params[:search]}%"
      conditions = columns.map { |col| "#{col} ILIKE ?" }.join(" OR ")
      scope.where(conditions, *Array.new(columns.size, search_term))
    end

    def filter_by_role(scope)
      return scope if params[:role].blank?

      scope.where(role: params[:role])
    end

    def filter_by_user_status(scope)
      return scope if params[:status].blank?

      case params[:status]
      when "active"
        scope.active
      when "inactive"
        scope.inactive
      else
        scope
      end
    end
  end
end
