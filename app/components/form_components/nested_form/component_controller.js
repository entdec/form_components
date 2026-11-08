import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["insertion", "template"];
    static values = {
        wrapperSelector: { type: String, default: ".nested-form-wrapper" },
        placeholder: { type: String, default: "NEW_RECORD" },
    };

    add(e) {
        e.preventDefault();
        const content = this.templateTarget.innerHTML.replace(
            new RegExp(this.placeholderValue, "g"),
            new Date().getTime().toString(),
        );
        this.insertionTarget.insertAdjacentHTML("beforebegin", content);
        this.element.dispatchEvent(
            new CustomEvent("nested-form:add", { bubbles: true }),
        );
    }

    remove(e) {
        e.preventDefault();
        const wrapper = e.target.closest(this.wrapperSelectorValue);
        if (wrapper.dataset.newRecord === "true") {
            wrapper.remove();
        } else {
            wrapper.style.display = "none";
            const input = wrapper.querySelector("input[name*='_destroy']");
            input.value = "1";
        }
        this.element.dispatchEvent(
            new CustomEvent("nested-form:remove", { bubbles: true }),
        );
    }
}
