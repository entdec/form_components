// Bundles the components' third-party JavaScript into one ESM file each, so
// importmap can pin them without chasing CDN chunk files: the rich text
// area's Tiptap and Active Storage's DirectUpload, the code editor's
// CodeMirror with its languages, the signature field's signature_pad.
import { build } from "esbuild"
import { readFileSync } from "node:fs"

const out = new URL("../../vendor/javascript/form_components/", import.meta.url).pathname
const version = (name) => JSON.parse(readFileSync(new URL(`node_modules/${name}/package.json`, import.meta.url))).version

const bundles = {
  "tiptap.js": {
    banner: `@tiptap/core ${version("@tiptap/core")}, @tiptap/starter-kit, @tiptap/extension-image, @tiptap/extension-text-align, @tiptap/extensions (MIT); @rails/activestorage ${version("@rails/activestorage")} (MIT)`,
    contents: [
      'export { Editor } from "@tiptap/core"',
      'export { StarterKit } from "@tiptap/starter-kit"',
      'export { Image } from "@tiptap/extension-image"',
      'export { TextAlign } from "@tiptap/extension-text-align"',
      'export { Placeholder } from "@tiptap/extensions"',
      'export { DirectUpload } from "@rails/activestorage"'
    ].join("\n")
  },
  "codemirror.js": {
    banner: `codemirror ${version("codemirror")}, @codemirror/state, @codemirror/view and its languages (MIT)`,
    contents: [
      'export { basicSetup } from "codemirror"',
      'export { EditorState } from "@codemirror/state"',
      'export { EditorView } from "@codemirror/view"',
      'export { sql } from "@codemirror/lang-sql"',
      'export { json } from "@codemirror/lang-json"',
      'export { yaml } from "@codemirror/lang-yaml"',
      'export { liquid } from "@codemirror/lang-liquid"',
      'export { markdown } from "@codemirror/lang-markdown"',
      'export { javascript } from "@codemirror/lang-javascript"',
      'export { html } from "@codemirror/lang-html"',
      'export { css } from "@codemirror/lang-css"'
    ].join("\n")
  },
  "signature_pad.js": {
    banner: `signature_pad ${version("signature_pad")} (MIT)`,
    contents: 'export { default } from "signature_pad"'
  }
}

for (const [file, { banner, contents }] of Object.entries(bundles)) {
  await build({
    stdin: { contents, resolveDir: new URL(".", import.meta.url).pathname, loader: "js" },
    bundle: true,
    format: "esm",
    minify: true,
    target: "es2020",
    platform: "browser",
    define: { "process.env.NODE_ENV": '"production"', global: "globalThis" },
    banner: { js: `/* ${banner}. Built by script/vendor/build.mjs */` },
    outfile: out + file,
    logLevel: "warning"
  })
  console.log(`wrote vendor/javascript/form_components/${file}`)
}
