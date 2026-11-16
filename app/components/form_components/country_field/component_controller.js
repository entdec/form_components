import CountryPicker from "form_components/components/country_field/country_picker"

// A country picked from the list: the hidden field gets its code ("NL"),
// with a change event. A code set on the hidden field by other JS (with a
// change event) is shown as picked.
export default class extends CountryPicker {
  static targets = ["name", "value", "clear"]
  static values = { placeholder: String }

  picked(iso) {
    this.valueTarget.value = iso.toUpperCase()
    this.valueTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.toggleTarget.focus()
  }

  clear() {
    this.countryValue = ""
    this.updateToggle()
    this.valueTarget.value = ""
    this.valueTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.toggleTarget.focus()
  }

  changed() {
    const iso = this.valueTarget.value.toLowerCase()
    if (iso === this.countryValue || (iso && !this.details.has(iso))) return

    this.countryValue = iso
    this.updateToggle()
  }

  updateToggle() {
    super.updateToggle()
    const iso = this.countryValue
    this.nameTarget.textContent = iso ? this.names.get(iso) : this.placeholderValue
    this.nameTarget.classList.toggle("text-gray-400", !iso)
    this.nameTarget.classList.toggle("auto-dark:text-gray-500", !iso)
    if (this.hasClearTarget) this.clearTarget.hidden = !iso
  }
}
