# Changelog

## Unreleased

- `rich_text_area` (`rich_textarea`) is a Tiptap editor instead of Rails'
  Trix, for an Action Text attribute or one that holds HTML, with
  `toolbar:` (and `default_toolbar` for the app) and `placeholder:`. Images
  are uploaded with Active Storage's direct uploads, and are attachments on
  an Action Text attribute. Tiptap is vendored
  (`vendor/javascript/form_components/tiptap.js`, built by
  `script/vendor/build.mjs`).
- `fieldset` (`field_set`): a group of fields in a card, as Rails'
  `field_set_tag`, with `description:` and `legend_position:` (`:above`,
  `:inside`, `:beside`). Also renders without a form
  (`FormComponents::Fieldset::Component`).
- `FormComponents::FormBuilder.register(name) { |*args, **options| component }`
  adds a helper for one of the app's components.
- A select's `depends_on:` (a field, or several) shows only the option groups
  for those fields' values, named in an attribute after the field
  (`{data: {role: "player"}}` for `depends_on: :role`), as Satis' `chain_to`.

## 0.1.4

- `telephone_field` (`phone_field`) has a country picker, with flags
  (flag-icons, which the host provides) and a search, and sends the number
  with the country's calling code (`+31123456789`). `country:` and
  `priority_countries:`. Its arguments are still Rails'.

- An input whose attribute has a presence validator gets `required`, when
  the validator's `if:` and `unless:` hold for the record as it is: text
  fields, text areas, selects, comboboxes, a check box, radio buttons
  (also as a collection, rating or scale). Not a check box of several, nor a
  file field. `required: false` leaves it out.
- The combobox has the other fields' colors, and a dark mode (`auto-dark`).

## 0.1.2

- The templates are ERB; slim-rails is no longer a dependency. They render
  the same HTML as the Slim ones did, apart from whitespace between tags.

## 0.1.1

- Every helper takes Rails' arguments and renders Rails' own input, so
  names, ids, values and options are Rails' (with `index:`, `namespace:`,
  `fields_for`, a form without a record, …). Their extras (`label:`,
  `description:`, …) aren't passed to Rails any more.
- `label` is Rails' label: its block, its options and a hash as options, and
  its text from `helpers.label`.
- Collections show each item's text (`text_method`), not its value; they are a
  fieldset with the label as its legend, and show the description and errors
  once, not with every item.
- `check_box` names an array attribute's field `[]` only with `multiple: true`,
  as Rails; `password_field` leaves out the value, as Rails.
- `telephone_field` and `phone_field`.
- `select`, `collection_select`, `grouped_collection_select`,
  `time_zone_select` and `weekday_select`, with a label, description and
  errors; until now they were Rails' plain selects.
- `combobox` (hotwire_combobox's) with a label, description and errors.
- `rating_field` (stars) and `scale_field` (a row of numbers).
- Check boxes have a size of their own, also in a collection, and a
  collection's description is below its legend.
- A dummy app (`test/dummy`), and tests comparing each helper with Rails'.

## 0.1.0

- A form builder whose fields are view components, with Stimulus controllers
  for nested forms and the color field, and a Tailwind entry point.
