module Filterable
  extend ActiveSupport::Concern

  included do
    helper_method :filter_params
  end

  private

  def filter_params
    @filter_params ||= {
      status: params[:status],
      category_id: params[:category_id],
      time_period: params[:time_period] || "all",
      region: params[:region],
      city: params[:city],
      search_query: params[:q],
      sort: params[:sort] || "recent"
    }
  end

  def apply_filters(scope)
    scope = scope.filter_by(filter_params.slice(:status, :category_id, :time_period, :region, :city))
    scope = scope.search(filter_params[:search_query]) if filter_params[:search_query].present?
    apply_sorting(scope, filter_params[:sort])
  end

  def apply_sorting(scope, sort_param)
    case sort_param
    when "oldest"
      scope.oldest
    when "recent", nil
      scope.recent
    else
      scope.recent
    end
  end
end
