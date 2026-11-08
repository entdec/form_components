module FormComponents
  module TextArea
    class Component < FormComponents::Field::Component
      # Adds a placeholder inside the field
      option_reader :placeholder
      # Adds a corner hint, next to the label, above the field
      option_reader :corner_hint

      def text_area_classes
        class_names("block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline outline-1 -outline-offset-1 placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-1 sm:text-sm/6 auto-dark:bg-white/5 auto-dark:text-white auto-dark:placeholder:text-gray-500",
          {"col-start-1 row-start-1 pr-3" => has_error?},
          {"outline-gray-300 focus:outline-primary-600 auto-dark:outline-white/10" => !has_error?},
          {"text-red-900 outline-red-300 placeholder:text-red-300 focus:outline-red-600 auto-dark:text-red-300 auto-dark:outline-red-500/50" => has_error?})
      end
    end
  end
end
