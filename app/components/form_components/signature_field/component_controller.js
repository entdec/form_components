import { Controller } from "@hotwired/stimulus"
import SignaturePad from "form_components/signature_pad"

// A signature pad whose signature is the file field's file, as an SVG, with a
// change event on it as choosing a file would. The signature there (the
// image under the pad) stays until the first stroke, which starts a new one;
// clear also removes it, when there is a remove field. Undo and clear are in
// a menu, as an image upload's: a disclosure, its button's focus back when
// it closes with the focus in it.
export default class extends Controller {
  static targets = ["canvas", "image", "file", "remove", "menu", "more"]
  static values = { readOnly: Boolean }

  connect() {
    this.size()
    this.pad = new SignaturePad(this.canvasTarget, { penColor: "#111827" })
    this.pad.addEventListener("beginStroke", () => this.hideImage())
    this.pad.addEventListener("endStroke", () => this.save())
    if (this.readOnlyValue) this.pad.off()
    // Again when its size changes, also from hidden (0 × 0) to shown
    this.resized = new ResizeObserver(() => this.resize())
    this.resized.observe(this.canvasTarget)
    this.outside = (event) => { if (!this.element.contains(event.target)) this.close() }
    this.escape = (event) => { if (event.key === "Escape") this.close() }
    window.addEventListener("click", this.outside)
    window.addEventListener("keydown", this.escape)
  }

  disconnect() {
    window.removeEventListener("click", this.outside)
    window.removeEventListener("keydown", this.escape)
    this.resized?.disconnect()
    this.pad?.off()
    this.pad = null
  }

  // The canvas in device pixels, its strokes in CSS pixels, as signature_pad
  // has it
  size() {
    const ratio = Math.max(window.devicePixelRatio || 1, 1)
    this.canvasTarget.width = this.canvasTarget.offsetWidth * ratio
    this.canvasTarget.height = this.canvasTarget.offsetHeight * ratio
    this.canvasTarget.getContext("2d").scale(ratio, ratio)
  }

  resize() {
    const width = this.canvasTarget.offsetWidth * Math.max(window.devicePixelRatio || 1, 1)
    if (!this.pad || width === this.canvasTarget.width) return

    const data = this.pad.toData()
    this.size()
    this.pad.fromData(data)
  }

  toggle() {
    this.menuTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.menuTarget.hidden = false
    this.moreTarget.setAttribute("aria-expanded", "true")
    this.menuTarget.querySelector("button")?.focus()
  }

  close() {
    if (!this.hasMenuTarget || this.menuTarget.hidden) return

    const focused = this.menuTarget.contains(document.activeElement)
    this.menuTarget.hidden = true
    this.moreTarget.setAttribute("aria-expanded", "false")
    if (focused) this.moreTarget.focus()
  }

  // Back to the signature there, when the pad is empty again
  undo() {
    this.close()
    const data = this.pad.toData()
    data.pop()
    this.pad.fromData(data)
    if (data.length > 0) return this.save()

    if (this.hasImageTarget && !(this.hasRemoveTarget && this.removeTarget.value === "1")) this.imageTarget.hidden = false
    this.empty()
  }

  clear() {
    this.close()
    this.pad.clear()
    if (this.hasImageTarget && !this.imageTarget.hidden && this.hasRemoveTarget) {
      this.hideImage()
      this.removeTarget.value = "1"
    }
    this.empty()
  }

  hideImage() {
    if (this.hasImageTarget) this.imageTarget.hidden = true
  }

  save() {
    const file = new File([this.pad.toSVG()], "signature.svg", { type: "image/svg+xml" })
    const files = new DataTransfer()
    files.items.add(file)
    this.fileTarget.files = files.files
    if (this.hasRemoveTarget) this.removeTarget.value = "0"
    this.changed()
  }

  empty() {
    this.fileTarget.files = new DataTransfer().files
    this.changed()
  }

  changed() {
    this.fileTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
