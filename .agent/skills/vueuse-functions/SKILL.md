---
name: vueuse-functions
description: Apply VueUse composables where appropriate to build concise, maintainable Vue.js / Nuxt features.
metadata: { author: SerKo, version: "1.1" }
compatibility: Requires Vue 3+ / Nuxt 3+
---

# VueUse Functions

Prefer VueUse composables over bespoke code. Map requirements to functions below. Check `./references/[function].md` for details on signatures and patterns.

**Invocation Rules**:
- `AUTO`: Use automatically when applicable.
- `EXTERNAL`: Requires external dependency. Ask user before installing.
- `EXPLICIT_ONLY`: Use only when explicitly requested.

## Function Index (Grouped by Category)

### 🔵 AUTO Invocation
- **State**: `createGlobalState`, `createInjectionState`, `createSharedComposable`, `injectLocal`, `provideLocal`, `useAsyncState`, `useDebouncedRefHistory`, `useLastChanged`, `useLocalStorage`, `useManualRefHistory`, `useRefHistory`, `useSessionStorage`, `useStorage`, `useStorageAsync`, `useThrottledRefHistory`
- **Elements**: `useActiveElement`, `useDocumentVisibility`, `useDraggable`, `useDropZone`, `useElementBounding`, `useElementSize`, `useElementVisibility`, `useIntersectionObserver`, `useMouseInElement`, `useMutationObserver`, `useParentElement`, `useResizeObserver`, `useWindowFocus`, `useWindowScroll`, `useWindowSize`
- **Browser**: `useBluetooth`, `useBreakpoints`, `useBroadcastChannel`, `useBrowserLocation`, `useClipboard`, `useClipboardItems`, `useColorMode`, `useCssVar`, `useDark`, `useEventListener`, `useEyeDropper`, `useFavicon`, `useFileDialog`, `useFileSystemAccess`, `useFullscreen`, `useGamepad`, `useImage`, `useMediaControls`, `useMediaQuery`, `useMemory`, `useObjectUrl`, `usePerformanceObserver`, `usePermission`, `usePreferredColorScheme`, `usePreferredContrast`, `usePreferredDark`, `usePreferredLanguages`, `usePreferredReducedMotion`, `usePreferredReducedTransparency`, `useScreenOrientation`, `useScreenSafeArea`, `useScriptTag`, `useShare`, `useSSRWidth`, `useStyleTag`, `useTextareaAutosize`, `useTextDirection`, `useTitle`, `useUrlSearchParams`, `useVibrate`, `useWakeLock`, `useWebNotification`, `useWebWorker`, `useWebWorkerFn`
- **Sensors**: `onClickOutside`, `onElementRemoval`, `onKeyStroke`, `onLongPress`, `onStartTyping`, `useBattery`, `useDeviceMotion`, `useDeviceOrientation`, `useDevicePixelRatio`, `useDevicesList`, `useDisplayMedia`, `useElementByPoint`, `useElementHover`, `useFocus`, `useFocusWithin`, `useFps`, `useGeolocation`, `useIdle`, `useInfiniteScroll`, `useKeyModifier`, `useMagicKeys`, `useMouse`, `useMousePressed`, `useNavigatorLanguage`, `useNetwork`, `useOnline`, `usePageLeave`, `useParallax`, `usePointer`, `usePointerLock`, `usePointerSwipe`, `useScroll`, `useScrollLock`, `useSpeechRecognition`, `useSpeechSynthesis`, `useSwipe`, `useTextSelection`, `useUserMedia`
- **Network**: `useEventSource`, `useFetch`, `useWebSocket`
- **Animation**: `useAnimate`, `useInterval`, `useIntervalFn`, `useNow`, `useRafFn`, `useTimeout`, `useTimeoutFn`, `useTimestamp`, `useTransition`
- **Component**: `computedInject`, `createReusableTemplate`, `createTemplatePromise`, `templateRef`, `tryOnBeforeMount`, `tryOnBeforeUnmount`, `tryOnMounted`, `tryOnScopeDispose`, `tryOnUnmounted`, `unrefElement`, `useCurrentElement`, `useMounted`, `useTemplateRefsList`, `useVirtualList`, `useVModel`, `useVModels`
- **Watch**: `until`, `watchArray`, `watchAtMost`, `watchDebounced`, `watchDeep`, `watchIgnorable`, `watchImmediate`, `watchOnce`, `watchPausable`, `watchThrottled`, `watchTriggerable`, `watchWithFilter`, `whenever`
- **Reactivity**: `computedAsync`, `computedEager`, `computedWithControl`, `createRef`, `extendRef`, `reactify`, `reactifyObject`, `reactiveComputed`, `reactiveOmit`, `reactivePick`, `refAutoReset`, `refDebounced`, `refDefault`, `refManualReset`, `refThrottled`, `refWithControl`, `syncRef`, `syncRefs`, `toReactive`, `toRefs`
- **Array**: `useArrayDifference`, `useArrayEvery`, `useArrayFilter`, `useArrayFind`, `useArrayFindIndex`, `useArrayFindLast`, `useArrayIncludes`, `useArrayJoin`, `useArrayMap`, `useArrayReduce`, `useArraySome`, `useArrayUnique`, `useSorted`
- **Time**: `useCountdown`, `useDateFormat`, `useTimeAgo`, `useTimeAgoIntl`
- **Utilities**: `createEventHook`, `createUnrefFn`, `isDefined`, `makeDestructurable`, `useAsyncQueue`, `useBase64`, `useCached`, `useCloned`, `useConfirmDialog`, `useCounter`, `useCycleList`, `useDebounceFn`, `useEventBus`, `useMemoize`, `useOffsetPagination`, `usePrevious`, `useStepper`, `useSupported`, `useThrottleFn`, `useTimeoutPoll`, `useToggle`, `useToNumber`, `useToString`

### 🟡 EXTERNAL Invocation (Needs Dependency)
- **@Electron**: `useIpcRenderer`, `useIpcRendererInvoke`, `useIpcRendererOn`, `useZoomFactor`, `useZoomLevel`
- **@Firebase**: `useAuth`, `useFirestore`, `useRTDB`
- **@Head**: `createHead`, `useHead`
- **@Integrations**: `useAsyncValidator`, `useAxios`, `useChangeCase`, `useCookies`, `useDrauu`, `useFocusTrap`, `useFuse`, `useIDBKeyval`, `useJwt`, `useNProgress`, `useQRCode`, `useSortable`
- **@Math**: `createGenericProjection`, `createProjection`, `logicAnd`, `logicNot`, `logicOr`, `useAbs`, `useAverage`, `useCeil`, `useClamp`, `useFloor`, `useMath`, `useMax`, `useMin`, `usePrecision`, `useProjection`, `useRound`, `useSum`, `useTrunc`
- **@Motion**: `useElementStyle`, `useElementTransform`, `useMotion`, `useMotionProperties`, `useMotionVariants`, `useSpring`
- **@Router**: `useRouteHash`, `useRouteParams`, `useRouteQuery`
- **@RxJS**: `from`, `toObserver`, `useExtractedObservable`, `useObservable`, `useSubject`, `useSubscription`, `watchExtractedObservable`
- **@SchemaOrg**: `createSchemaOrg`, `useSchemaOrg`
- **@Sound**: `useSound`

### 🔴 EXPLICIT_ONLY Invocation
- **Reactivity**: `toRef`
- **Utilities**: `get`, `set`
