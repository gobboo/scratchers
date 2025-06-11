<script setup lang="ts">
import { ref, onMounted } from "vue";

const props = defineProps<{ scratched: boolean }>();
const emit = defineEmits(["scratched"]);

let positionX = 0;
let positionY = 0;
let clearDetectionTimeout: number | null = null;

const scratchCardCover = ref<HTMLElement | null>(null);
const scratchCardCoverContainer = ref<HTMLElement | null>(null);

const canvas = ref<HTMLCanvasElement | null>(null);
let context: CanvasRenderingContext2D | null = null;

onMounted(() => {
  if (props.scratched) {
    scratchCardCoverContainer.value?.classList.add("hidden");
    return;
  }

  setTimeout(() => {
    if (!canvas.value) return;

    context = canvas.value.getContext("2d");
    if (!context) return;

    const devicePixelRatio = window.devicePixelRatio || 1;
    const canvasWidth = canvas.value.offsetWidth * devicePixelRatio;
    const canvasHeight = canvas.value.offsetHeight * devicePixelRatio;

    canvas.value.width = canvasWidth;
    canvas.value.height = canvasHeight;

    context.scale(devicePixelRatio, devicePixelRatio);

    // check if we're already scratched

    canvas.value.addEventListener("pointerdown", onPointerDown);
  }, 50);
});

function onPointerDown(e: PointerEvent) {
  if (!canvas.value || !context) return;

  // scratchCardCover.value?.classList.remove("shine");
  const pos = getPosition(e);
  positionX = pos.x;
  positionY = pos.y;

  if (clearDetectionTimeout !== null) {
    clearTimeout(clearDetectionTimeout);
    clearDetectionTimeout = null;
  }

  canvas.value.addEventListener("pointermove", plot);

  window.addEventListener(
    "pointerup",
    () => {
      canvas.value?.removeEventListener("pointermove", plot);
      clearDetectionTimeout = window.setTimeout(() => {
        checkBlackFillPercentage();
      }, 500);
    },
    { once: true }
  );
}

function getPosition(e: PointerEvent): { x: number; y: number } {
  if (!canvas.value) return { x: 0, y: 0 };
  const rect = canvas.value.getBoundingClientRect();
  return {
    x: e.clientX - rect.left,
    y: e.clientY - rect.top,
  };
}

function plot(e: PointerEvent) {
  if (!context) return;
  const { x, y } = getPosition(e);
  plotLine(context, positionX, positionY, x, y);
  positionX = x;
  positionY = y;
}

function plotLine(ctx: CanvasRenderingContext2D, x1: number, y1: number, x2: number, y2: number) {
  const diffX = Math.abs(x2 - x1);
  const diffY = Math.abs(y2 - y1);
  const dist = Math.sqrt(diffX * diffX + diffY * diffY);
  const step = dist / 50;
  let i = 0;

  while (i < dist) {
    const t = Math.min(1, i / dist);
    const x = x1 + (x2 - x1) * t;
    const y = y1 + (y2 - y1) * t;

    ctx.beginPath();
    ctx.arc(x, y, 16, 0, Math.PI * 2);
    ctx.fill();

    i += step;
  }
}

function checkBlackFillPercentage() {
  if (!context || !canvas.value) return;
  const canvasWidth = canvas.value.width;
  const canvasHeight = canvas.value.height;
  const imageData = context.getImageData(0, 0, canvasWidth, canvasHeight);
  const pixelData = imageData.data;

  let blackPixelCount = 0;
  for (let i = 0; i < pixelData.length; i += 4) {
    const red = pixelData[i];
    const green = pixelData[i + 1];
    const blue = pixelData[i + 2];
    const alpha = pixelData[i + 3];

    if (red === 0 && green === 0 && blue === 0 && alpha === 255) {
      blackPixelCount++;
    }
  }

  const blackFillPercentage = (blackPixelCount * 100) / (canvasWidth * canvasHeight);

  if (blackFillPercentage >= 45) {
    scratchCardCoverContainer.value?.classList.add("clear");

    // const textRect = scratchCardText.value?.getBoundingClientRect();
    // const originY = textRect ? (textRect.bottom + 60) / window.innerHeight : 0.5;

    scratchCardCoverContainer.value?.addEventListener(
      "transitionend",
      () => {
        scratchCardCoverContainer.value?.classList.add("hidden");
        emit("scratched");
      },
      { once: true }
    );
  }
}
</script>

<template>
  <div class="scratch-card">
    <!-- Container that will get the “clear” and “hidden” classes -->
    <div class="scratch-card-cover-container -translate-1/2" ref="scratchCardCoverContainer">
      <canvas ref="canvas" class="scratch-card-canvas" width="full" height="full"></canvas>

      <div class="scratch-card-cover shine" ref="scratchCardCover"></div>
    </div>

    <slot />

    <svg width="0" height="0">
      <filter id="remove-black" color-interpolation-filters="sRGB">
        <feColorMatrix
          type="matrix"
          values="1 0 0 0 0
              0 1 0 0 0
              0 0 1 0 0
              -1 -1 -1 0 1"
          result="black-pixels"
        />
        <feComposite in="SourceGraphic" in2="black-pixels" operator="out" />
      </filter>
    </svg>
  </div>
</template>

<style scoped>
.scratch-card {
  position: relative;
  border: none;
  width: "fit-content";
  height: "fit-content";
  aspect-ratio: 1 / 1.1130705394191;
}

.scratch-card-cover-container {
  position: absolute;
  z-index: 1;
  top: 50%;
  left: 50%;
  width: 88.5%;
  height: 89.5%;
  filter: url("#remove-black");
  transition: opacity 0.4s;

  &.clear {
    opacity: 0;
  }

  &.hidden {
    display: none;
  }
}

.scratch-card-canvas {
  position: absolute;
  z-index: 2;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  cursor: grab;
  touch-action: none;
}

.scratch-card-canvas.hidden {
  opacity: 0;
}

.scratch-card-canvas:active {
  cursor: grabbing;
}

.scratch-card-canvas-render {
  position: absolute;
  z-index: 1;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: transparent;
  transition: background-color 0.2s;
}

.scratch-card-canvas-render.hidden {
  display: none;
}

.scratch-card-cover {
  display: flex;
  justify-content: center;
  align-items: center;
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;
  background: 
    /* Conic‐gradient layer #1 (blended via “screen”) */ conic-gradient(
      from 176.21deg at 50% 50%,
      #000000 -24.66deg,
      #ffffff 0.25deg,
      #000000 50.63deg,
      #000000 51.97deg,
      #ffffff 88.12deg,
      #000000 142.5deg,
      #ffffff 196.87deg,
      #000000 256.87deg,
      #ffffff 300deg,
      #000000 335.2deg,
      #000000 335.34deg,
      #ffffff 360.25deg
    ),
    /* Conic‐gradient layer #2 (blended via “difference”) */
      conic-gradient(
        from 176.21deg at 50% 50%,
        #000000 -24.66deg,
        #ffffff 0.25deg,
        #000000 50.63deg,
        #000000 51.97deg,
        #ffffff 88.12deg,
        #000000 142.5deg,
        #ffffff 196.87deg,
        #000000 256.87deg,
        #ffffff 300deg,
        #000000 335.2deg,
        #000000 335.34deg,
        #ffffff 360.25deg
      ),
    /* Radial‐gradient layer (on top) */
      radial-gradient(
        95.11% 95.11% at 36.64% 4.89%,
        #7d7d7d 0%,
        #adadad 22.92%,
        #d7d7d7 46.88%,
        #d4d4d4 68.23%,
        #aaaaaa 87.5%,
        #a7a7a7 100%
      );

  background-blend-mode: screen, /* for the first conic‐gradient */ difference,
    /* for the second conic‐gradient */ normal; /* radial goes on top normally */

  /* 
    Apply a tiny blur to soften any hard edges.
    Adjust between 0px – 2px as you see fit. 
  */
  filter: blur(1px);

  /* Rounded corners (change to your own radius) */
  border-radius: 8px;
}

/* ------------------------------------------------ */
/*  “Shine” Overlay (diagonal highlight)            */
/* ------------------------------------------------ */
.scratch-card-cover.shine::before {
  content: "";
  position: absolute;
  inset: 0; /* shorthand for top:0; right:0; bottom:0; left:0 */
  background-image: linear-gradient(
    135deg,
    transparent 40%,
    rgba(255, 255, 255, 0.9) 50%,
    transparent 60%
  );
  background-position: bottom right;
  background-size: 300% 300%;
  background-repeat: no-repeat;
  pointer-events: none;
  animation: shine 6s infinite;
}

@keyframes shine {
  50% {
    background-position: 0% 0%;
  }
  100% {
    background-position: -50% -50%;
  }
}

@keyframes pop-out-in {
  36% {
    transform: scale(1.125);
  }
  100% {
    transform: scale(1);
  }
}
</style>
