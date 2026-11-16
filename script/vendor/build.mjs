// Bundles the components' third-party JavaScript into one ESM file each, so
// importmap can pin them without chasing CDN chunk files: the rich text
// area's Tiptap and Active Storage's DirectUpload, the code editor's
// CodeMirror with its languages, the signature field's signature_pad.
import { build } from "esbuild"
import { copyFileSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs"

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

// flag-icons' flags (4:3), for the telephone and country fields: the SVGs as
// the engine's images, and their classes (.fi .fi-nl) pointing at them, by a
// path Propshaft resolves from the host's stylesheet
const flags = new URL("node_modules/flag-icons/flags/4x3/", import.meta.url).pathname
const images = new URL("../../app/assets/images/form_components/flags/", import.meta.url).pathname
rmSync(images, { recursive: true, force: true })
mkdirSync(images, { recursive: true })
const codes = readdirSync(flags).filter((file) => file.endsWith(".svg")).map((file) => file.replace(/\.svg$/, "")).sort()
for (const code of codes) copyFileSync(flags + code + ".svg", images + code + ".svg")
writeFileSync(new URL("../../app/assets/stylesheets/form_components/flags.css", import.meta.url).pathname, [
  `/* flag-icons ${version("flag-icons")} (MIT), its 4:3 flags. Built by script/vendor/build.mjs */`,
  ".fi { position: relative; display: inline-block; width: 1.333333em; line-height: 1em; background-size: contain; background-position: 50%; background-repeat: no-repeat; }",
  ".fi::before { content: \"\\00a0\"; }",
  ...codes.map((code) => `.fi-${code} { background-image: url("form_components/flags/${code}.svg"); }`)
].join("\n") + "\n")
console.log(`wrote app/assets/images/form_components/flags (${codes.length}) and app/assets/stylesheets/form_components/flags.css`)
