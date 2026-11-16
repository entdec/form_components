import { Controller } from "@hotwired/stimulus"

// The symbol before the amount, of the currency picked
export default class extends Controller {
  static targets = ["symbol", "currency"]
  static values = { symbols: Object }

  update() {
    if (this.hasSymbolTarget) this.symbolTarget.textContent = this.symbolsValue[this.currencyTarget.value] || ""
  }
}
