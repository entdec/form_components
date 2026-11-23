# Changelog

## Unreleased

- `signature_field` takes `pen_color:` (`#111827` by default): the pad
  draws in it, and the signature there shows in it too, whatever colour it
  was drawn in, as a mask over the colour instead of an image.
- `money_field` offers the money gem's ISO 4217 currencies by default, not
  its others (BTC, USDC): USDC's four letters made the browser's names for
  them throw, which left the list empty. A code without a name in the
  browser goes by its code, in the currency and country pickers.

- `required: true` marks a field's label and gives its input `required`
  without a presence validator; `required: false` takes the label's asterisk
  away too.
- A field that can't be changed (`readonly:` or `disabled:`) is no longer
  required (no asterisk, no `required`), and looks it: text fields, text
  areas and selects on a tint with a dashed edge.
- With a validation context, validators without `on:` count too, as Rails
  runs them: a field required in every context kept its asterisk only
  without one.

## 0.1.10

- `combobox` with chips (hotwire_combobox's `multiselect_chip_src:`): as
  wide as the other fields instead of 30rem, without the handle (focusing it
  opens the list), its chips as far from its sides as from its top and
  bottom, and its input beside the chips while there's room rather than on a
  line of its own.
- A form without a model (`form_with scope:`, whose object Rails makes
  `false`) no longer fails on its fields' validators.

## 0.1.9

- `combobox`: as wide and high as the other fields (36px, its text in the
  middle and as far in as theirs), text-base and sm:text-sm, and on focus a
  2px ring in the focus colour as their outline, red-300 with an error.
  Through hotwire_combobox's variables, as its unlayered styles win over the
  components layer. A host app no longer needs its own sizes for it.

## 0.1.8

- `money_field`: the currency is picked at the field's start, from a list as
  the telephone field's countries (names in the locale, searched as typed,
  `priority_currencies:` on top), instead of a select at its end, and sent in
  Rails' hidden field. It's shown by its symbol, or by its code with
  `currency_display: :code`, no longer as a symbol before the amount.
  `currencies:` are codes, no longer a select's choices. `fixed_currency:
  true` shows the currency without letting it be changed.
- `field_group`: fields in one box, each below the one before or in a
  `field_row` beside each other, with a legend, their labels for screen
  readers only and their descriptions and errors below the box.
- The country picker (`country_field/country_picker`) can pick other codes:
  `namesType`, `icon` and `detailText`.

## 0.1.7

- `money_field`: an amount with its currency picked at its end and the
  currency's symbol before it, in one field, for money-rails' `monetize`.
- Accessibility, as the W3C's forms tutorial has it: an input is described by
  its errors and its description (both, no longer only the errors); a check
  box's, radio button's and collection item's description is a paragraph
  that describes it, no longer a second label; `aria-required` where the
  label is marked but the browser doesn't check it, and "(required)" in the
  label or legend where an input can't have it; `hide_label: true` for a
  label for screen readers only; icons hidden from screen readers; a
  rating's stars named "3 stars", a scale's end labels describing its ends;
  the country field's button named by its label and the country; the
  telephone field's country button says it's the country; the rich text
  area's toolbar named and one Tab stop, with the arrow keys; the signature
  field's menu a disclosure that gives the focus back; the color picker's
  toggle and dialog named; the nested form's focus on the new item's field,
  and on the add button after a remove; placeholders with enough contrast
  (gray-500, gray-400 in dark mode).
- The rich text area's toolbar looks like Tiptap's own editor's: light
  buttons with Lucide's icons (vendored, ISC), the headings in a menu
  instead of a select, and the image button saying "Add".
- The code editor's gutter is part of the field: no band or hard border, its
  line numbers muted, the current line marked only while it has the focus.
- A switch's knob has a check when it's on and a cross when it's off.
- `error_summary`: the form's errors above its fields, each a link to its
  field, focused when there are errors.

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
- `code_editor` (`editor`): a CodeMirror editor for code, with `lang:` and
  `height:`, as Satis' editor. CodeMirror is vendored
  (`vendor/javascript/form_components/codemirror.js`), loaded when the first
  editor shows.
- `signature_field` (`signature`): a signature drawn with signature_pad
  (vendored), sent as an SVG file for an Active Storage attachment, as
  Satis' signature, with `width:` and `height:`.
- `check_box`'s `switch: true` looks like a switch, as Satis' switch, still a
  check box.
- flag-icons' flags are the gem's (vendored, 4:3, `fi fi-nl`): the host no
  longer provides them.
- `country_field`: a country picked from a list with flags and names, sent as
  its ISO 3166 code (`NL`), the telephone field's picker.

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
