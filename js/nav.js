(function () {
  const links = [
    ['/about/', 'about'],
    ['/projects/', 'projects'],
    ['/photos/', 'photos'],
    ['/shelf/', 'shelf'],
    ['/homelab/', 'homelab'],
  ];

  const path = window.location.pathname;
  const items = links.map(([href, label]) => {
    const active = (path === href || path.startsWith(href)) ? ' class="active"' : '';
    return `<li><a href="${href}"${active}>${label}</a></li>`;
  }).join('');

  const nav = document.createElement('nav');
  nav.innerHTML = `<div class="container"><a href="/" class="logo">martin hodde</a><ul>${items}</ul></div>`;
  document.body.prepend(nav);
})();
