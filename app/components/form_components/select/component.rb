module FormComponents
  module Select
    # Rails' select, or another of its kind (helper: :collection_select, …),
    # given the arguments Rails takes between method and options. Its arrow
    # is @tailwindcss/forms'.
    #
    # With depends_on: (a field of the same form, or several), its options
    # depend on those fields' values: grouped choices whose groups say which
    # values they're for, in an attribute named after the field, and only the
    # groups that match are shown (by the controller):
    #
    #   <%= f.select :function, [["Players", [["Keeper", "keeper"]], {data: {role: "player"}}]], {}, depends_on: :role %>
    #
    # A group without the attribute of one of the fields is for any value of
    # it.
    class Component < FormComponents::Field::Component
      self.extras = superclass.extras + %i[depends_on]
      attr_reader :helper, :arguments, :select_html_options, :block

      # Our options can be in either hash
      def initialize(form, object, method, arguments, options = {}, html_options = {}, helper: :select, &block)
        html_options = (html_options || {}).symbolize_keys
        super(form, object, method, (options || {}).merge(html_options.slice(*extras)))
        @arguments = arguments
        @select_html_options = html_options.except(*extras)
        @helper = helper
        @block = block
      end

      def input
        rails(helper, method, *arguments, html_options, input_options(select_classes, from: select_html_options), &block)
      end

      # Each field it depends on: its name in the form, and the attribute of
      # the groups for its values
      def depends_on_fields
        Array(options[:depends_on]).map do |field|
          {name: form.field_name(field, index: id_options.fetch(:index, form.options[:index])), attribute: "data-#{field.to_s.dasherize}"}
        end
      end

      # Rails takes a select's id from its html_options
      def id_options
        select_html_options
      end

      def select_classes
        class_names("block w-full bg-white py-1.5 pl-3 pr-10 text-base text-gray-900 outline outline-1 -outline-offset-1 focus:outline focus:outline-2 focus:-outline-offset-1 sm:text-sm/6 auto-dark:bg-white/5 auto-dark:text-white",
          corner_classes, LOCKED_CLASSES.gsub("read-only:", "disabled:"),
          {"focus:relative" => grouped?, "relative" => grouped? && has_error?},
          {"outline-gray-300 focus:outline-primary-600 auto-dark:outline-white/10" => !has_error?},
          {"text-red-900 outline-red-300 focus:outline-red-600 auto-dark:text-red-300 auto-dark:outline-red-500/50" => has_error?})
      end
    end
  end
end
