import { Controller } from "@hotwired/stimulus";

const FIELDS = "input:not([type=hidden]):not([disabled]), select:not([disabled]), textarea:not([disabled]), [contenteditable=true]";

export default class extends Controller {
    static targets = ["insertion", "template"];
    static values = {
        wrapperSelector: { type: String, default: ".nested-form-wrapper" },
        placeholder: { type: String, default: "NEW_RECORD" },
    };

    // The new item's first field gets the focus
    add(e) {
        e.preventDefault();
        const content = this.templateTarget.innerHTML.replace(
            new RegExp(this.placeholderValue, "g"),
            new Date().getTime().toString(),
        );
        const before = this.insertionTarget.previousElementSibling;
        this.insertionTarget.insertAdjacentHTML("beforebegin", content);
        for (let node = before.nextElementSibling; node !== this.insertionTarget; node = node.nextElementSibling) {
            const field = [node, ...node.querySelectorAll(FIELDS)].find((element) => element.matches(FIELDS) && element.checkVisibility());
            if (field) {
                field.focus();
                break;
            }
        }
        this.element.dispatchEvent(
            new CustomEvent("nested-form:add", { bubbles: true }),
        );
    }

    // The add button gets the focus, which was on the item's remove button
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
        this.element.querySelector(":scope > [data-action*='nested-form#add'] :is(button, a[href])")?.focus();
        this.element.dispatchEvent(
            new CustomEvent("nested-form:remove", { bubbles: true }),
        );
    }
}
