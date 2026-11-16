import { Controller } from "@hotwired/stimulus"
import ColorPicker from "form_components/jscolorpicker"

// Turns the text input into a JS Color Picker that fills in "#rrggbb", or nothing when cleared.
//
// The picker's toggle, a button around the input, is named by the field's
// label and the color, and its dialog's controls by labels (their names),
// which the picker has none of. Its thumbs are for the pointer only: the
// keyboard has the hex field the dialog opens with, and the swatches. The
// focus is back on the toggle when the dialog closes with it.
export default class extends Controller {
  static targets = ["input"]
  static values = { swatches: Array, labels: Object }

  connect() {
    this.picker = new ColorPicker(this.inputTarget, {
      toggleStyle: "input",
      enableAlpha: false,
      formats: false,
      defaultFormat: "hex",
      swatches: this.swatchesValue.length > 0 ? this.swatchesValue : null,
      showClearButton: true,
      dialogPlacement: "bottom-start"
    })
    this.label()
    this.picker.on("open", () => this.opened())
    this.picker.on("close", () => this.closed())
  }

  disconnect() {
    this.picker?.destroy()
    this.picker = null
  }

  label() {
    const toggle = this.picker.element
    const label = this.inputTarget.labels?.[0]
    if (label?.id) toggle.setAttribute("aria-labelledby", `${label.id} ${this.inputTarget.id}`)
    const describedBy = this.inputTarget.getAttribute("aria-describedby")
    if (describedBy) toggle.setAttribute("aria-describedby", describedBy)
    toggle.setAttribute("aria-haspopup", "dialog")
    toggle.setAttribute("aria-expanded", "false")
  }

  opened() {
    const dialog = this.picker.$dialog
    if (!dialog) return

    this.picker.element.setAttribute("aria-expanded", "true")
    dialog.setAttribute("role", "dialog")
    const label = this.inputTarget.labels?.[0]
    if (label?.id) dialog.setAttribute("aria-labelledby", label.id)
    const names = { ".cp_value": "value", ".cp_eyedrop": "eyedropper", ".cp_clear": "clear", ".cp_submit": "submit" }
    for (const [selector, name] of Object.entries(names)) dialog.querySelector(selector)?.setAttribute("aria-label", this.labelsValue[name])
    for (const swatch of dialog.querySelectorAll(".cp_swatch")) swatch.setAttribute("aria-label", swatch.dataset.color)
    for (const thumb of dialog.querySelectorAll(".cp_thumb")) {
      thumb.tabIndex = -1
      thumb.setAttribute("aria-hidden", "true")
    }
    this.dialog = dialog
  }

  // Closed from the dialog (Escape, Done, Clear): not when a click outside
  // closed it, which put the focus elsewhere
  closed() {
    this.picker.element.setAttribute("aria-expanded", "false")
    const focused = document.activeElement
    if (!focused || focused === document.body || this.dialog?.contains(focused)) this.picker.element.focus()
    this.dialog = null
  }
}
