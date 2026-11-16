import { Controller } from "@hotwired/stimulus"

// Picking a country from a list with their flags (.fi, flags.css) and names
// in the locale (Intl.DisplayNames), searched as typed, with the priority
// countries at the top: the telephone field's and the country field's.
//
// countries: [iso, detail] each, the detail ("31", a calling code) shown as
// "+31" after its name, if there is one. A subclass shows the pick in its
// toggle (updateToggle) and does what picking means (picked); it can pick
// other codes, such as currencies, with namesType, icon and detailText.
export default class extends Controller {
  static targets = ["toggle", "flag", "menu", "search", "list"]
  static values = { countries: Array, priority: Array, country: String, locale: String }

  connect() {
    this.details = new Map(this.countriesValue)
    this.render()
    this.updateToggle()
  }

  // The priority countries, then the rest by their names in the locale
  render() {
    const names = this.displayNames()
    const collator = new Intl.Collator(this.localeValue || undefined)
    const country = (iso) => ({ iso, detail: this.details.get(iso), name: names(iso) })
    const priority = this.priorityValue.map(country)
    const rest = [...this.details.keys()].filter((iso) => !this.priorityValue.includes(iso)).map(country)
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
      const names = new Intl.DisplayNames([this.localeValue || "en", "en"], { type: this.namesType })
      return (iso) => names.of(iso.toUpperCase()) || iso.toUpperCase()
    } catch {
      return (iso) => iso.toUpperCase()
    }
  }

  // The kind of names of the codes, Intl.DisplayNames' type
  get namesType() {
    return "region"
  }

  // Before an option's name: the country's flag
  icon(iso) {
    const flag = document.createElement("span")
    flag.className = `fi fi-${iso} shrink-0 rounded-xs`
    return flag
  }

  // After an option's name: its detail, a calling code
  detailText(detail) {
    return `+${detail}`
  }

  option({ iso, detail, name }) {
    const li = document.createElement("li")
    li.id = `${this.listTarget.id}_${iso}`
    li.setAttribute("role", "option")
    li.setAttribute("aria-selected", "false")
    li.dataset.country = iso
    li.dataset.search = `${this.normalize(name)} ${iso}${detail ? ` ${this.detailText(detail)}` : ""}`
    li.className = "flex cursor-pointer items-center gap-3 rounded-md px-3 py-2 text-base text-gray-900 select-none aria-selected:font-semibold data-active:bg-gray-100 sm:text-sm/6 auto-dark:text-white auto-dark:data-active:bg-white/10"

    const icon = this.icon(iso)
    const label = document.createElement("span")
    label.className = "grow truncate"
    label.textContent = name
    li.append(...(icon ? [icon] : []), label)
    if (detail) {
      const dial = document.createElement("span")
      dial.className = "text-gray-500 auto-dark:text-gray-400"
      dial.textContent = this.detailText(detail)
      li.append(dial)
    }
    return li
  }

  // Only options are allowed in a listbox: the line is for the eye
  separator() {
    const li = document.createElement("li")
    li.setAttribute("role", "none")
    li.dataset.separator = ""
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

  // Countries whose name, ISO code or detail has what's typed
  filter() {
    const query = this.normalize(this.searchTarget.value.trim())
    for (const li of this.listTarget.children) {
      li.hidden = query !== "" && ("separator" in li.dataset || !li.dataset.search.includes(query))
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
    this.close()
    this.picked(iso)
  }

  // The flag of the country picked, none without one, and the pick in the list
  updateToggle() {
    const iso = this.countryValue
    if (this.hasFlagTarget) this.flagTarget.className = iso ? `fi fi-${iso} rounded-xs` : "hidden"
    for (const li of this.listTarget.querySelectorAll("[role=option]")) {
      li.setAttribute("aria-selected", li.dataset.country === iso ? "true" : "false")
    }
  }

  picked(iso) {}
}
