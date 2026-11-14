# Changelog

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
