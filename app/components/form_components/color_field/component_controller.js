import { Controller } from "@hotwired/stimulus"
import ColorPicker from "form_components/jscolorpicker"

// Turns the text input into a JS Color Picker that fills in "#rrggbb", or nothing when cleared
export default class extends Controller {
  static targets = ["input"]
  static values = { swatches: Array }

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
  }

  disconnect() {
    this.picker?.destroy()
    this.picker = null
  }
}
