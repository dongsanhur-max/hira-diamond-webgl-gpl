// Temporary dev-server config used only for T5 mobile-device testing.
// Vite's default server.allowedHosts blocks requests whose Host header
// isn't recognized (DNS-rebinding protection), which rejects the random
// *.trycloudflare.com hostname a quick tunnel assigns. This widens that
// check for local testing only -- it is never used by `npm run dev` or
// `npm run build` and has no effect on any deployed/production path.
export default {
  root: new URL("../../docs", import.meta.url).pathname.replace(/^\/([A-Za-z]):/, "$1:"),
  server: {
    host: "0.0.0.0",
    allowedHosts: true,
  },
};
