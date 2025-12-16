module Admin
  module ResourceLoader
    extend ActiveSupport::Concern

    class_methods do
      def load_resource(name, options = {})
        model_class = options[:class_name]&.constantize || name.to_s.classify.constantize
        instance_var = "@#{name}"
        only_actions = options[:only] || %i[show edit update destroy]

        define_method("set_#{name}") do
          instance_variable_set(instance_var, model_class.find(params[:id]))
        end

        before_action :"set_#{name}", only: only_actions
        private :"set_#{name}"
      end
    end
  end
end
