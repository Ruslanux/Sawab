import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "count"]
  static values = { max: Number }

  connect() {
    this.update()
  }

  update() {
    const current = this.inputTarget.value.length
    const remaining = this.maxValue - current
    this.countTarget.textContent = remaining
    this.countTarget.classList.toggle("text-red-500", remaining < 20)
    this.countTarget.classList.toggle("text-orange-500", remaining >= 20 && remaining < 50)
    this.countTarget.classList.toggle("text-gray-400", remaining >= 50)
  }
}
