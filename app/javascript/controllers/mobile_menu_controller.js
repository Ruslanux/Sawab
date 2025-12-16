import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "overlay", "openIcon", "closeIcon"]

  connect() {
    // Close menu on escape key
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
    this.enableScroll()
  }

  toggle() {
    if (this.menuTarget.classList.contains("translate-x-full")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove("translate-x-full")
    this.menuTarget.classList.add("translate-x-0")
    this.overlayTarget.classList.remove("opacity-0", "pointer-events-none")
    this.overlayTarget.classList.add("opacity-100")
    this.openIconTarget.classList.add("hidden")
    this.closeIconTarget.classList.remove("hidden")
    this.disableScroll()
  }

  close() {
    this.menuTarget.classList.add("translate-x-full")
    this.menuTarget.classList.remove("translate-x-0")
    this.overlayTarget.classList.add("opacity-0", "pointer-events-none")
    this.overlayTarget.classList.remove("opacity-100")
    this.openIconTarget.classList.remove("hidden")
    this.closeIconTarget.classList.add("hidden")
    this.enableScroll()
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  disableScroll() {
    document.body.style.overflow = "hidden"
  }

  enableScroll() {
    document.body.style.overflow = ""
  }
}
