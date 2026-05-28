import { siteConfig } from '../config/site';

export async function fetchWordPressRoot() {
  const response = await fetch(siteConfig.apiUrl);

  if (!response.ok) {
    throw new Error(`WordPress API responded with ${response.status}`);
  }

  return response.json();
}
