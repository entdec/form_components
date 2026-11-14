import { Application } from "@hotwired/stimulus"
import { registerFormComponents } from "form_components"
import HwComboboxController from "controllers/hw_combobox_controller"

window.Stimulus = Application.start()
registerFormComponents(window.Stimulus)
window.Stimulus.register("hw-combobox", HwComboboxController)
