// Registers the components' Stimulus controllers with the host's
// application:
//
//   import { registerFormComponents } from "form_components"
//   registerFormComponents(window.Stimulus)
import NestedFormController from "form_components/components/nested_form/component_controller"
import ColorFieldController from "form_components/components/color_field/component_controller"

export function registerFormComponents(application) {
  application.register("form-components--nested-form", NestedFormController)
  application.register("form-components--color-field", ColorFieldController)
}
