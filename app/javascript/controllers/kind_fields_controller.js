import { Controller } from "@hotwired/stimulus"

// Shows only the fields for the selected agenda item kind, and disables the
// others so a value picked before switching kinds isn't submitted
export default class extends Controller {
  static targets = ["kind", "motion", "election"]

  connect() {
    this.toggle()
  }

  toggle() {
    const election = this.kindTarget.value === "election"
    this.motionTargets.forEach(field => this.#show(field, !election))
    this.electionTargets.forEach(field => this.#show(field, election))
  }

  #show(field, visible) {
    field.hidden = !visible
    field.querySelectorAll("input, select, textarea").forEach(input => input.disabled = !visible)
  }
}
