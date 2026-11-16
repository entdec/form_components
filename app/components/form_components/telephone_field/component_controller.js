import CountryPicker from "form_components/components/country_field/country_picker"

// A country picker for a phone number: the hidden field gets the number with
// the picked country's code, as "+31123456789", or nothing while it's empty
export default class extends CountryPicker {
  static targets = ["code", "number", "value"]

  connect() {
    this.codes = new Map(this.countriesValue)
    this.label = this.toggleTarget.getAttribute("aria-label")
    super.connect()
  }

  picked() {
    this.sync()
    this.numberTarget.focus()
  }

  updateToggle() {
    super.updateToggle()
    const iso = this.countryValue
    this.codeTarget.textContent = `+${this.codes.get(iso)}`
    this.toggleTarget.setAttribute("aria-label", `${this.label}: ${this.names.get(iso)} +${this.codes.get(iso)}`)
  }

  // A number typed or pasted with its code ("+44 20…", "0044 20…") picks
  // that code's country
  input() {
    const typed = this.numberTarget.value.trim()
    if (/^(\+|00)/.test(typed)) {
      const digits = typed.replace(/^00/, "").replace(/\D/g, "")
      const code = [1, 2, 3].map((length) => digits.slice(0, length)).find((prefix) => [...this.codes.values()].includes(prefix))
      if (code) {
        this.countryValue = this.countryFor(code)
        this.numberTarget.value = digits.slice(code.length)
        this.updateToggle()
      }
    }
    this.sync()
  }

  // The picked country, a priority one, else the code's main country
  countryFor(code) {
    const candidates = [this.countryValue, ...this.priorityValue]
    return candidates.find((iso) => this.codes.get(iso) === code) ||
      this.countriesValue.find(([, c]) => c === code)[0]
  }

  // The number with the code, without the national 0 before it (but Italy's)
  sync() {
    const code = this.codes.get(this.countryValue)
    let digits = this.numberTarget.value.replace(/\D/g, "")
    if (code !== "39") digits = digits.replace(/^0+/, "")
    this.valueTarget.value = digits === "" ? "" : `+${code}${digits}`
    this.valueTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
