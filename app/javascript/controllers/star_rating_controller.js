import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="star-rating"
export default class extends Controller {
  static targets = ["star", "input"]

  connect() {
    // Update stars based on any pre-selected value
    this.updateStars()

    // Add click handlers to stars
    this.starTargets.forEach((star) => {
      star.addEventListener("click", () => {
        this.selectRating(star)
      })

      // Add hover effect
      star.addEventListener("mouseenter", () => {
        this.highlightStars(star.dataset.value)
      })
    })

    // Reset hover on mouse leave
    this.element.addEventListener("mouseleave", () => {
      this.updateStars()
    })
  }

  selectRating(starElement) {
    const rating = parseInt(starElement.dataset.value)

    // Find and check the corresponding radio button
    const radioButton = starElement.querySelector('input[type="radio"]')
    if (radioButton) {
      radioButton.checked = true
    }

    this.updateStars()
  }

  highlightStars(rating) {
    const numRating = parseInt(rating)

    this.starTargets.forEach((star) => {
      const starValue = parseInt(star.dataset.value)
      const svg = star.querySelector("svg")

      if (starValue <= numRating) {
        svg.classList.remove("text-gray-300", "dark:text-gray-500")
        svg.classList.add("text-yellow-400")
      } else {
        svg.classList.remove("text-yellow-400")
        svg.classList.add("text-gray-300", "dark:text-gray-500")
      }
    })
  }

  updateStars() {
    // Find the checked radio button
    const checkedInput = this.inputTargets.find(input => input.checked)

    if (checkedInput) {
      const rating = parseInt(checkedInput.value)
      this.highlightStars(rating)
    } else {
      // No rating selected, reset all stars
      this.starTargets.forEach((star) => {
        const svg = star.querySelector("svg")
        svg.classList.remove("text-yellow-400")
        svg.classList.add("text-gray-300", "dark:text-gray-500")
      })
    }
  }
}
