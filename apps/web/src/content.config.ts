import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

const modules = defineCollection({
  loader: glob({ base: './src/content/modules', pattern: '**/*.md' }),
  schema: z.object({
    title: z.string(),
    order: z.number(),
    summary: z.string(),
  }),
});

export const collections = {
  modules,
};
