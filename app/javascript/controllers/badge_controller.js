import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["icon", "details"]

  connect() {
    // Убедимся, что детали изначально скрыты
    this.detailsTarget.classList.add("max-h-0", "opacity-0", "mt-0")
    // Скрываем иконку-стрелку
    this.iconTarget.classList.add("opacity-0", "group-hover:opacity-100")
  }

  toggle(event) {
    // Останавливаем "всплытие" клика, чтобы он не закрыл, например, модальное окно
    event.stopPropagation() 

    // --- 1. Анимация "Пульс" ---
    this.pulse()
    
    // --- 2. Анимация "Раскрытие" ---
    if (this.detailsTarget.classList.contains("max-h-0")) {
      // Открываем
      this.detailsTarget.classList.remove("hidden", "max-h-0", "opacity-0", "mt-0")
      this.detailsTarget.classList.add("max-h-48", "opacity-100", "mt-2") // max-h-48 - можно изменить
      this.iconTarget.classList.add("rotate-180")
    } else {
      // Закрываем
      this.detailsTarget.classList.add("max-h-0", "opacity-0", "mt-0")
      this.detailsTarget.classList.remove("max-h-48", "mt-2")
      this.iconTarget.classList.remove("rotate-180")
      
      // Добавляем 'hidden' после завершения анимации
      setTimeout(() => {
        if (this.detailsTarget.classList.contains("max-h-0")) {
          this.detailsTarget.classList.add("hidden")
        }
      }, 500) // 500ms - это 'duration-500'
    }
  }

  pulse() {
    const iconElement = this.iconTarget.closest("[data-controller='badge']").querySelector("img, svg")
    if (iconElement) {
      iconElement.classList.add("scale-125")
      setTimeout(() => {
        iconElement.classList.remove("scale-125")
      }, 200)
    }
  }
}
