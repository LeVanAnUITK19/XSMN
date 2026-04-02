
export const buildDigits = (full) => {
  const all = Object.values(full).flat();

  return {
    twoDigits: all.map(x => x.slice(-2)),
    threeDigits: all.map(x => x.slice(-3))
  };
};