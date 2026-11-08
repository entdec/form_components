module FormComponents
  module Validation
    extend ActiveSupport::Concern

    included do
      delegate :validation_context, to: :form

      def optional?(context: validation_context)
        return false if object.nil?

        !required?(context: context)
      end

      def required?(context: validation_context)
        return false if object.nil?

        validators(context: context).any?(ActiveModel::Validations::PresenceValidator)
      end

      def validators(context: validation_context)
        method_validators.select do |validator|
          if context.nil?
            validator.options[:on].blank?
          else
            Array(validator.options[:on]).include?(context&.to_sym)
          end
        end
      end

      private

      def method_validators
        @method_validators ||= if object.nil?
          []
        else
          object.class.validators_on(method)
        end
      end
    end
  end
end
