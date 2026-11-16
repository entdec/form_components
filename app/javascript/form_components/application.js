// Registers the components' Stimulus controllers with the host's
// application:
//
//   import { registerFormComponents } from "form_components"
//   registerFormComponents(window.Stimulus)
import NestedFormController from "form_components/components/nested_form/component_controller"
import CodeEditorController from "form_components/components/code_editor/component_controller"
import CountryFieldController from "form_components/components/country_field/component_controller"
import ColorFieldController from "form_components/components/color_field/component_controller"
import TelephoneFieldController from "form_components/components/telephone_field/component_controller"
import SignatureFieldController from "form_components/components/signature_field/component_controller"
import RichTextAreaController from "form_components/components/rich_text_area/component_controller"
import DependsOnController from "form_components/components/select/depends_on_controller"

export function registerFormComponents(application) {
  application.register("form-components--nested-form", NestedFormController)
  application.register("form-components--code-editor", CodeEditorController)
  application.register("form-components--color-field", ColorFieldController)
  application.register("form-components--country-field", CountryFieldController)
  application.register("form-components--telephone-field", TelephoneFieldController)
  application.register("form-components--rich-text-area", RichTextAreaController)
  application.register("form-components--signature-field", SignatureFieldController)
  application.register("form-components--depends-on", DependsOnController)
}
