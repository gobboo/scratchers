<script setup lang="ts">
import { onMounted, reactive, ref } from "vue";
import CoinGrid from "./components/CoinGrid.vue";
import ScratchCard from "./components/ScratchCard.vue";
import { useNuiEvent } from "./composables/useNui";

// TODO: Move typings int types file
const state = reactive<State>({
  serial: "",
  scratched: false,
  goldenStars: [],
  isOpen: false,
  tiers: [],
});

useNuiEvent("Ticket:Open", (payload: NUIPayload) => {
  state.serial = payload.serial;
  state.scratched = payload.scratched;
  state.goldenStars = payload.goldenStars;

  // sort so we have highest tiers up top
  state.tiers = payload.tiers.sort((a, b) => b.minCluster - a.minCluster);

  state.isOpen = true;
});

// TODO: event type
async function handleClose(event: KeyboardEvent) {
  if (event.key !== "Escape") return;

  // alert the code we're all good here, with updated state
  await fetch("https://gob_scratchers/ticketClosed", {
    body: JSON.stringify({ scratched: state.scratched, serial: state.serial }),
    method: "POST",
  });

  // reset state
  state.isOpen = false;
  state.scratched = false;
  state.goldenStars = [];
}

const wrapper = ref<HTMLElement>();

onMounted(() => {
  // use an event listener as @keydown needs focus, even when using focus() didnt like me sooo
  document.addEventListener("keydown", handleClose);
});
</script>

<template>
  <div
    ref="wrapper"
    v-show="state.isOpen"
    @keydown="handleClose"
    tabindex="0"
    class="w-full h-screen bg-transparent flex justify-center items-center select-none"
  >
    <div
      class="scratcher relative max-w-80 2xl:max-w-96 w-full flex flex-col items-center py-6 px-5 sm:py-12 sm:px-10 rounded-2xl sm:gap-y-8"
    >
      <img class="absolute top-0 left-0 max-w-24 -scale-x-100" src="@/assets/stars.svg" />
      <img class="absolute top-0 right-0 max-w-24" src="@/assets/stars.svg" />

      <img class="w-full max-w-48" src="@/assets/title.svg" />

      <ScratchCard
        v-if="state.goldenStars.length && state.isOpen"
        :scratched="state.scratched"
        class="sm:px-4 sm:py-3 relative"
        @scratched="state.scratched = true"
      >
        <img class="absolute top-0 left-0 w-full object-contain" src="@/assets/border.svg" />
        <CoinGrid :golden-stars="state.goldenStars" :tiers="state.tiers" />
      </ScratchCard>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.scratcher {
  background-image: url("@/assets/background.png");
  background-size: cover;
  background-repeat: no-repeat;
  background-position: center;
  aspect-ratio: 1 / 1.5;
}
</style>
