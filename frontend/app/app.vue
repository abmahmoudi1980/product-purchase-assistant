<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 persian-text" dir="rtl">
    <NuxtRouteAnnouncer />
    
    <div class="container mx-auto px-4 py-8">
      <!-- Header -->
      <div class="text-center mb-8">
        <h1 class="text-4xl font-bold text-gray-800 mb-2 font-persian">
          دستیار خرید محصولات
        </h1>
        <p class="text-gray-600 text-lg font-persian">
          توصیه‌های محصولات هوشمند از دیجی‌کالا دریافت کنید
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
          <div v-if="messages.length === 0" class="text-center text-gray-500 mt-16 font-persian">
            <div class="text-6xl mb-4">🛍️</div>
            <h3 class="text-xl font-semibold mb-2">به دستیار خرید شما خوش آمدید!</h3>
            <p>از من درباره هر محصولی که می‌خواهید بخرید بپرسید و من بهترین گزینه‌ها را از دیجی‌کالا برایتان پیدا می‌کنم.</p>
            <div class="mt-4 text-sm text-gray-400">
              مثال: "به یک لپ تاپ جدید برای کار نیاز دارم" یا "بهترین گوشی‌های زیر ۲۰ میلیون تومان را نشان بده"
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
              class="max-w-md p-3 rounded-lg shadow-md font-persian"
              :class="message.type === 'user' ? 'bg-blue-500 text-white ml-auto' : 'bg-gray-100 text-gray-800 mr-auto'"
            >
              <div v-if="message.type === 'bot'" class="flex items-start space-x-2">
                <div class="text-2xl">🤖</div>
                <div class="flex-1">
                  <div v-html="formatMessage(message.content)"></div>
                  <!-- Products Display -->
                  <div v-if="message.products && message.products.length > 0" class="mt-4">
                    <h4 class="font-semibold text-gray-700 mb-2">📦 محصولات یافت شده:</h4>
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
                            مشاهده محصول
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
            <div class="max-w-md p-3 rounded-lg shadow-md bg-gray-100 text-gray-800 mr-auto font-persian">
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
          <form @submit.prevent="sendMessage" class="flex space-x-4 space-x-reverse">
            <button
              type="submit"
              :disabled="!userMessage.trim() || isTyping"
              class="px-6 py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors font-persian"
            >
              <span v-if="!isTyping">ارسال</span>
              <span v-else>...</span>
            </button>
            <input
              v-model="userMessage"
              type="text"
              placeholder="از من درباره هر محصولی که می‌خواهید بخرید بپرسید..."
              class="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent font-persian"
              :disabled="isTyping"
            />
          </form>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="max-w-4xl mx-auto mt-6">
        <div class="text-center mb-4">
          <h3 class="text-lg font-semibold text-gray-700 font-persian">دسترسی سریع</h3>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button
            @click="quickSearch('laptop')"
            class="p-4 bg-white rounded-lg shadow hover:shadow-md transition-shadow text-right font-persian"
          >
            <div class="text-2xl mb-2">💻</div>
            <div class="font-medium">جستجوی لپ تاپ</div>
            <div class="text-sm text-gray-600">مرور لپ تاپ‌های کاری و گیمینگ</div>
          </button>
          <button
            @click="quickSearch('phone')"
            class="p-4 bg-white rounded-lg shadow hover:shadow-md transition-shadow text-right font-persian"
          >
            <div class="text-2xl mb-2">📱</div>
            <div class="font-medium">جستجوی گوشی هوشمند</div>
            <div class="text-sm text-gray-600">جدیدترین گوشی‌ها و لوازم جانبی</div>
          </button>
          <button
            @click="quickSearch('headphone')"
            class="p-4 bg-white rounded-lg shadow hover:shadow-md transition-shadow text-right font-persian"
          >
            <div class="text-2xl mb-2">🎧</div>
            <div class="font-medium">جستجوی هدفون</div>
            <div class="text-sm text-gray-600">تجهیزات صوتی و لوازم جانبی</div>
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
      content: response.response || 'متاسفم، نتوانستم درخواست شما را پردازش کنم.',
      products: response.products || [],
      searched_for: response.searched_for,
      timestamp: new Date()
    })

  } catch (error) {
    console.error('Error sending message:', error)
    messages.value.push({
      type: 'bot',
      content: 'متاسفم، در حال حاضر مشکلی در اتصال دارم. لطفاً دوباره تلاش کنید.',
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
  userMessage.value = `بهترین ${query === 'laptop' ? 'لپ تاپ‌های' : query === 'phone' ? 'گوشی‌های' : 'هدفون‌های'} موجود را نشان بده`
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
  title: 'دستیار خرید محصولات',
  meta: [
    { name: 'description', content: 'دستیار هوشمند توصیه محصولات برای محصولات دیجی‌کالا' }
  ]
})
</script>

<style>
/* Import Persian fonts */
@import url('https://fonts.googleapis.com/css2?family=Vazirmatn:wght@100;200;300;400;500;600;700;800;900&display=swap');
@import url('https://cdn.fontcdn.ir/Font/Persian/IRANSans/IRANSansXFaNum.css');

/* Persian font settings */
* {
  font-family: 'Vazirmatn', 'IRANSansXFaNum', 'IRANSans', 'Tahoma', 'Arial', sans-serif !important;
}

body {
  direction: rtl;
  font-feature-settings: 'kern', 'liga', 'clig', 'calt';
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* Ensure Persian text is properly rendered */
.persian-text, .font-persian {
  font-family: 'Vazirmatn', 'IRANSansXFaNum', 'IRANSans', 'Tahoma', 'Arial', sans-serif !important;
  line-height: 1.8;
  letter-spacing: 0.01em;
}

/* Custom styles for the chat interface */
.chat-bubble {
  max-width: 28rem;
  padding: 0.75rem;
  border-radius: 0.5rem;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.user-message {
  background-color: #3b82f6;
  color: white;
  margin-left: auto;
}

.bot-message {
  background-color: #f3f4f6;
  color: #374151;
  margin-right: auto;
}

.product-card {
  background-color: white;
  border-radius: 0.5rem;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  padding: 1rem;
  border: 1px solid #e5e7eb;
}

.product-card:hover {
  transform: scale(1.02);
  transition: transform 0.2s;
}

.loading-dots {
  display: flex;
  gap: 0.25rem;
}

.loading-dot {
  width: 0.5rem;
  height: 0.5rem;
  background-color: #9ca3af;
  border-radius: 50%;
  animation: bounce 1s infinite;
}
</style>
