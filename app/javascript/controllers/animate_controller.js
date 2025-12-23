import { Controller } from "@hotwired/stimulus"

// Handles scroll-based animations using Intersection Observer
// Usage: data-controller="animate"
//        data-animate-class="animate-fade-in-up" (optional, default is animate-fade-in-up)
//        data-animate-threshold="0.1" (optional, 0-1, default is 0.1)
//        data-animate-delay="100" (optional, ms delay)

export default class extends Controller {
  static values = {
    class: { type: String, default: "animate-fade-in-up" },
    threshold: { type: Number, default: 0.1 },
    delay: { type: Number, default: 0 }
  }

  connect() {
    // Initially hide element
    this.element.style.opacity = "0"

    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            this.animate()
            this.observer.unobserve(entry.target)
          }
        })
      },
      {
        threshold: this.thresholdValue,
        rootMargin: "0px 0px -50px 0px"
      }
    )

    this.observer.observe(this.element)
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  animate() {
    if (this.delayValue > 0) {
      setTimeout(() => {
        this.applyAnimation()
      }, this.delayValue)
    } else {
      this.applyAnimation()
    }
  }

  applyAnimation() {
    this.element.style.opacity = ""
    this.element.classList.add(this.classValue)
  }
}
