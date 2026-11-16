# Form components

A form builder for Rails whose fields are view components (ViewComponent,
Stimulus, Tailwind CSS v4), as a Rails engine: labels, text fields of every
type, text areas, a rich text area (Tiptap), check boxes, radio buttons and
their collections, selects, a combobox, ratings, scales, color and file
fields, a submit button and nested forms. Each field has its
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
- [Propshaft](https://github.com/rails/propshaft), which resolves the flags'
  `url(form_components/flags/nl.svg)` in the stylesheet to the gem's images.
  The flags are [flag-icons](https://flagicons.lipis.dev)' (4:3, vendored),
  as `fi fi-nl`, also for the host's own use.

### Bundling with esbuild

Instead of the importmap, a bundler resolves these imports to the gem:

- `form_components` to `app/javascript/form_components/application.js`
- `form_components/components/<name>/component_controller` to
  `app/components/form_components/<name>/component_controller.js`
- `form_components/components/<name>/<file>` (as `country_field/country_picker`)
  to `app/components/form_components/<name>/<file>.js`
- `form_components/jscolorpicker` to
  `vendor/javascript/form_components/jscolorpicker/colorpicker.js`, and
  `form_components/tiptap`, `form_components/codemirror` and
  `form_components/signature_pad` to `vendor/javascript/form_components/<name>.js`

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
  `date_field`, `time_field`,
  `datetime_field`, `datetime_local_field`, `month_field`, `week_field`,
  `url_field`, `email_field` and `number_field`, with `leading_icon:` and
  `corner_hint:`. `text_area` (`textarea`) with `corner_hint:`.
- **Rich text area**: `rich_text_area` (`rich_textarea`) is a
  [Tiptap](https://tiptap.dev) editor instead of Rails' Trix (vendored, see
  [Development](#development)), for an Action Text attribute (`has_rich_text`)
  or one that holds HTML. The HTML is in Rails' `text_area`, with Rails' name,
  id and options, out of sight: the label points at it, the browser checks it
  when it's required, and it hands its focus to the editor. `toolbar:` names
  its buttons, with `:|` between groups, or is `false` for none:

  ```erb
  <%= f.rich_text_area :content, toolbar: %i[heading | bold italic link | bullet_list ordered_list] %>
  ```

  The buttons are `heading` (a select of paragraph and headings 1–3), `bold`,
  `italic`, `underline`, `strike`, `code`, `link` (⌘K), `bullet_list`,
  `ordered_list`, `blockquote`, `code_block`, `horizontal_rule`,
  `align_left`, `align_center`, `align_right`, `align_justify`, `image`,
  `undo` and `redo`; the default is
  `%i[heading | bold italic underline strike | link | bullet_list ordered_list blockquote | image | undo redo]`,
  set for the app with `FormComponents::RichTextArea::Component.default_toolbar`.
  The editor allows only the formatting of its toolbar, also when pasting or
  typing Markdown. `image` uploads an image, also a pasted or dropped one,
  with Active Storage's direct uploads, when the host has Active Storage (or
  as Rails takes them, `data: {direct_upload_url:, blob_url_template:}`); a
  form submitted while one uploads waits for it. On an Action Text attribute
  an image is an attachment, as with Trix; elsewhere an `<img>` with the
  blob's URL. Other attachments an Action Text attribute has from Trix are
  left out. `placeholder:` shows while it's empty, `class:` is the editor's
  and `corner_hint:` as a text area; translate the buttons' titles in
  `form_components.rich_text_area` (`bold`, `bullet_list`, …,
  `heading_level`, `paragraph`, `url`, `apply`, `remove_link`). Like the
  color field it needs JS; `upload-error` is dispatched
  (`form-components--rich-text-area:upload-error`) when an upload fails, with
  an alert unless it's prevented.
- **Code editor**: `code_editor` (`editor`, as Satis') is a
  [CodeMirror](https://codemirror.net) editor (vendored) for code, with
  `lang:` (`sql`, `json`, `yaml`, `liquid`, `markdown`, `javascript`, `html`,
  `css`; none for plain text) and `height:` (CSS, `12rem` by default, or
  `FormComponents::CodeEditor::Component.default_height`), scrolling beyond
  it. The code is in Rails' text area, out of sight, as the rich text
  area's; `readonly:` or `disabled:` make it read-only. CodeMirror is loaded
  when the first editor shows. It needs JS.

  ```erb
  <%= f.code_editor :sql, lang: :sql, height: "24rem" %>
  ```
- **Signature field**: `signature_field` (`signature`, as Satis') draws a
  signature with [signature_pad](https://github.com/szimek/signature_pad)
  (vendored) and sends it as an SVG file in Rails' file field, out of sight,
  for an Active Storage attachment. `width:` and `height:` are the pad's size
  (400 × 200), at most the field's width. The signature there shows under the
  pad until a new one is drawn; undo and clear in a menu (…), clear also removing
  the signature there when the record takes `remove_<attribute>`. Serving
  SVG as an image needs it out of Active Storage's
  `content_types_to_serve_as_binary`. Translate the buttons' titles in
  `form_components.signature_field` (`more`, `undo`, `clear`). It needs JS.
- **Telephone field**: `telephone_field` (`phone_field`) takes Rails'
  arguments, with a country picker before the number: a flag and the
  country's calling code, and a list of countries to search, `priority_countries:`
  (`%w[nl de be fr gb]`) on top, named in `I18n.locale`. It sends the number
  with the code, as `+31123456789` (without the national `0`, but Italy's),
  in a hidden field with Rails' name; the number is typed in Rails'
  telephone field, with its id and options. A number with a code picks its
  country, also when typed or pasted (`+44 20…`, `0044 20…`); one without, as
  a plain field saved it, is shown as it is, with `country:` (`"nl"`). Set
  the defaults for the app with
  `FormComponents::TelephoneField::Component.default_country` and
  `.default_priority_countries`; translate `form_components.telephone_field.country`
  and `.search`. Like the color field it needs JS; `text_field :phone, type: "tel"`
  is a plain one. `corner_hint:` as a text field.
- **Country field**: `country_field` picks a country from the same list as
  the telephone field's, with flags and names in `I18n.locale` (the
  browser's), `priority_countries:` on top, and sends its ISO 3166 code in
  capitals (`NL`) in Rails' hidden field; a code in any case is read. Not
  required, it can be cleared. `placeholder:` while there's none
  (`form_components.country_field.placeholder`), and `.search`, `.clear`.
  A code set on the hidden field by other JS, with a change event, is shown
  as picked. It needs JS.
- **Check boxes and radio buttons**: `check_box` (`checkbox`), with its hidden
  unchecked value, `multiple:` and the rest as Rails, and `switch: true` to
  look like a switch (still the check box, with `role="switch"`, no JS);
  `radio_button`.
- **Collections**: `collection_check_boxes` and `collection_radio_buttons` in a
  fieldset, with the label as its legend and the description and errors once;
  `description_method:` (a method name or a proc, as `value_method`) gives each
  item a description of its own. With a block, the block renders the items, as
  with Rails.
- **Selects**: `select`, `collection_select`, `grouped_collection_select`,
  `time_zone_select` and `weekday_select`, as Rails'; the extras go in either
  hash, `options` or `html_options`. The arrow is `@tailwindcss/forms`'.
  `depends_on:` (a field of the same form, or several) shows only the
  option groups for those fields' values: each group says which values it's
  for in an attribute named after the field (`data-role` for `:role`), and a
  group without one is for any value. A choice that no longer fits is
  cleared, the only option left chosen, each with a change event, so selects
  can depend on each other in a chain. In a nested form a field is the
  row's own. Without JS all groups show.

  ```erb
  <%= f.select :role, Member::ROLES %>
  <%= f.select :function, [["Players", [["Keeper", "keeper"], …], {data: {role: "player"}}], …],
        {include_blank: true}, depends_on: :role %>
  ```
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

### Fieldsets

`fieldset` (`field_set`) groups fields in a card, as Rails' `field_set_tag`
(`legend`, `options`), with `description:` and `legend_position:`, where the
heading goes: `:above` the card (the default), `:inside` it, on its first
line, or `:beside` it, with the description, in a column of its own on wider
screens (as settings pages have it). The legend is for screen readers; the
heading shown is a copy, as a fieldset draws its own legend on its border.
It's not a field, so it renders in any form, too:
`render FormComponents::Fieldset::Component.new("Pricing", legend_position: :inside)`.

```erb
<%= f.fieldset "Pricing", description: "What a sponsor pays" do %>
  <%= f.text_field :price %>
<% end %>
```

A field with errors is wrapped as Rails wraps it
(`ActionView::Base.field_error_proc`); in a component the wrapper takes no
place (`.form-component .field_with_errors { display: contents }`).

### The app's own components

`FormComponents::FormBuilder.register` adds a helper for a component of the
app's: its block gets the helper's arguments and returns the component, and
runs in the builder (`self`, `object`, `@template`); the helper renders it,
with its own block as the content. Registering a name again replaces it, so
it can be done in a `to_prepare`, as the app's components reload:

```ruby
# config/initializers/form_components.rb
Rails.application.config.to_prepare do
  FormComponents::FormBuilder.register(:image_upload) do |method = :photo, **options|
    ImageUpload::Component.new(form: self, attribute: method, **options)
  end
end
```

```erb
<%= f.image_upload :logo, shape: :square %>
```

### Required fields

A field's label is marked when its attribute has a presence validator, and
its input gets `required`, for the browser to check, when the validator
holds for the record as it is (its `if:` and `unless:`). Not for a check box
that is one of several or of a collection, which would each have to be
checked, nor for a file field, as a file there already isn't sent again.
`required: false` leaves it out. Pass the validation context to the form to
count those `on:` it:

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

`/articles/new` there has a rich text area on an Action Text attribute,
with what it stores and how that renders.

`test/form_builders/rails_parity_test.rb` renders each helper with Rails' own
form builder and with this one, and compares their form controls.

Tiptap, and Active Storage's `DirectUpload`, are vendored as one ES module,
`vendor/javascript/form_components/tiptap.js`, CodeMirror with its
languages as another, `codemirror.js`, and signature_pad as
`signature_pad.js`; flag-icons' flags are copied into
`app/assets/images/form_components/flags`, with their classes in
`app/assets/stylesheets/form_components/flags.css`. To update them:

```sh
cd script/vendor && npm install && node build.mjs
```

## License

MIT, see MIT-LICENSE. JS Color Picker is MIT too, see
`vendor/javascript/form_components/jscolorpicker/LICENSE`, and so are the
vendored Tiptap, Active Storage, CodeMirror and signature_pad JavaScript, and
flag-icons' flags (`app/assets/images/form_components/flags/LICENSE`).
