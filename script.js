const board = document.getElementById('led-board');
const red = document.getElementById('red');
const green = document.getElementById('green');
const blue = document.getElementById('blue');
const brightness = document.getElementById('brightness');
const speed = document.getElementById('speed');
const hexCode = document.getElementById('hex-code');
const redVal = document.getElementById('red-val');
const greenVal = document.getElementById('green-val');
const blueVal = document.getElementById('blue-val');
const brightVal = document.getElementById('bright-val');
const speedVal = document.getElementById('speed-val');

let mode = 'solid';
let leds = [];
let animId = null;
let time = 0;

// Create 8x8 LED grid
for (let i = 0; i < 64; i++) {
  const led = document.createElement('div');
  led.className = 'led';
  board.appendChild(led);
  leds.push(led);
}

function updateColor() {
  const r = +red.value;
  const g = +green.value;
  const b = +blue.value;
  const br = +brightness.value / 100;

  redVal.textContent = r;
  greenVal.textContent = g;
  blueVal.textContent = b;
  brightVal.textContent = Math.round(br * 100) + '%';
  speedVal.textContent = speed.value;

  const hex = '#' + [r, g, b].map(v => v.toString(16).padStart(2, '0')).join('').toUpperCase();
  hexCode.textContent = hex;

  if (mode === 'solid') {
    applySolid(r, g, b, br);
  }
}

function applySolid(r, g, b, br) {
  const color = `rgb(${r * br}, ${g * br}, ${b * br})`;
  const glow = `0 0 12px rgb(${r}, ${g}, ${b}), 0 0 24px rgb(${r}, ${g}, ${b})`;
  leds.forEach(led => {
    led.style.background = color;
    led.style.boxShadow = glow;
  });
}

function animate() {
  time += 0.05 * (+speed.value || 1);
  const r = +red.value;
  const g = +green.value;
  const b = +blue.value;
  const br = +brightness.value / 100;

  leds.forEach((led, i) => {
    let factor = 1;
    const row = Math.floor(i / 8);
    const col = i % 8;

    if (mode === 'pulse') {
      factor = 0.4 + 0.6 * (0.5 + 0.5 * Math.sin(time));
    } else if (mode === 'wave') {
      factor = 0.3 + 0.7 * (0.5 + 0.5 * Math.sin(time + col * 0.5 + row * 0.3));
    } else if (mode === 'spark') {
      factor = Math.random() > 0.7 ? 1 : 0.15 + 0.2 * Math.sin(time * 3 + i);
    }

    const fr = r * br * factor;
    const fg = g * br * factor;
    const fb = b * br * factor;
    led.style.background = `rgb(${fr}, ${fg}, ${fb})`;
    led.style.boxShadow = `0 0 ${8 + 12 * factor}px rgb(${r}, ${g}, ${b})`;
  });

  animId = requestAnimationFrame(animate);
}

function setMode(newMode) {
  mode = newMode;
  document.querySelectorAll('.mode-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.mode === mode);
  });
  if (animId) cancelAnimationFrame(animId);
  if (mode === 'solid') {
    updateColor();
  } else {
    animate();
  }
}

// Event listeners
[red, green, blue, brightness, speed].forEach(el => {
  el.addEventListener('input', () => {
    if (mode === 'solid') updateColor();
  });
});

document.getElementById('random-btn').addEventListener('click', () => {
  red.value = Math.floor(Math.random() * 256);
  green.value = Math.floor(Math.random() * 256);
  blue.value = Math.floor(Math.random() * 256);
  updateColor();
});

document.querySelectorAll('.preset').forEach(btn => {
  btn.addEventListener('click', () => {
    red.value = btn.dataset.r;
    green.value = btn.dataset.g;
    blue.value = btn.dataset.b;
    updateColor();
  });
});

document.querySelectorAll('.mode-btn').forEach(btn => {
  btn.addEventListener('click', () => setMode(btn.dataset.mode));
});

document.getElementById('save-btn').addEventListener('click', () => {
  const name = prompt('Preset name:');
  if (name) {
    const btn = document.createElement('button');
    btn.className = 'preset';
    btn.textContent = name;
    btn.dataset.r = red.value;
    btn.dataset.g = green.value;
    btn.dataset.b = blue.value;
    btn.addEventListener('click', () => {
      red.value = btn.dataset.r;
      green.value = btn.dataset.g;
      blue.value = btn.dataset.b;
      updateColor();
    });
    document.getElementById('presets').appendChild(btn);
  }
});

// Init
updateColor();