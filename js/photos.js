// [filename_index, width, height]
const photos = [
  [1,1800,1350],[2,1349,1800],[3,1800,1350],[4,1800,1350],[5,1350,1800],
  [6,1800,1351],[7,1350,1800],[8,1800,1350],[9,1800,1350],[10,1350,1800],
  [11,1800,1350],[12,1800,1200],[13,1244,1800],[14,1800,1352],[15,1800,1200],
  [16,1349,1800],[17,1800,1350],[18,1800,1350],[19,1800,1350],[20,1800,1350],
  [21,1800,1350],[22,1800,1350],[23,1350,1800],[24,1800,1350],[25,1800,1350],
  [26,1800,1350],[27,1800,1200],[28,1351,1800],[29,1800,1200],[30,1350,1800],
  [31,1800,1352],[32,1201,1800],[33,1800,1350],[34,1800,1350],[35,1800,1350],
  [36,1800,1350],[37,1059,1319],[38,1800,1350],[39,1800,1349],[40,1800,1350],
  [41,1800,1351],[42,1350,1800],[43,1800,1350],[44,1350,1800],[45,1800,1350],
  [46,1800,1350],[47,1350,1800],[48,1800,1350],[49,1800,1350],[50,1350,1800],
  [51,1350,1800],[52,1800,1350],[53,1350,1800],[54,1800,1350],[55,1800,1351],
  [56,1800,1350],[57,1800,1350],[58,1800,1350],[59,1349,1800],[60,1800,1350],
  [61,1351,1800],[62,1800,1350],[63,1800,1351],[64,1800,1351],[65,1800,1455],
  [66,1800,1350],[67,1800,1200],[68,1800,1350],[69,1800,1350],[70,1350,1800],
  [71,1800,1350],[72,1350,1800],[73,1800,1350],[74,1350,1800],[75,1800,1350],
  [76,1349,1800],[77,1800,1350],[78,1800,1442],[79,1350,1800],[80,1800,1200],
  [81,1800,1350],[82,1800,1200],[83,1349,1800],[84,1351,1800],[85,1351,1800],
  [86,1800,1350],[87,1800,1350],[88,1350,1800],[89,1800,1350],[90,1350,1800],
  [91,1800,1350],[92,1800,1350],[93,1800,1350],[94,1800,1351],[95,1800,1342],
  [96,1800,1200],[97,1800,1350],[98,1800,1350],[99,1800,1350],[100,1800,1350],
  [101,1351,1800],[102,1800,1350],[103,1351,1800],[104,1800,1350],[105,1800,1305],
  [106,1350,1800],[107,1800,1350],[108,1800,1351],[109,1800,1350],[110,1800,1351],
  [111,1800,1350]
];

// Fisher-Yates shuffle
for (let i = photos.length - 1; i > 0; i--) {
  const j = Math.floor(Math.random() * (i + 1));
  [photos[i], photos[j]] = [photos[j], photos[i]];
}

const grid = document.getElementById('photo-grid');
const shuffled = [];
photos.forEach(([n, w, h], i) => {
  const id = String(n).padStart(3,'0');
  const img = document.createElement('img');
  img.src = `/photos/thumbs/${id}.webp`;
  img.dataset.full = `/photos/img/${id}.jpg`;
  img.width = w;
  img.height = h;
  img.loading = 'eager';
  img.decoding = 'async';
  img.dataset.idx = i;
  grid.appendChild(img);
  shuffled.push(img);
});

// Lightbox
const lightbox = document.getElementById('lightbox');
const lbImg = document.getElementById('lightbox-img');
let current = 0;

function open(i) {
  current = i;
  lbImg.src = shuffled[i].dataset.full;
  lightbox.classList.add('open');
  document.body.style.overflow = 'hidden';
}
function close() {
  lightbox.classList.remove('open');
  document.body.style.overflow = '';
}
function prev() { open((current - 1 + shuffled.length) % shuffled.length); }
function next() { open((current + 1) % shuffled.length); }

grid.addEventListener('click', e => {
  if (e.target.tagName === 'IMG') open(+e.target.dataset.idx);
});
document.getElementById('lightbox-close').addEventListener('click', close);
document.getElementById('lightbox-prev').addEventListener('click', e => { e.stopPropagation(); prev(); });
document.getElementById('lightbox-next').addEventListener('click', e => { e.stopPropagation(); next(); });
lightbox.addEventListener('click', close);
document.addEventListener('keydown', e => {
  if (!lightbox.classList.contains('open')) return;
  if (e.key === 'Escape') close();
  if (e.key === 'ArrowLeft') prev();
  if (e.key === 'ArrowRight') next();
});
