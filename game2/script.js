const boardEl = document.getElementById('board');
const scoreEl = document.getElementById('score');
const levelEl = document.getElementById('level');
const timerEl = document.getElementById('timer');
const msgEl = document.getElementById('message');
const rotateBtn = document.getElementById('rotate-btn');
const checkBtn = document.getElementById('check-btn');
const nextBtn = document.getElementById('next-btn');

const WIRES = ['─','│','┌','┐','└','┘','├','┤','┬','┴','┼'];
let grid = [];
let selected = null;
let score = 0;
let level = 1;
let timeLeft = 30;
let timerId = null;
const SIZE = 5;

function createLevel() {
  grid = Array(SIZE*SIZE).fill(null);
  grid[0] = 'S';
  grid[SIZE*SIZE-1] = 'T';
  if (level > 1) {
    grid[1] = '─';
    grid[SIZE] = '│';
  }
  render();
  startTimer();
  msgEl.textContent = 'Connect Source (S) to Target (T). Click cells to place wires.';
  nextBtn.disabled = true;
}

function render() {
  boardEl.innerHTML = '';
  grid.forEach((val, i) => {
    const cell = document.createElement('div');
    cell.className = 'cell';
    if (val === 'S') { cell.classList.add('source'); cell.textContent = '⚡'; }
    else if (val === 'T') { cell.classList.add('target'); cell.textContent = '💡'; }
    else if (val) { cell.textContent = val; }
    cell.dataset.idx = i;
    cell.addEventListener('click', () => selectCell(i));
    boardEl.appendChild(cell);
  });
}

function selectCell(idx) {
  if (grid[idx] === 'S' || grid[idx] === 'T') return;
  selected = idx;
  const current = grid[idx];
  const nextIdx = current ? (WIRES.indexOf(current)+1) % WIRES.length : 0;
  grid[idx] = WIRES[nextIdx];
  render();
}

rotateBtn.addEventListener('click', () => {
  if (selected === null || !grid[selected] || grid[selected]==='S'||grid[selected]==='T') return;
  const i = WIRES.indexOf(grid[selected]);
  grid[selected] = WIRES[(i+1)%WIRES.length];
  render();
});

function startTimer() {
  clearInterval(timerId);
  timeLeft = 25 + level * 5;
  timerEl.textContent = timeLeft;
  timerId = setInterval(() => {
    timeLeft--;
    timerEl.textContent = timeLeft;
    if (timeLeft <= 0) {
      clearInterval(timerId);
      msgEl.textContent = 'Time up! Circuit failed.';
      msgEl.style.color = '#ff4466';
    }
  }, 1000);
}

checkBtn.addEventListener('click', () => {
  const hasWires = grid.some(c => c && c!=='S' && c!=='T');
  if (!hasWires) {
    msgEl.textContent = 'Place some wires first!';
    msgEl.style.color = '#ffaa00';
    return;
  }
  clearInterval(timerId);
  score += timeLeft * level * 10;
  scoreEl.textContent = score;
  msgEl.textContent = 'Power flowing! Circuit complete!';
  msgEl.style.color = '#00ff88';
  nextBtn.disabled = false;
  document.querySelectorAll('.cell').forEach(c => c.classList.add('correct'));
});

nextBtn.addEventListener('click', () => {
  level++;
  levelEl.textContent = level;
  createLevel();
});

createLevel();