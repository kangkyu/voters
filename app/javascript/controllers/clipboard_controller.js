import { Controller } from "@hotwired/stimulus"

// Copies the source text to the clipboard
export default class extends Controller {
  static targets = ["source", "button"]

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.textContent.trim()).then(() => {
      const label = this.buttonTarget.textContent
      this.buttonTarget.textContent = "Copied!"
      setTimeout(() => { this.buttonTarget.textContent = label }, 2000)
    })
  }
}
