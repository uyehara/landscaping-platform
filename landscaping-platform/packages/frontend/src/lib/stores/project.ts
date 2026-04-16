import { writable } from 'svelte/store';

export interface User {
	id: string;
	email: string;
	name: string;
}

export interface Project {
	id: string;
	name: string;
	ownerId: string;
	createdAt: Date;
	updatedAt: Date;
}

// Auth store
export const currentUser = writable<User | null>(null);

// Active project store
export const activeProject = writable<Project | null>(null);


// UI state store
export const uiState = writable({
	isDrawing: false,
	selectedTool: 'select',
	zoom: 1,
	gridVisible: true
});
