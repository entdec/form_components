// Bundles the rich text area's third-party JavaScript, Tiptap and Active
// Storage's DirectUpload, into one ESM file, so importmap can pin it without
// chasing CDN chunk files.
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
