export default defineNuxtPlugin(() => {
  // Preload Persian fonts for better performance
  if (process.client) {
    // Create link elements for font preloading
    const fontLinks = [
      {
        href: 'https://fonts.googleapis.com/css2?family=Vazirmatn:wght@100;200;300;400;500;600;700;800;900&display=swap',
        as: 'style'
      },
      {
        href: 'https://cdn.fontcdn.ir/Font/Persian/IRANSans/IRANSansXFaNum.css',
        as: 'style'
      }
    ]

    fontLinks.forEach(link => {
      const linkElement = document.createElement('link')
      linkElement.rel = 'preload'
      linkElement.href = link.href
      linkElement.as = link.as
      linkElement.crossOrigin = 'anonymous'
      document.head.appendChild(linkElement)
    })

    // Set font-display: swap for better performance
    const style = document.createElement('style')
    style.textContent = `
      @font-face {
        font-family: 'Vazirmatn';
        font-display: swap;
      }
      @font-face {
        font-family: 'IRANSansXFaNum';
        font-display: swap;
      }
    `
    document.head.appendChild(style)
  }
})
