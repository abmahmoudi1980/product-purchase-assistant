<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
    <NuxtRouteAnnouncer />
    
    <div class="container mx-auto px-4 py-8">
      <!-- Header -->
      <div class="text-center mb-8">
        <h1 class="text-4xl font-bold text-gray-800 mb-2">
          Product Purchase Assistant
        </h1>
        <p class="text-gray-600 text-lg">
          Get AI-powered product recommendations from Digikala
        </p>
      </div>

      <!-- Chat Container -->
      <div class="max-w-4xl mx-auto bg-white rounded-xl shadow-lg overflow-hidden">
        <!-- Chat Messages -->
        <div 
          ref="chatContainer"
          class="h-96 overflow-y-auto p-6 space-y-4 bg-gray-50"
        >
          <!-- Welcome Message -->
          <div v-if="messages.length === 0" class="text-center text-gray-500 mt-16">
            <div class="text-6xl mb-4">🛍️</div>
            <h3 class="text-xl font-semibold mb-2">Welcome to your shopping assistant!</h3>
            <p>Ask me about any product you want to buy, and I'll help you find the best options from Digikala.</p>
            <div class="mt-4 text-sm text-gray-400">
              Try asking: "I need a new laptop for work" or "Show me the best smartphones under 20 million tomans"
            </div>
          </div>

          <!-- Chat Messages -->
          <div 
            v-for="(message, index) in messages" 
            :key="index"
            class="flex mb-4"
            :class="message.type === 'user' ? 'justify-end' : 'justify-start'"
          >
            <div 
              class="max-w-md p-3 rounded-lg shadow-md"
              :class="message.type === 'user' ? 'bg-blue-500 text-white ml-auto' : 'bg-gray-100 text-gray-800 mr-auto'"
            >
              <div v-if="message.type === 'bot'" class="flex items-start space-x-2">
                <div class="text-2xl">🤖</div>
                <div class="flex-1">
                  <div v-html="formatMessage(message.content)"></div>
                  <!-- Products Display -->
                  <div v-if="message.products && message.products.length > 0" class="mt-4">
                    <h4 class="font-semibold text-gray-700 mb-2">📦 Found Products:</h4>
                    <div class="grid gap-3">
                      <div 
                        v-for="product in message.products.slice(0, 3)" 
                        :key="product.url"
                        class="bg-white rounded-lg shadow-md p-4 border hover:shadow-lg transition-shadow text-sm"
                      >
                        <div class="flex justify-between items-start mb-2">
                          <h5 class="font-medium text-gray-800 flex-1">{{ product.name }}</h5>
                          <span class="text-green-600 font-bold text-lg">{{ product.price }}</span>
                        </div>
                        <div class="flex items-center justify-between text-xs text-gray-600">
                          <div class="flex items-center space-x-2">
                            <span class="bg-blue-100 text-blue-800 px-2 py-1 rounded">{{ product.brand }}</span>
                            <div class="flex items-center">
                              <span class="text-yellow-500">⭐</span>
                              <span class="ml-1">{{ product.rating }}</span>
                            </div>
                          </div>
                          <a 
                            :href="product.url" 
                            target="_blank" 
                            class="text-blue-500 hover:text-blue-700 underline"
                          >
                            View Product
                          </a>
                        </div>
                        <p class="text-xs text-gray-500 mt-2">{{ product.description }}</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div v-else class="flex items-start space-x-2">
                <div class="text-2xl">👤</div>
                <div>{{ message.content }}</div>
              </div>
            </div>
          </div>

          <!-- Typing Indicator -->
          <div v-if="isTyping" class="flex justify-start">
            <div class="max-w-md p-3 rounded-lg shadow-md bg-gray-100 text-gray-800 mr-auto">
              <div class="flex items-center space-x-2">
                <div class="text-2xl">🤖</div>
                <div class="flex space-x-1">
                  <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></span>
                  <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0.1s"></span>
                  <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0.2s"></span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Chat Input -->
        <div class="p-6 bg-white border-t">
          <form @submit.prevent="sendMessage" class="flex space-x-4">
            <input
              v-model="userMessage"
              type="text"
              placeholder="Ask me about any product you want to buy..."
              class="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              :disabled="isTyping"
            />
            <button
              type="submit"
              :disabled="!userMessage.trim() || isTyping"
              class="px-6 py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
            >
              <span v-if="!isTyping">Send</span>
              <span v-else>...</span>
            </button>
          </form>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="max-w-4xl mx-auto mt-6">
        <div class="text-center mb-4">
          <h3 class="text-lg font-semibold text-gray-700">Quick Actions</h3>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button
            @click="quickSearch('laptop')"
            class="p-4 bg-white rounded-lg shadow hover:shadow-md transition-shadow text-left"
          >
            <div class="text-2xl mb-2">💻</div>
            <div class="font-medium">Find Laptops</div>
            <div class="text-sm text-gray-600">Browse laptops for work and gaming</div>
          </button>
          <button
            @click="quickSearch('phone')"
            class="p-4 bg-white rounded-lg shadow hover:shadow-md transition-shadow text-left"
          >
            <div class="text-2xl mb-2">📱</div>
            <div class="font-medium">Find Smartphones</div>
            <div class="text-sm text-gray-600">Latest mobile phones and accessories</div>
          </button>
          <button
            @click="quickSearch('headphone')"
            class="p-4 bg-white rounded-lg shadow hover:shadow-md transition-shadow text-left"
          >
            <div class="text-2xl mb-2">🎧</div>
            <div class="font-medium">Find Headphones</div>
            <div class="text-sm text-gray-600">Audio equipment and accessories</div>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const config = useRuntimeConfig()

// Reactive data
const messages = ref([])
const userMessage = ref('')
const isTyping = ref(false)
const chatContainer = ref(null)

// Methods
const sendMessage = async () => {
  if (!userMessage.value.trim()) return

  const message = userMessage.value.trim()
  
  // Add user message
  messages.value.push({
    type: 'user',
    content: message,
    timestamp: new Date()
  })

  // Clear input and show typing
  userMessage.value = ''
  isTyping.value = true
  
  // Scroll to bottom
  nextTick(() => {
    scrollToBottom()
  })

  try {
    // Send to backend
    const response = await $fetch(`${config.public.apiBase}/chatbot/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: message
      })
    })

    // Add bot response
    messages.value.push({
      type: 'bot',
      content: response.response || 'Sorry, I couldn\'t process your request.',
      products: response.products || [],
      searched_for: response.searched_for,
      timestamp: new Date()
    })

  } catch (error) {
    console.error('Error sending message:', error)
    messages.value.push({
      type: 'bot',
      content: 'Sorry, I\'m having trouble connecting right now. Please try again.',
      timestamp: new Date()
    })
  } finally {
    isTyping.value = false
    nextTick(() => {
      scrollToBottom()
    })
  }
}

const quickSearch = (query) => {
  userMessage.value = `Show me the best ${query}s available`
  sendMessage()
}

const formatMessage = (content) => {
  // Simple formatting - convert newlines to <br>
  return content.replace(/\n/g, '<br>')
}

const scrollToBottom = () => {
  if (chatContainer.value) {
    chatContainer.value.scrollTop = chatContainer.value.scrollHeight
  }
}

// Page metadata
useHead({
  title: 'Product Purchase Assistant',
  meta: [
    { name: 'description', content: 'AI-powered product recommendation assistant for Digikala products' }
  ]
})
</script>
