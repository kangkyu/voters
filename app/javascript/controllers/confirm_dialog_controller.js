import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Shows every data-turbo-confirm prompt in the layout's <dialog> instead of the browser's confirm box.
// Optional on the form: data-confirm-detail (a second, lighter line) and data-confirm-button (label; the
// button's own text, already in the page's language, by default).
// The form submits only when that button is pressed; Cancel, Escape or clicking outside keeps it unsent.
export default class extends Controller {
  static targets = ["message", "detail", "button"]

  connect() {
    this.defaultButtonLabel = this.buttonTarget.textContent
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
    this.buttonTarget.textContent = form?.dataset.confirmButton || this.defaultButtonLabel

    this.element.returnValue = ""
    this.element.showModal()
    return new Promise((resolve) => { this.resolve = resolve })
  }

  // Fires on confirm, Cancel and Escape alike; only the confirm button sets the return value
  closed() {
    this.resolve?.(this.element.returnValue === "submit")
    this.resolve = null
  }

  // A click on the backdrop lands on the <dialog> itself
  backdropClick(event) {
    if (event.target === this.element) this.element.close()
  }
}
