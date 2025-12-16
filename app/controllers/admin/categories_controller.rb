module Admin
  class CategoriesController < BaseController
    load_resource :category, only: %i[show edit update destroy]

    def index
      @categories = paginate(Category.includes(:requests).order(:name))
    end

    def show
      @requests = @category.requests.includes(:user).order(created_at: :desc).limit(10)
      @offers = Offer.joins(:request)
                     .where(requests: { category_id: @category.id })
                     .includes(:user, :request)
                     .order(created_at: :desc)
                     .limit(10)
    end

    def new
      @category = Category.new
    end

    def create
      @category = Category.new(category_params)

      if @category.save
        redirect_to admin_categories_path, notice: "Category was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: "Category was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      requests_count = @category.requests.count
      offers_count = Offer.joins(:request).where(requests: { category_id: @category.id }).count

      if requests_count > 0 || offers_count > 0
        redirect_to admin_categories_path,
                    alert: "Cannot delete category with #{requests_count} requests and #{offers_count} offers. Reassign items first."
      else
        @category.destroy
        redirect_to admin_categories_path, notice: "Category was successfully deleted."
      end
    end

    private

    def category_params
      params.require(:category).permit(:name)
    end
  end
end
