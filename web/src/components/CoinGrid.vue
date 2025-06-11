<script lang="ts" setup>
import { computed, defineProps } from "vue";

const props = defineProps<{ goldenStars: Coord[]; tiers: PrizeTier[] }>();

const ROWS = 5;
const COLS = 4;

function cellKey(r: number, c: number) {
  return `${r}-${c}`;
}

const starSet = computed<Set<string>>(
  () => new Set(props.goldenStars.map((p) => cellKey(p.r - 1, p.c - 1)))
);

function findComponents(stars: Set<string>): Coord[][] {
  const visited = new Set<string>();
  const components: Coord[][] = [];
  const dirs = [
    [-1, 0],
    [1, 0],
    [0, -1],
    [0, 1],
  ];

  function neighbors(r: number, c: number): Coord[] {
    return dirs
      .map(([dr, dc]) => ({ r: r + dr, c: c + dc }))
      .filter(
        ({ r, c }) =>
          r >= 0 &&
          r < ROWS && // r < 5
          c >= 0 &&
          c < COLS // c < 4
      );
  }

  for (const key of stars) {
    if (visited.has(key)) continue;

    const comp: Coord[] = [];
    const stack = [key];
    visited.add(key);

    while (stack.length) {
      const k = stack.pop()!;
      const [r, c] = k.split("-").map(Number);
      comp.push({ r, c });

      for (const { r: nr, c: nc } of neighbors(r, c)) {
        const nk = cellKey(nr, nc);
        if (stars.has(nk) && !visited.has(nk)) {
          visited.add(nk);
          stack.push(nk);
        }
      }
    }

    components.push(comp);
  }

  return components;
}

/** computed list of components **/
const components = computed<Coord[][]>(() => findComponents(starSet.value));

/** pick your winning cluster, if any **/
const winningCluster = computed<WinningCluster | null>(() => {
  for (const tier of props.tiers) {
    for (const comp of components.value) {
      if (comp.length >= tier.minCluster) {
        return { size: comp.length, reward: tier.reward };
      }
    }
  }
  return null;
});

function isInWinningCluster(r: number, c: number): boolean {
  const wc = winningCluster.value;

  if (!wc) return false;

  return components.value.some(
    (comp) => comp.length === wc.size && comp.some((p) => p.r === r && p.c === c)
  );
}
</script>

<template>
  <div class="flex items-center justify-center w-full h-full px-4 2xl:px-6">
    <div
      class="relative w-full aspect-[4/5] grid grid-cols-4 grid-rows-5 gap-1 place-items-center mt-1"
    >
      <template v-for="r in ROWS" :key="'r' + r">
        <template v-for="c in COLS" :key="`${r}-${c}`">
          <div
            class="w-full h-full"
            :class="{
              'cell--golden': starSet.has(cellKey(r - 1, c - 1)),
              'cell--win': isInWinningCluster(r - 1, c - 1),
            }"
          >
            <img v-if="starSet.has(cellKey(r - 1, c - 1))" src="@/assets/coin_winner.svg" />
            <img v-else src="@/assets/coin.svg" />
          </div>
        </template>
      </template>
    </div>
  </div>
</template>

<style scoped>
div[cell] {
  display: flex;
  align-items: center;
  justify-content: center;
}

.cell--win {
  box-shadow: 0 0 1rem gold;
  background: #fff7cc;
  border-radius: 9999px;
}
</style>
