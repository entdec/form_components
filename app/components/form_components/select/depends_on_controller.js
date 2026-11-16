import { Controller } from "@hotwired/stimulus"

// A select whose options depend on other fields of its form: of its groups
// (optgroups), only those whose attributes (data-role="player") match those
// fields' values are in it, a group without one of them for any value. The
// options outside a group (a blank, a prompt) stay. A choice that no longer
// fits is cleared, and the only option left is chosen, each with a change
// event, so a select depending on this one follows.
//
// Safari doesn't hide options, so the groups are taken out and put back.
export default class extends Controller {
  static values = { fields: Array }

  connect() {
    this.select = this.element.querySelector("select")
    this.groups = [...this.select.querySelectorAll("optgroup")]
    this.changed = this.changed.bind(this)
    this.form?.addEventListener("change", this.changed)
    // A saved choice stays, also when it doesn't fit (yet)
    this.update({ keep: this.select.value })
  }

  disconnect() {
    this.form?.removeEventListener("change", this.changed)
  }

  get form() {
    return this.select.form
  }

  changed(event) {
    if (this.fieldsValue.some(({ name }) => name === event.target.name)) {
      this.update({ choose: true })
    }
  }

  update({ keep = null, choose = false } = {}) {
    const values = this.fieldsValue.map(({ name, attribute }) => ({ attribute, value: this.valueOf(name) }))
    const matching = this.groups.filter((group) =>
      values.every(({ attribute, value }) => !group.hasAttribute(attribute) || group.getAttribute(attribute) === value)
      || (keep && [...group.querySelectorAll("option")].some((option) => option.value === keep)))

    const selected = this.select.value
    this.groups.forEach((group) => group.remove())
    this.select.append(...matching)

    const options = matching.flatMap((group) => [...group.querySelectorAll("option")])
    if (choose && options.length === 1) {
      this.select.value = options[0].value
    } else if (!options.some((option) => option.value === selected)) {
      this.select.value = ""
    } else {
      this.select.value = selected
    }

    if (this.select.value !== selected) {
      this.select.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }

  // The field's value: of radio buttons or a check box the checked one's,
  // else the hidden field's Rails gives a check box
  valueOf(name) {
    const fields = [...this.form.elements].filter((element) => element.name === name)
    const choices = fields.filter((element) => ["radio", "checkbox"].includes(element.type))
    if (choices.length === 0) return fields[0]?.value ?? ""

    return choices.find((element) => element.checked)?.value ?? fields.find((element) => element.type === "hidden")?.value ?? ""
  }
}
