# Form components

A form builder for Rails whose fields are view components (ViewComponent,
Slim, Stimulus, Tailwind CSS v4), as a Rails engine: labels, text fields of
every type, text areas, check boxes, radio buttons and their collections,
color and file fields, a submit button and nested forms. Each field has its
label (marked when the attribute is required), a description, and its errors.

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

```slim
= form_with model: @post, builder: FormComponents::FormBuilder do |f|
  = f.text_field :title, placeholder: "A title", description: "Shown on top", leading_icon: "fas fa-heading"
  = f.email_field :email, corner_hint: "Optional"
  = f.text_area :body, label: false
  = f.check_box :published
  = f.collection_radio_buttons :kind, Kind.all, :id, :name, description_method: :hint
  = f.color_field :color, swatches: ["#e6007e", "#1e40af"], default: "#e6007e"
  = f.file_field :logo, accept: "image/*", preview: @post.logo
  = f.submit
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

Every field takes `label:` (a text, or false for none) and `description:`.
The other options go to the input.

- **Text fields**: `text_field`, and `password_field`, `search_field`,
  `date_field`, `time_field`, `datetime_field`, `datetime_local_field`,
  `month_field`, `week_field`, `url_field`, `email_field` and `number_field`,
  with `placeholder:`, `leading_icon:` and `corner_hint:`.
- **Color field**: a color as `#rrggbb`, picked with JS Color Picker by
  Zygomatic (vendored, MIT). It can be cleared, so empty can mean the default
  color: `default:` shows it while empty, `swatches:` are colors to pick with
  one click.
- **File field**: makes the form multipart; `preview:` is an Active Storage
  attachment to show above it.

### Required fields

A field's label is marked when its attribute has a presence validator. Pass
the validation context to the form to count those `on:` it:

```slim
= form_with model: @post, builder: FormComponents::FormBuilder, validation_context: :publish do |f|
```

### Nested forms

For a has_many association with `accepts_nested_attributes_for`:

```slim
= f.nested_form :sections do |nf|
  - nf.with_item do |sf|
    .section-wrapper data-new-record=sf.object.new_record?.to_s
      = sf.hidden_field :_destroy
      = sf.text_field :title
      button type="button" data-action="form-components--nested-form#remove" Remove
  - nf.with_add_button
    button type="button" Add section
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

## License

MIT, see MIT-LICENSE. JS Color Picker is MIT too, see
`vendor/javascript/form_components/jscolorpicker/LICENSE`.
