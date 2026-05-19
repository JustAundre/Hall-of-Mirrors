const root = document.documentElement,
	configModal = document.querySelector('#config-menu'),
	toggleTheme = document.querySelector('#toggle-theme'),
	toggleMotion = document.querySelector('#toggle-motion'),
	toggleDyslexic = document.querySelector('#toggle-dyslexic'),
	savedConfig = JSON.parse(localStorage.getItem('userConfig'));

let config,
	theme,
	motion,
	dyslexic;

function openConfig() {
	configModal.showModal();
	configModal.setAttribute('open', '');
}

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
	openConfig()
}

function commitConfig() {
	config = { theme, motion, dyslexic };
	localStorage.setItem('userConfig', JSON.stringify(config));
}

function updateTheme() {
	theme = toggleTheme.checked ? 'light' : 'dark';
	root.setAttribute('data-theme', theme);
}

function updateMotion() {
	motion = toggleMotion.checked ? 'true' : 'false';
	root.setAttribute('data-motion', motion);
}

function updateDyslexic() {
	dyslexic = toggleDyslexic.checked ? 'true' : 'false';
	root.setAttribute('data-dyslexic', dyslexic);
}