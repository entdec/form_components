module FormComponents
  module FileField
    # Rails' file field, which also makes the form multipart
    class Component < FormComponents::Field::Component
      self.extras = superclass.extras + %i[preview]

      # An attached image to show above the field, as what's there now
      option_reader :preview

      # Not for a file just uploaded with a form that didn't save, as it isn't stored yet
      def preview?
        preview.respond_to?(:attached?) && preview.attached? && preview.blob.persisted? && preview.representable?
      end

      def input
        rails(:file_field, method, input_options(file_field_classes))
      end

      def file_field_classes
        class_names("block w-full text-sm text-gray-500 file:mr-4 file:rounded-md file:border-0 file:bg-primary-50 file:px-3 file:py-2 file:text-sm file:font-semibold file:text-primary-700 hover:file:bg-primary-100 auto-dark:text-gray-400 auto-dark:file:bg-primary-500/10 auto-dark:file:text-primary-400 auto-dark:hover:file:bg-primary-500/20",
          {"text-red-900 auto-dark:text-red-300" => has_error?})
      end
    end
  end
end
