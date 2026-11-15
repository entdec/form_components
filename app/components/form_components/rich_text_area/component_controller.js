import { Controller } from "@hotwired/stimulus"
import { DirectUpload, Editor, Image, Placeholder, StarterKit, TextAlign } from "form_components/tiptap"

// A Tiptap editor on the text area's HTML, which it keeps up to date ("" when
// empty). The toolbar's buttons (component.rb) run their command and show
// whether it's active. It allows only the formatting of the toolbar.
//
// Images are uploaded with Active Storage's direct uploads: shown at once,
// and as the blob's URL when it's stored. For an Action Text attribute an
// image is an attachment (<action-text-attachment sgid="…">). A form
// submitted while images are uploading waits for them and then goes on.
export default class extends Controller {
  static targets = ["editor", "input", "toolbar", "button", "heading", "linkMenu", "linkInput", "file"]
  static values = {
    toolbar: Array,
    attributes: Object,
    placeholder: String,
    actionText: Boolean,
    directUploadUrl: String,
    blobUrlTemplate: String,
    disabled: Boolean
  }

  connect() {
    this.uploads = new Map()
    this.editorTarget.replaceChildren()
    this.editor = new Editor({
      element: this.editorTarget,
      content: this.inputTarget.value,
      editable: !this.disabledValue,
      extensions: this.extensions(),
      editorProps: {
        attributes: this.attributesValue,
        handleKeyDown: (view, event) => this.keydown(event),
        handlePaste: (view, event) => this.uploadFiles(event.clipboardData?.files),
        handleDrop: (view, event, slice, moved) => {
          if (moved) return false
          const position = view.posAtCoords({ left: event.clientX, top: event.clientY })?.pos
          return this.uploadFiles(event.dataTransfer?.files, position)
        }
      },
      onUpdate: () => this.save(),
      onTransaction: () => this.updateToolbar()
    })
    this.form = this.element.closest("form")
    this.submit = (event) => this.waitForUploads(event)
    this.form?.addEventListener("submit", this.submit)
    this.updateToolbar()
  }

  disconnect() {
    this.form?.removeEventListener("submit", this.submit)
    this.editor?.destroy()
    this.editor = null
  }

  has(name) {
    return this.toolbarValue.includes(name)
  }

  // StarterKit with only the toolbar's formatting, its lists' items and the
  // editor's essentials
  extensions() {
    const on = (name, options = {}) => (this.has(name) ? options : false)
    const lists = this.has("bullet_list") || this.has("ordered_list")
    const extensions = [
      StarterKit.configure({
        heading: on("heading", { levels: [1, 2, 3] }),
        bold: on("bold"),
        italic: on("italic"),
        underline: on("underline"),
        strike: on("strike"),
        code: on("code"),
        link: on("link", { openOnClick: false, autolink: true, defaultProtocol: "https", HTMLAttributes: { target: null, rel: null } }),
        bulletList: on("bullet_list"),
        orderedList: on("ordered_list"),
        listItem: lists ? {} : false,
        listKeymap: lists ? {} : false,
        blockquote: on("blockquote"),
        codeBlock: on("code_block"),
        horizontalRule: on("horizontal_rule")
      })
    ]
    const alignments = ["left", "center", "right", "justify"].filter((alignment) => this.has(`align_${alignment}`))
    if (alignments.length > 0) extensions.push(TextAlign.configure({ types: ["heading", "paragraph"], alignments }))
    if (this.has("image")) extensions.push(UploadedImage)
    if (this.placeholderValue) extensions.push(Placeholder.configure({ placeholder: this.placeholderValue }))
    return extensions
  }

  // The editor's HTML in the text area, without images still uploading or the
  // empty paragraph Tiptap keeps at the end, and with an Action Text
  // attribute's images as attachments
  save() {
    const template = document.createElement("template")
    template.innerHTML = this.editor.isEmpty ? "" : this.editor.getHTML()
    template.content.querySelectorAll("img[data-upload]").forEach((img) => img.remove())
    while (template.content.lastElementChild?.matches("p:empty")) template.content.lastElementChild.remove()
    if (this.actionTextValue) {
      template.content.querySelectorAll("img[data-sgid]").forEach((img) => img.replaceWith(this.attachment(img)))
    }
    this.inputTarget.value = template.innerHTML
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  attachment(img) {
    const attachment = document.createElement("action-text-attachment")
    const attributes = { sgid: img.dataset.sgid, "content-type": img.dataset.contentType, url: img.getAttribute("src"), filename: img.dataset.filename, caption: img.alt }
    for (const [name, value] of Object.entries(attributes)) if (value) attachment.setAttribute(name, value)
    return attachment
  }

  // The label's and the browser's check's focus, in the editor
  focus() {
    this.editor?.commands.focus()
  }

  keepFocus(event) {
    event.preventDefault()
  }

  run(event) {
    const command = event.currentTarget.dataset.command
    const chain = () => this.editor.chain().focus()
    const commands = {
      bold: () => chain().toggleBold().run(),
      italic: () => chain().toggleItalic().run(),
      underline: () => chain().toggleUnderline().run(),
      strike: () => chain().toggleStrike().run(),
      code: () => chain().toggleCode().run(),
      bullet_list: () => chain().toggleBulletList().run(),
      ordered_list: () => chain().toggleOrderedList().run(),
      blockquote: () => chain().toggleBlockquote().run(),
      code_block: () => chain().toggleCodeBlock().run(),
      horizontal_rule: () => chain().setHorizontalRule().run(),
      align_left: () => chain().setTextAlign("left").run(),
      align_center: () => chain().setTextAlign("center").run(),
      align_right: () => chain().setTextAlign("right").run(),
      align_justify: () => chain().setTextAlign("justify").run(),
      undo: () => chain().undo().run(),
      redo: () => chain().redo().run(),
      link: () => this.openLink(),
      image: () => this.fileTarget.click()
    }
    commands[command]?.()
  }

  heading(event) {
    const level = Number(event.target.value)
    const chain = this.editor.chain().focus()
    level ? chain.setHeading({ level }).run() : chain.setParagraph().run()
  }

  updateToolbar() {
    if (!this.editor) return
    const editor = this.editor
    const active = {
      bold: () => editor.isActive("bold"),
      italic: () => editor.isActive("italic"),
      underline: () => editor.isActive("underline"),
      strike: () => editor.isActive("strike"),
      code: () => editor.isActive("code"),
      link: () => editor.isActive("link"),
      bullet_list: () => editor.isActive("bulletList"),
      ordered_list: () => editor.isActive("orderedList"),
      blockquote: () => editor.isActive("blockquote"),
      code_block: () => editor.isActive("codeBlock"),
      align_left: () => editor.isActive({ textAlign: "left" }),
      align_center: () => editor.isActive({ textAlign: "center" }),
      align_right: () => editor.isActive({ textAlign: "right" }),
      align_justify: () => editor.isActive({ textAlign: "justify" })
    }
    const disabled = {
      undo: () => !editor.can().undo(),
      redo: () => !editor.can().redo()
    }
    for (const button of this.buttonTargets) {
      const command = button.dataset.command
      if (active[command]) button.setAttribute("aria-pressed", active[command]().toString())
      button.disabled = this.disabledValue || Boolean(disabled[command]?.())
    }
    if (this.hasHeadingTarget) {
      const level = [1, 2, 3].find((level) => editor.isActive("heading", { level }))
      this.headingTarget.value = String(level || 0)
      this.headingTarget.disabled = this.disabledValue
    }
  }

  keydown(event) {
    if (this.has("link") && (event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      this.openLink()
      return true
    }
    return false
  }

  // Links

  openLink() {
    this.linkInputTarget.value = this.editor.getAttributes("link").href || ""
    this.linkMenuTarget.hidden = false
    this.linkInputTarget.focus()
  }

  closeLink({ focus = true } = {}) {
    if (!this.hasLinkMenuTarget || this.linkMenuTarget.hidden) return
    this.linkMenuTarget.hidden = true
    if (focus) this.editor.commands.focus()
  }

  // The URL on the selected text or the link at the caret, else as a link
  // of its own; an empty one removes it
  applyLink() {
    const href = this.linkInputTarget.value.trim()
    if (!href) return this.removeLink()

    const { empty } = this.editor.state.selection
    const chain = this.editor.chain().focus().extendMarkRange("link")
    if (empty && !this.editor.isActive("link")) {
      chain.insertContent({ type: "text", text: href, marks: [{ type: "link", attrs: { href } }] }).run()
    } else {
      chain.setLink({ href }).run()
    }
    this.closeLink()
  }

  removeLink() {
    this.editor.chain().focus().extendMarkRange("link").unsetLink().run()
    this.closeLink()
  }

  linkKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.applyLink()
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.closeLink()
    }
  }

  clickOutside(event) {
    if (this.hasLinkMenuTarget && !this.linkMenuTarget.contains(event.target) && !event.target.closest?.("[data-command=link]")) {
      this.closeLink({ focus: false })
    }
  }

  // Images

  pick() {
    this.uploadFiles(this.fileTarget.files)
    this.fileTarget.value = ""
  }

  // Whether there were images to upload, at the position or the selection
  uploadFiles(files, position) {
    const images = [...(files || [])].filter((file) => file.type.startsWith("image/"))
    if (!this.has("image") || !this.directUploadUrlValue || images.length === 0) return false

    for (const file of images) {
      const id = Math.random().toString(36).slice(2)
      const src = URL.createObjectURL(file)
      // An attachment's caption is the file's name unless it has one
      const image = { type: "image", attrs: { src, alt: this.actionTextValue ? null : file.name, upload: id } }
      const chain = this.editor.chain().focus()
      position === undefined ? chain.insertContent(image).run() : chain.insertContentAt(position, image).run()
      this.upload(file, id, src)
    }
    return true
  }

  upload(file, id, src) {
    const done = new Promise((resolve) => {
      new DirectUpload(file, this.directUploadUrlValue, this).create((error, blob) => {
        URL.revokeObjectURL(src)
        if (error) {
          this.updateImage(id, null)
          const event = this.dispatch("upload-error", { detail: { error, file }, cancelable: true })
          if (!event.defaultPrevented) alert(error)
        } else {
          const attachment = this.actionTextValue ? { sgid: blob.attachable_sgid, contentType: blob.content_type, filename: blob.filename } : {}
          this.updateImage(id, { src: this.blobUrl(blob), ...attachment })
        }
        resolve()
      })
    })
    this.uploads.set(id, done)
    done.then(() => this.uploads.delete(id))
  }

  blobUrl(blob) {
    return this.blobUrlTemplateValue.replace(":signed_id", blob.signed_id).replace(":filename", encodeURIComponent(blob.filename))
  }

  // The image of an upload, with the blob's attributes, or removed
  updateImage(id, attributes) {
    if (!this.editor) return
    const { state } = this.editor
    state.doc.descendants((node, position) => {
      if (node.type.name !== "image" || node.attrs.upload !== id) return
      const tr = attributes
        ? state.tr.setNodeMarkup(position, null, { ...node.attrs, ...attributes, upload: null })
        : state.tr.delete(position, position + node.nodeSize)
      this.editor.view.dispatch(tr.setMeta("addToHistory", false))
      return false
    })
  }

  // A form submitted while uploading: again once the uploads are done
  waitForUploads(event) {
    if (this.uploads.size === 0) return
    event.preventDefault()
    event.stopImmediatePropagation()
    const submitter = event.submitter
    Promise.all(this.uploads.values()).then(() => this.form.requestSubmit(submitter))
  }
}

// An image with an upload in progress (data-upload) or an Action Text
// attachment's sgid, content type and filename (data-sgid, …)
const UploadedImage = Image.extend({
  addAttributes() {
    const data = (name, attribute) => ({
      default: null,
      parseHTML: (element) => element.getAttribute(attribute),
      renderHTML: (attributes) => (attributes[name] ? { [attribute]: attributes[name] } : {})
    })
    return {
      ...this.parent?.(),
      upload: data("upload", "data-upload"),
      sgid: data("sgid", "data-sgid"),
      contentType: data("contentType", "data-content-type"),
      filename: data("filename", "data-filename")
    }
  }
})
