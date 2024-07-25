module CaseConversion
  extend ActiveSupport::Concern

  class_methods do
    def camelcase_to_snakecase(data)
      data.transform_keys { |key| key.to_s.underscore.to_sym }
    end

    def snakecase_to_camelcase(data)
      data.transform_keys { |key| key.to_s.camelize(:lower) }
    end
  end
end
