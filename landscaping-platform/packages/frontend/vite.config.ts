import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],
	server: {
		port: 5173,
		host: true,
		proxy: {
			'/api': {
				target: process.env.PUBLIC_API_URL || 'http://localhost:3001',
				changeOrigin: true
			}
		}
	},
	build: {
		target: 'esnext'
	}
});
