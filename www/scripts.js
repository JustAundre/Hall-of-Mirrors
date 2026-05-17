window.addEventListener('DOMContentLoaded', () => {
	const root = document.querySelector("html")
	const configModal = document.querySelector('#config-menu');
	const toggleTheme = document.getElementById('toggle-theme');
	const toggleMotion = document.getElementById('toggle-motion');
	const toggleDyslexic = document.getElementById('toggle-dyslexic');
	configModal.showModal();
	configModal.addEventListener('close', () => {
		if (toggleTheme.checked) {
			root.setAttribute('data-theme', 'light');
		} else {
			root.setAttribute('data-theme', 'dark');
		}

		if (!toggleMotion.checked) {
			root.setAttribute('data-motion', 'true');
		} else {
			root.setAttribute('data-motion', 'false');
		}

		if (toggleDyslexic.checked) {
			root.setAttribute('data-dyslexic', 'true');
		} else {
			root.setAttribute('data-dyslexic', 'false');
		}
	});
});