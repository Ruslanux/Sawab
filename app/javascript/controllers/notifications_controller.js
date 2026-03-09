import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["counter", "dropdown", "list", "button"]
  static values = { 
    userId: Number,
    count: { type: Number, default: 0 }
  }

  connect() {
    console.log("Notifications controller connected")
    
    if (this.userIdValue) {
      this.subscription = createConsumer().subscriptions.create(
        { channel: "NotificationsChannel" },
        {
          connected: this._connected.bind(this),
          disconnected: this._disconnected.bind(this),
          received: this._received.bind(this)
        }
      )
    }
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  toggleDropdown(event) {
    event.preventDefault()
    const isHidden = this.dropdownTarget.classList.toggle("hidden")
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", String(!isHidden))
    }
  }

  closeDropdown(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden")
      if (this.hasButtonTarget) {
        this.buttonTarget.setAttribute("aria-expanded", "false")
      }
    }
  }

  markAsRead(event) {
    const notificationId = event.currentTarget.dataset.notificationId
    const url = event.currentTarget.dataset.url
    
    fetch(`/notifications/${notificationId}/mark_as_read`, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    }).then(response => {
      if (response.ok && url) {
        window.location.href = url
      }
    })
  }

  markAllAsRead(event) {
    event.preventDefault()
    
    fetch('/notifications/mark_all_as_read', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    }).then(response => {
      if (response.ok) {
        this.updateCounter(0)
        // Обновляем UI - убираем индикаторы непрочитанных
        this.listTarget.querySelectorAll('.unread-indicator').forEach(el => el.remove())
      }
    })
  }

  // Private methods

  _connected() {
    console.log("Connected to NotificationsChannel")
  }

  _disconnected() {
    console.log("Disconnected from NotificationsChannel")
  }

  _received(data) {
    console.log("Received notification:", data)
    
    // Увеличиваем счётчик
    this.updateCounter(this.countValue + 1)
    
    // Показываем toast уведомление (опционально)
    this.showToast(data)
  }

  updateCounter(count) {
    this.countValue = count
    
    if (this.hasCounterTarget) {
      if (count > 0) {
        this.counterTarget.textContent = count > 99 ? '99+' : count
        this.counterTarget.classList.remove('hidden')
      } else {
        this.counterTarget.classList.add('hidden')
      }
    }
  }

  showToast(data) {
    const toast = document.createElement('div')
    toast.className = 'fixed top-4 right-4 bg-white shadow-lg rounded-lg p-4 max-w-sm z-50 border border-gray-200'

    const messageText = document.createTextNode(data.message || 'У вас новое уведомление')

    const icon = document.createElement('div')
    icon.className = 'flex-shrink-0'
    icon.innerHTML = '<svg class="h-6 w-6 text-blue-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" /></svg>'

    const title = document.createElement('p')
    title.className = 'text-sm font-medium text-gray-900'
    title.textContent = 'Новое уведомление'

    const body = document.createElement('p')
    body.className = 'mt-1 text-sm text-gray-500'
    body.appendChild(messageText)

    const textWrap = document.createElement('div')
    textWrap.className = 'ml-3 w-0 flex-1'
    textWrap.appendChild(title)
    textWrap.appendChild(body)

    const closeBtn = document.createElement('button')
    closeBtn.className = 'inline-flex text-gray-400 hover:text-gray-500'
    closeBtn.innerHTML = '<span class="sr-only">Close</span><svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" /></svg>'
    closeBtn.addEventListener('click', () => toast.remove())

    const closeWrap = document.createElement('div')
    closeWrap.className = 'ml-4 flex-shrink-0 flex'
    closeWrap.appendChild(closeBtn)

    const inner = document.createElement('div')
    inner.className = 'flex items-start'
    inner.appendChild(icon)
    inner.appendChild(textWrap)
    inner.appendChild(closeWrap)

    toast.appendChild(inner)
    document.body.appendChild(toast)

    // Автоматически убираем через 5 секунд
    setTimeout(() => {
      toast.style.transition = 'opacity 0.3s'
      toast.style.opacity = '0'
      setTimeout(() => toast.remove(), 300)
    }, 5000)
  }
}
