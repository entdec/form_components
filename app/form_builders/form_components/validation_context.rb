# frozen_string_literal: true

module FormComponents
  module ValidationContext
    extend ActiveSupport::Concern

    included do
      attr_reader :validation_context
      alias_method :original_initialize, :initialize

      def initialize(*args, &block)
        original_initialize(*args, &block)
        @validation_context = options[:validation_context]
      end
    end
  end
end
