import { Application } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"
import { registerFormComponents } from "form_components"
import HwComboboxController from "controllers/hw_combobox_controller"

// For the combobox's chips, which come as a Turbo Stream; the forms are sent
// without it, as the showcase renders its page in reply
window.Turbo = Turbo
Turbo.session.drive = false

window.Stimulus = Application.start()
registerFormComponents(window.Stimulus)
window.Stimulus.register("hw-combobox", HwComboboxController)
