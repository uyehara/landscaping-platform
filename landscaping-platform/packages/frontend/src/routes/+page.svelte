<script lang="ts">
	import { Card, Button } from 'flowbite-svelte';
</script>

<svelte:head>
	<title>Landscaping Platform</title>
</svelte:head>


<div class="min-h-screen flex flex-col">
	<!-- Header -->
	<header class="bg-white dark:bg-gray-800 shadow-sm">
		<div class="container mx-auto px-4 py-4 flex justify-between items-center">
			<h1 class="text-2xl font-bold text-primary-600 dark:text-primary-400">
				🌿 Landscaping Platform
			</h1>
			<nav class="flex gap-4">
				<a href="/projects" class="text-gray-600 dark:text-gray-300 hover:text-primary-600">Projects</a>
				<a href="/design" class="text-gray-600 dark:text-gray-300 hover:text-primary-600">Design</a>
			</nav>
		</div>
	</header>

	<!-- Main Content -->
	<main class="flex-1 container mx-auto px-4 py-8">
		<div class="grid md:grid-cols-3 gap-6">
			<Card href="/design/new">
				<h3 class="text-xl font-semibold mb-2">🎨 New Design</h3>
				<p class="text-gray-600 dark:text-gray-400">
					Start a new collaborative landscaping design project
				</p>
			</Card>

			<Card href="/projects">
				<h3 class="text-xl font-semibold mb-2">📋 Projects</h3>
				<p class="text-gray-600 dark:text-gray-400">
					View and manage your landscaping projects
				</p>
			</Card>

			<Card href="/clients">
				<h3 class="text-xl font-semibold mb-2">👥 Clients</h3>
				<p class="text-gray-600 dark:text-gray-400">
					Manage client information and contacts
				</p>
			</Card>
		</div>
	</main>

	<!-- Footer -->
	<footer class="bg-gray-100 dark:bg-gray-800 py-4 text-center text-sm text-gray-500">
		Landscaping Platform v0.1.0
	</footer>
</div>
