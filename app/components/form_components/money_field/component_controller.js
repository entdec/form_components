import CountryPicker from "form_components/components/country_field/country_picker"

// A currency picked from a list with their names in the locale, as a country
// from the country picker's (its countries are the currencies, by their codes
// in lowercase, each with how it's shown, its symbol or code): the toggle
// shows it, and the hidden field gets its code ("EUR"), with a change event
export default class extends CountryPicker {
  static targets = ["display", "value", "amount"]

  connect() {
    this.label = this.toggleTarget.getAttribute("aria-label")
    super.connect()
  }

  get namesType() {
    return "currency"
  }

  icon() {
    return null
  }

  detailText(display) {
    return display
  }

  picked(iso) {
    this.valueTarget.value = iso.toUpperCase()
    this.valueTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.amountTarget.focus()
  }

  updateToggle() {
    super.updateToggle()
    const iso = this.countryValue
    this.displayTarget.textContent = this.details.get(iso)
    this.toggleTarget.setAttribute("aria-label", `${this.label}: ${this.names.get(iso)}`)
  }
}
