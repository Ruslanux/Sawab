import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, 4000)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    if (!this.element) return
    
    // Плавное исчезновение
    this.element.style.opacity = "0"
    this.element.style.transform = "translateX(100%)"
    
    // Удаляем после анимации
    setTimeout(() => {
      if (this.element) {
        this.element.remove()
      }
    }, 500)
  }
}
   