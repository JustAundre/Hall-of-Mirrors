window.addEventListener('DOMContentLoaded', () => {
	const root = document.documentElement;
	const configModal = document.querySelector('#config-menu');
	const toggleTheme = document.querySelector('#toggle-theme');
	const toggleMotion = document.querySelector('#toggle-motion');
	const toggleDyslexic = document.querySelector('#toggle-dyslexic');
	const savedConfig = JSON.parse(localStorage.getItem('userConfig'));

	if (savedConfig) {
		root.setAttribute('data-theme', savedConfig.theme);
		root.setAttribute('data-motion', savedConfig.motion);
		root.setAttribute('data-dyslexic', savedConfig.dyslexic);

		toggleTheme.checked = (savedConfig.theme === 'light');
		toggleMotion.checked = (savedConfig.motion === 'true');
		toggleDyslexic.checked = (savedConfig.dyslexic === 'true');
	} else {
		if (window.matchMedia("(prefers-color-scheme: light)").matches) {
			toggleTheme.checked = true;
			root.setAttribute('data-theme', 'light');
		} else {
			root.setAttribute('data-theme', 'dark');
		}
		if (!window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
			toggleMotion.checked = true;
			root.setAttribute('data-motion', 'true');
		} else {
			root.setAttribute('data-motion', 'false');
		}
		root.setAttribute('data-dyslexic', 'false');
	}

	configModal.showModal();
	configModal.addEventListener('close', () => {
		const theme = toggleTheme.checked ? 'light' : 'dark';
		const motion = toggleMotion.checked ? 'true' : 'false';
		const dyslexic = toggleDyslexic.checked ? 'true' : 'false';

		root.setAttribute('data-theme', theme);
		root.setAttribute('data-motion', motion);
		root.setAttribute('data-dyslexic', dyslexic);

		const config = { theme, motion, dyslexic };

		localStorage.setItem('userConfig', JSON.stringify(config));
	});
});