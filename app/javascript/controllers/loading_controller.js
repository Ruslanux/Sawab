import { Controller } from "@hotwired/stimulus"

// Handles loading states with skeleton placeholders
// Usage: data-controller="loading" on a container
//        data-loading-target="content" on the actual content
//        data-loading-target="skeleton" on the skeleton placeholder

export default class extends Controller {
  static targets = ["content", "skeleton"]

  connect() {
    // Listen for Turbo events
    document.addEventListener("turbo:before-fetch-request", this.showLoading.bind(this))
    document.addEventListener("turbo:before-fetch-response", this.hideLoading.bind(this))
    document.addEventListener("turbo:frame-load", this.hideLoading.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:before-fetch-request", this.showLoading.bind(this))
    document.removeEventListener("turbo:before-fetch-response", this.hideLoading.bind(this))
    document.removeEventListener("turbo:frame-load", this.hideLoading.bind(this))
  }

  showLoading(event) {
    // Only show loading if this controller's element is involved
    if (this.element.contains(event.target) || event.target.contains(this.element)) {
      if (this.hasSkeletonTarget) {
        this.skeletonTarget.classList.remove("hidden")
      }
      if (this.hasContentTarget) {
        this.contentTarget.classList.add("opacity-50", "pointer-events-none")
      }
    }
  }

  hideLoading(event) {
    if (this.hasSkeletonTarget) {
      this.skeletonTarget.classList.add("hidden")
    }
    if (this.hasContentTarget) {
      this.contentTarget.classList.remove("opacity-50", "pointer-events-none")
    }
  }

  // Manual trigger methods
  start() {
    this.showLoading({ target: this.element })
  }

  stop() {
    this.hideLoading({ target: this.element })
  }
}
