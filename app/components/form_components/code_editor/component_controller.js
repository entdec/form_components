import { Controller } from "@hotwired/stimulus"

// A CodeMirror editor on the text area's code, which it keeps up to date,
// with an input event as typing in the text area would. CodeMirror is loaded
// when the first editor connects.
export default class extends Controller {
  static targets = ["editor", "input"]
  static values = { lang: String, height: String, readOnly: Boolean, attributes: Object }

  async connect() {
    const codemirror = await import("form_components/codemirror")
    if (!this.element.isConnected || this.editor) return

    const { EditorState, EditorView, basicSetup } = codemirror
    const language = codemirror[this.langValue]
    this.editorTarget.replaceChildren()
    this.editor = new EditorView({
      doc: this.inputTarget.value,
      parent: this.editorTarget,
      extensions: [
        basicSetup,
        EditorView.lineWrapping,
        EditorView.theme({ "&": { height: this.heightValue }, ".cm-scroller": { overflow: "auto" } }),
        EditorView.contentAttributes.of(this.attributesValue),
        EditorState.readOnly.of(this.readOnlyValue),
        EditorView.editable.of(!this.readOnlyValue),
        ...(language ? [language()] : []),
        EditorView.updateListener.of((update) => { if (update.docChanged) this.save() })
      ]
    })
  }

  disconnect() {
    this.editor?.destroy()
    this.editor = null
  }

  save() {
    this.inputTarget.value = this.editor.state.doc.toString()
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  focus() {
    this.editor?.focus()
  }
}
