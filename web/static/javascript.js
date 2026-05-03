// Insert the navbar
fetch('/web/static/navbar.html')
	.then(res => res.text())
	.then(data => {
		document.getElementById('navbar-placeholder').innerHTML = data;
	});

// Insert the footer
fetch('/web/static/footer.html')
	.then(res => res.text())
	.then(data => {
		document.getElementById('footer-placeholder').innerHTML = data;
	});