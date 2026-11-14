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

      # Whether the input must be filled in as the object is now: a presence
      # validator whose if: and unless: hold for it, as the browser's
      # required attribute, which can't follow them later
      def required_now?(context: validation_context)
        return false if object.nil?

        validators(context: context).any? { |validator| validator.is_a?(ActiveModel::Validations::PresenceValidator) && applies?(validator) }
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

      def applies?(validator)
        Array(validator.options[:if]).all? { |condition| holds?(condition) } &&
          Array(validator.options[:unless]).none? { |condition| holds?(condition) }
      end

      # As Rails calls a validator's if: and unless:
      def holds?(condition)
        case condition
        when Symbol, String then object.send(condition)
        when Proc then condition.arity.zero? ? object.instance_exec(&condition) : object.instance_exec(object, &condition)
        else true
        end
      end

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
