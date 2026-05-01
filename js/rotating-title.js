(function(){
  const phrases = [
    'broom closet datacenter operator',
    'media backlog curator',
    'part-time ski bum',
    'dog treat dispenser',
    'home game poker shark',
    'fair-weather cyclist',
  ];
  const el = document.getElementById('rotating-title');
  let phraseIdx = 0, charIdx = 0, deleting = false;

  function tick() {
    const phrase = phrases[phraseIdx];
    if (!deleting) {
      el.textContent = phrase.slice(0, ++charIdx);
      if (charIdx === phrase.length) {
        deleting = true;
        setTimeout(tick, 2200);
        return;
      }
      setTimeout(tick, 55);
    } else {
      el.textContent = phrase.slice(0, --charIdx);
      if (charIdx === 0) {
        deleting = false;
        phraseIdx = (phraseIdx + 1) % phrases.length;
        setTimeout(tick, 400);
        return;
      }
      setTimeout(tick, 28);
    }
  }
  setTimeout(tick, 900);
})();
