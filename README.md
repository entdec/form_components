# Form components

A form builder for Rails whose fields are view components (ViewComponent,
Stimulus, Tailwind CSS v4), as a Rails engine: labels, text fields of every
type, text areas, check boxes, radio buttons and their collections, selects,
a combobox, ratings, scales, color and file fields, a submit button and
nested forms. Each field has its
label (marked when the attribute is required), a description, and its errors.

The fields are Rails' own: every helper takes the arguments Rails' form
builder takes, and renders its input with Rails' helper, so names, ids,
values, options, hidden fields and nested forms are exactly as with Rails.
The components add their look and their extras around it. Helpers without a
component (`select`, `hidden_field`, `range_field`, …) are Rails' as they are.

## Installation

In the Gemfile:

```ruby
gem "form_components", github: "entdec/form_components"
```

The engine adds its pins to the importmap. Register the controllers with the
host's Stimulus application:

```js
import { registerFormComponents } from "form_components"
registerFormComponents(window.Stimulus)
```

And include the styles in the host's Tailwind CSS (tailwindcss-rails v4), in
`app/assets/tailwind/application.css`:

```css
@import "../builds/tailwind/form_components";
```

### What the host provides

- A `primary` color in its Tailwind theme (`--color-primary-50` to `-950`).
- The `@tailwindcss/forms` plugin (`@plugin "@tailwindcss/forms";`), which
  draws a select's arrow and a checked check box's checkmark.
- An `auto-dark` variant, for the components' dark mode, so the host decides
  which pages have one. Follow the OS everywhere with:

  ```css
  @custom-variant auto-dark (@media (prefers-color-scheme: dark));
  ```

  or keep it off with `@custom-variant auto-dark (&:where(.never-dark, .never-dark *));`
- [Font Awesome](https://fontawesome.com), for the icons (`fas`, `fal`).

### Bundling with esbuild

Instead of the importmap, a bundler resolves these imports to the gem:

- `form_components` to `app/javascript/form_components/application.js`
- `form_components/components/<name>/component_controller` to
  `app/components/form_components/<name>/component_controller.js`
- `form_components/jscolorpicker` to
  `vendor/javascript/form_components/jscolorpicker/colorpicker.js`

## Usage

```erb
<%= form_with model: @post, builder: FormComponents::FormBuilder do |f| %>
  <%= f.text_field :title, placeholder: "A title", description: "Shown on top", leading_icon: "fas fa-heading" %>
  <%= f.email_field :email, corner_hint: "Optional" %>
  <%= f.text_area :body, label: false %>
  <%= f.check_box :published %>
  <%= f.collection_radio_buttons :kind, Kind.all, :id, :name, {description_method: :hint}, {class: "mine"} %>
  <%= f.select :category, Post::CATEGORIES, {include_blank: true}, description: "Where it goes" %>
  <%= f.rating_field :rating %>
  <%= f.color_field :color, swatches: ["#e6007e", "#1e40af"], default: "#e6007e" %>
  <%= f.file_field :logo, accept: "image/*", preview: @post.logo %>
  <%= f.submit %>
<% end %>
```

### As the default form builder

To use it without `builder:`, for the whole app, in `config/application.rb`:

```ruby
config.action_view.default_form_builder = "FormComponents::FormBuilder"
```

Or for a controller and its subclasses:

```ruby
class ApplicationController < ActionController::Base
  default_form_builder FormComponents::FormBuilder
end
```

App-wide, it's also the builder for engines' views that don't name one, so
those forms change too; per controller, for engines' controllers that inherit
from it. `builder:` still picks another builder for a form, like
`ActionView::Helpers::FormBuilder` for Rails' own fields.

### Fields

Each helper takes Rails' arguments, and these extras in its options, which
Rails doesn't get:

- **Every field**: `label:` (a text, or false for none) and `description:`,
  shown below it. A label is Rails' `label`, so its text comes from
  `helpers.label.<model>.<attribute>` too.
- **Text fields**: `text_field`, `password_field`, `search_field`,
  `telephone_field` (`phone_field`), `date_field`, `time_field`,
  `datetime_field`, `datetime_local_field`, `month_field`, `week_field`,
  `url_field`, `email_field` and `number_field`, with `leading_icon:` and
  `corner_hint:`. `text_area` (`textarea`) with `corner_hint:`.
- **Check boxes and radio buttons**: `check_box` (`checkbox`), with its hidden
  unchecked value, `multiple:` and the rest as Rails; `radio_button`.
- **Collections**: `collection_check_boxes` and `collection_radio_buttons` in a
  fieldset, with the label as its legend and the description and errors once;
  `description_method:` (a method name or a proc, as `value_method`) gives each
  item a description of its own. With a block, the block renders the items, as
  with Rails.
- **Selects**: `select`, `collection_select`, `grouped_collection_select`,
  `time_zone_select` and `weekday_select`, as Rails'; the extras go in either
  hash, `options` or `html_options`. The arrow is `@tailwindcss/forms`'.
- **Combobox**: `combobox`, [hotwire_combobox](https://hotwirecombobox.com)'s,
  when the host has that gem, with its arguments; our label replaces its own.
- **Rating**: `rating_field` gives stars from 1 to `max:` (5), and
  **scale**: `scale_field` a row of numbers, `in:` (1..5), with `min_label:`
  and `max_label:` at its ends. Both are Rails' `collection_radio_buttons` of
  their numbers, so they send a number, or an empty value when none is
  picked, and need no JS.
- **Color field**: a color as `#rrggbb`, picked with JS Color Picker by
  Zygomatic (vendored, MIT), with `swatches:` to pick with one click and
  `default:` shown while it's empty. Unlike Rails' `color_field` it is a text
  field (Rails' `text_field`, so its name, id and options are Rails'), and it
  can be cleared: empty stays empty, where Rails sends `#000000`, so it can
  mean the default color.
- **File field**: Rails' (which makes the form multipart), with `preview:`, an
  Active Storage attachment to show above it.
- **Submit**: Rails' `submit`, named after the record as Rails names it.

A field with errors is wrapped as Rails wraps it
(`ActionView::Base.field_error_proc`); in a component the wrapper takes no
place (`.form-component .field_with_errors { display: contents }`).

### Required fields

A field's label is marked when its attribute has a presence validator. Pass
the validation context to the form to count those `on:` it:

```erb
<%= form_with model: @post, builder: FormComponents::FormBuilder, validation_context: :publish do |f| %>
```

### Nested forms

For a has_many association with `accepts_nested_attributes_for`:

```erb
<%= f.nested_form :sections do |nf| %>
  <% nf.with_item do |sf| %>
    <div class="section-wrapper" data-new-record="<%= sf.object.new_record? %>">
      <%= sf.hidden_field :_destroy %>
      <%= sf.text_field :title %>
      <button type="button" data-action="form-components--nested-form#remove">Remove</button>
    </div>
  <% end %>
  <% nf.with_add_button do %>
    <button type="button">Add section</button>
  <% end %>
<% end %>
```

The add button adds a new item from a template, the remove button removes a
new item, or hides a saved one and marks it to be destroyed. Options:
`placeholder:` (the token replaced in the template, `NEW_SECTION`),
`wrapper_selector:` (an item's wrapper, `.section-wrapper`), `new_record:`
(the template's record, the association's `new`) and `add_label:` (for the
default add button).

## Development

```sh
bundle install
bundle exec rake test
bundle exec standardrb
```

The tests run in the dummy app (`test/dummy`), which shows every component on
one page, and what its form sends:

```sh
cd test/dummy && bin/rails server
```

`test/form_builders/rails_parity_test.rb` renders each helper with Rails' own
form builder and with this one, and compares their form controls.

## License

MIT, see MIT-LICENSE. JS Color Picker is MIT too, see
`vendor/javascript/form_components/jscolorpicker/LICENSE`.
