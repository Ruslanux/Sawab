import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay", "openIcon", "closeIcon"]

  connect() {
    // Close sidebar on escape key
    document.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  toggle() {
    if (this.sidebarTarget.classList.contains("-translate-x-full")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.sidebarTarget.classList.remove("-translate-x-full")
    this.overlayTarget.classList.remove("hidden")
    this.openIconTarget.classList.add("hidden")
    this.closeIconTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden", "md:overflow-auto")
  }

  close() {
    this.sidebarTarget.classList.add("-translate-x-full")
    this.overlayTarget.classList.add("hidden")
    this.openIconTarget.classList.remove("hidden")
    this.closeIconTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  // Close when clicking outside on mobile
  clickOutside(event) {
    this.close()
  }
}
