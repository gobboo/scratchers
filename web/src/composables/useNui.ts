import { ref, onMounted, onUnmounted } from "vue";

interface NuiMessage<T = unknown> {
  type: string;
  data: T;
}

type NuiHandlerSignature<T> = (data: T) => void | Promise<void>;

export const useNuiEvent = <T = unknown>(type: string, handler: NuiHandlerSignature<T>) => {
  const savedHandler = ref<NuiHandlerSignature<T>>(handler);

  onMounted(() => {
    const eventListener = (event: MessageEvent<NuiMessage<T>>) => {
      // console.log("Received event:", event.source);
      const { type: eventType, data } = event.data;

      if (savedHandler.value && eventType === type) {
        savedHandler.value(data);
      }
    };

    window.addEventListener("message", eventListener);

    // Cleanup listener on unmount
    onUnmounted(() => {
      // console.log("useNuiEvent unmounted");
      window.removeEventListener("message", eventListener);
    });
  });
};
