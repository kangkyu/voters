import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu", "openIcon", "closeIcon"];

  toggle() {
    const hidden = this.menuTarget.classList.toggle("hidden");
    this.openIconTarget.classList.toggle("hidden", !hidden);
    this.closeIconTarget.classList.toggle("hidden", hidden);
    this.element.querySelector("button").setAttribute("aria-expanded", !hidden);
  }
}
