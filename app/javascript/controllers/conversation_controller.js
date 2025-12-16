import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["messages", "input", "form", "submit"]
  static values = {
    id: Number, // <-- ИЗМЕНЕНИЕ 1: 'conversationId' стал 'id'
    currentUserId: Number 
  }

  connect() {
    console.log("🔌 Conversation controller connecting...")
    // v-- ИЗМЕНЕНИЕ 2: 'conversationIdValue' стал 'idValue'
    console.log("  conversationId:", this.idValue) 
    console.log("  currentUserId:", this.currentUserIdValue)
    
    const conversationId = this.idValue // <-- ИЗМЕНЕНИЕ 3: 'conversationIdValue' стал 'idValue'
    const currentUserId = this.currentUserIdValue
    
    if (!conversationId || conversationId === 0) {
      console.error("❌ Invalid conversation ID:", conversationId)
      return
    }
    
    this.conversationId = conversationId // (можно оставить это имя для локального свойства)
    this.currentUserId = currentUserId
    this.scrollToBottom()
    
    console.log("📤 Creating subscription with:", {
      channel: "ConversationChannel",
      id: conversationId
    })
    
    this.subscription = consumer.subscriptions.create(
      {
        channel: "ConversationChannel",
        id: conversationId
      },
      {
        connected: () => {
          console.log("✅ Successfully connected to ConversationChannel")
          console.log("📡 Streaming from conversation_" + conversationId)
        },
        
        disconnected: () => {
          console.log("❌ Disconnected from ConversationChannel")
        },
        
        received: (data) => {
          console.log("📨 Received new message data:")
          console.log(data)

          Turbo.renderStreamMessage(data)
          
          setTimeout(() => {
            console.log("🎨 Applying styles and scrolling...")
            this.applyMessageStyles()
            this.scrollToBottom()
          }, 100)
        }
      }
    )
  }

  disconnect() {
    console.log("🔌 Disconnecting conversation controller")
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.formTarget.requestSubmit()
    }
  }

  clearForm(event) {
    if (event.detail.success) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
    }
  }

  applyMessageStyles() {
    const messagesContainer = document.getElementById('messages')
    if (!messagesContainer) {
      console.warn("⚠️ Messages container not found")
      return
    }
    
    const currentUserId = this.currentUserId
    const messages = messagesContainer.querySelectorAll('[data-message-id]')
    
    console.log(`🎨 Applying styles to ${messages.length} messages for user ${currentUserId}`)
    
    messages.forEach(messageEl => {
      const messageUserId = parseInt(messageEl.dataset.userId)
      const isCurrentUser = messageUserId === currentUserId
      
      if (isCurrentUser) {
        messageEl.classList.remove('justify-start')
        messageEl.classList.add('justify-end')
      } else {
        messageEl.classList.remove('justify-end')
        messageEl.classList.add('justify-start')
      }
      
      const bubble = messageEl.querySelector('.px-4.py-2')
      if (bubble) {
        if (isCurrentUser) {
          bubble.classList.remove('bg-gray-200', 'text-gray-900', 'rounded-bl-none')
          bubble.classList.add('bg-blue-600', 'text-white', 'rounded-br-none')
        } else {
          bubble.classList.remove('bg-blue-600', 'text-white', 'rounded-br-none')
          bubble.classList.add('bg-gray-200', 'text-gray-900', 'rounded-bl-none')
        }
      }
    })
  }
}
