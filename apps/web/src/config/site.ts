export const siteConfig = {
  name: 'TCG Platform',
  description: 'Frontend Astro para el backend headless WordPress Bedrock.',
  apiUrl: import.meta.env.PUBLIC_WORDPRESS_API_URL ?? 'http://localhost:8080/wp-json',
  internalApiUrl: import.meta.env.WORDPRESS_API_URL ?? import.meta.env.PUBLIC_WORDPRESS_API_URL ?? 'http://localhost:8080/wp-json',
  features: {
    shop: import.meta.env.PUBLIC_ENABLE_SHOP !== 'false',
    blog: import.meta.env.PUBLIC_ENABLE_BLOG !== 'false',
  },
};
