function overlaps(startA, durA, startB, durB) {
  const a1 = new Date(startA).getTime();
  const a2 = a1 + durA * 60000;
  const b1 = new Date(startB).getTime();
  const b2 = b1 + durB * 60000;
  return a1 < b2 && b1 < a2;
}

module.exports = { overlaps };
