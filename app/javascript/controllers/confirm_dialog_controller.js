import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Shows data-turbo-confirm prompts in this page's <dialog> instead of the browser's confirm box.
// The form submits only when "Submit" is pressed; Cancel, Escape or clicking outside keeps it unsent.
export default class extends Controller {
  static targets = ["message", "detail"]

  connect() {
    this.previousConfirm = Turbo.config.forms.confirm
    Turbo.config.forms.confirm = (message, form) => this.ask(message, form)
  }

  disconnect() {
    Turbo.config.forms.confirm = this.previousConfirm
    this.resolve?.(false)
  }

  ask(message, form) {
    this.messageTarget.textContent = message
    const detail = form?.dataset.confirmDetail || ""
    this.detailTarget.textContent = detail
    this.detailTarget.hidden = !detail

    this.element.returnValue = ""
    this.element.showModal()
    return new Promise((resolve) => { this.resolve = resolve })
  }

  // Fires on Submit, Cancel and Escape alike; only Submit sets the return value
  closed() {
    this.resolve?.(this.element.returnValue === "submit")
    this.resolve = null
  }

  // A click on the backdrop lands on the <dialog> itself
  backdropClick(event) {
    if (event.target === this.element) this.element.close()
  }
}
