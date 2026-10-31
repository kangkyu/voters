import { Controller } from "@hotwired/stimulus"

// Copies the source text to the clipboard
export default class extends Controller {
  static targets = ["source", "button"]
  static values = { copied: { type: String, default: "Copied!" } }

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.textContent.trim()).then(() => {
      const label = this.buttonTarget.textContent
      this.buttonTarget.textContent = this.copiedValue
      setTimeout(() => { this.buttonTarget.textContent = label }, 2000)
    })
  }
}
