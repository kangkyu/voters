import { Controller } from "@hotwired/stimulus"

// Shows the content only while the checkbox is ticked, and disables its fields
// while hidden so they're neither required nor submitted
export default class extends Controller {
  static targets = ["toggle", "content"]

  connect() {
    this.toggle()
  }

  toggle() {
    const visible = this.toggleTarget.checked
    this.contentTarget.hidden = !visible
    this.contentTarget.querySelectorAll("input, select, textarea").forEach(input => input.disabled = !visible)
  }
}
