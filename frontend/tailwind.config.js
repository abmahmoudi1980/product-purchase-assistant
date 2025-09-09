/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./components/**/*.{js,vue,ts}",
    "./layouts/**/*.vue",
    "./pages/**/*.vue",
    "./plugins/**/*.{js,ts}",
    "./app.vue",
    "./error.vue"
  ],
  theme: {
    extend: {
      fontFamily: {
        'persian': ['Vazirmatn', 'IRANSans', 'Tahoma', 'Arial', 'sans-serif'],
        'sans': ['Vazirmatn', 'IRANSans', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
      animation: {
        'bounce': 'bounce 1s infinite',
      }
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
}