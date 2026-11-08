# Pins for form_components. The host app registers the controllers with:
# import { registerFormComponents } from "form_components"

pin "form_components", to: "form_components/application.js"
pin_all_from FormComponents::Engine.root.join("app/components/form_components"), under: "form_components/components", to: "form_components"
pin "form_components/jscolorpicker", to: "form_components/jscolorpicker/colorpicker.js"
