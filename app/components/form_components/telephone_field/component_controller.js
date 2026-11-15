import { Controller } from "@hotwired/stimulus"

// A country picker for a phone number: the hidden field gets the number with
// the picked country's code, as "+31123456789", or nothing while it's empty
export default class extends Controller {
  static targets = ["toggle", "flag", "code", "number", "value", "menu", "search", "list"]
  static values = { countries: Array, priority: Array, country: String, locale: String }

  connect() {
    this.codes = new Map(this.countriesValue)
    this.render()
    this.updateToggle()
  }

  // The priority countries, then the rest by their names in the locale
  render() {
    const names = this.displayNames()
    const collator = new Intl.Collator(this.localeValue || undefined)
    const country = (iso) => ({ iso, code: this.codes.get(iso), name: names(iso) })
    const priority = this.priorityValue.map(country)
    const rest = [...this.codes.keys()].filter((iso) => !this.priorityValue.includes(iso)).map(country)
      .sort((a, b) => collator.compare(a.name, b.name))

    this.names = new Map([...priority, ...rest].map(({ iso, name }) => [iso, name]))
    this.listTarget.replaceChildren(
      ...priority.map((c) => this.option(c)),
      ...(priority.length > 0 ? [this.separator()] : []),
      ...rest.map((c) => this.option(c))
    )
  }

  displayNames() {
    try {
      const names = new Intl.DisplayNames([this.localeValue || "en", "en"], { type: "region" })
      return (iso) => names.of(iso.toUpperCase()) || iso.toUpperCase()
    } catch {
      return (iso) => iso.toUpperCase()
    }
  }

  option({ iso, code, name }) {
    const li = document.createElement("li")
    li.id = `${this.listTarget.id}_${iso}`
    li.setAttribute("role", "option")
    li.setAttribute("aria-selected", "false")
    li.dataset.country = iso
    li.dataset.search = `${this.normalize(name)} ${iso} +${code}`
    li.className = "flex cursor-pointer items-center gap-3 rounded-md px-3 py-2 text-base text-gray-900 select-none aria-selected:font-semibold data-active:bg-gray-100 sm:text-sm/6 auto-dark:text-white auto-dark:data-active:bg-white/10"

    const flag = document.createElement("span")
    flag.className = `fi fi-${iso} shrink-0 rounded-xs`
    const label = document.createElement("span")
    label.className = "grow truncate"
    label.textContent = name
    const dial = document.createElement("span")
    dial.className = "text-gray-500 auto-dark:text-gray-400"
    dial.textContent = `+${code}`
    li.append(flag, label, dial)
    return li
  }

  separator() {
    const li = document.createElement("li")
    li.setAttribute("role", "separator")
    li.className = "mx-2 my-1 border-t border-gray-200 auto-dark:border-white/10"
    return li
  }

  normalize(text) {
    return text.normalize("NFD").replace(/\p{Diacritic}/gu, "").toLowerCase()
  }

  toggle() {
    this.menuTarget.hidden ? this.open() : this.close()
  }

  toggleKeydown(event) {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      this.open()
    }
  }

  open() {
    this.menuTarget.hidden = false
    this.toggleTarget.setAttribute("aria-expanded", "true")
    this.searchTarget.value = ""
    this.filter()
    this.activate(this.listTarget.querySelector(`[data-country="${this.countryValue}"]`))
    this.searchTarget.focus()
  }

  close({ focus = false } = {}) {
    if (this.menuTarget.hidden) return

    this.menuTarget.hidden = true
    this.toggleTarget.setAttribute("aria-expanded", "false")
    if (focus) this.toggleTarget.focus()
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  // Countries whose name, ISO code or calling code has what's typed
  filter() {
    const query = this.normalize(this.searchTarget.value.trim())
    for (const li of this.listTarget.children) {
      li.hidden = query !== "" && (li.getAttribute("role") === "separator" || !li.dataset.search.includes(query))
    }
    if (!this.active || this.active.hidden) this.activate(this.visibleOptions()[0])
  }

  searchKeydown(event) {
    const options = this.visibleOptions()
    const index = options.indexOf(this.active)

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.activate(options[Math.min(index + 1, options.length - 1)])
        break
      case "ArrowUp":
        event.preventDefault()
        this.activate(options[Math.max(index - 1, 0)])
        break
      case "Enter":
        event.preventDefault()
        if (this.active) this.select(this.active.dataset.country)
        break
      case "Escape":
        event.preventDefault()
        this.close({ focus: true })
        break
      case "Tab":
        this.close()
        break
    }
  }

  visibleOptions() {
    return [...this.listTarget.querySelectorAll("[role=option]:not([hidden])")]
  }

  activate(option) {
    this.active?.removeAttribute("data-active")
    this.active = option
    if (!option) {
      this.searchTarget.removeAttribute("aria-activedescendant")
      return
    }

    option.setAttribute("data-active", "")
    this.searchTarget.setAttribute("aria-activedescendant", option.id)
    option.scrollIntoView({ block: "nearest" })
  }

  hover(event) {
    const option = event.target.closest("[role=option]")
    if (option && option !== this.active) this.activate(option)
  }

  pick(event) {
    const option = event.target.closest("[role=option]")
    if (option) this.select(option.dataset.country)
  }

  select(iso) {
    this.countryValue = iso
    this.updateToggle()
    this.sync()
    this.close()
    this.numberTarget.focus()
  }

  updateToggle() {
    const iso = this.countryValue
    this.flagTarget.className = `fi fi-${iso} rounded-xs`
    this.codeTarget.textContent = `+${this.codes.get(iso)}`
    this.toggleTarget.setAttribute("aria-label", `${this.names.get(iso)} +${this.codes.get(iso)}`)
    for (const li of this.listTarget.querySelectorAll("[role=option]")) {
      li.setAttribute("aria-selected", li.dataset.country === iso ? "true" : "false")
    }
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
