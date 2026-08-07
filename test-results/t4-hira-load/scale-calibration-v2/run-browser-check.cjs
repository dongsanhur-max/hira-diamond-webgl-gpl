const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { chromium } = require("playwright");

const [url, outputDir] = process.argv.slice(2);
if (!url || !outputDir) {
  console.error("Usage: node run-browser-check.cjs <url> <output-dir>");
  process.exit(1);
}

fs.mkdirSync(outputDir, { recursive: true });
const runtime = {
  date: new Date().toISOString(),
  url,
  viewport: { width: 900, height: 900 },
  browser: null,
  responses: [],
  failedRequests: [],
  console: [],
  pageErrors: [],
  captures: [],
};

function sha256(filePath) {
  return crypto.createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}

async function capture(page, canvas, name) {
  const filePath = path.join(outputDir, `${name}.png`);
  await canvas.screenshot({ path: filePath });
  runtime.captures.push({ name, file: path.basename(filePath), sha256: sha256(filePath) });
}

async function interactAndCapture(page, mode, geometryOnly) {
  await page.goto(url, { waitUntil: "networkidle", timeout: 30000 });
  await page.waitForTimeout(1500);
  if (geometryOnly) {
    await page.locator("#only-normals-checkbox-id").check({ force: true });
    await page.waitForTimeout(800);
  }

  const canvas = page.locator("canvas").first();
  await canvas.scrollIntoViewIfNeeded();
  await page.waitForTimeout(300);
  const geometryOnlyChecked = await page.locator("#only-normals-checkbox-id").isChecked();
  const box = await canvas.boundingBox();
  if (!box) throw new Error("Canvas has no bounding box.");

  await capture(page, canvas, `${mode}-initial`);
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  await page.mouse.down();
  await page.mouse.move(box.x + box.width / 2 + 150, box.y + box.height / 2 - 50, { steps: 20 });
  await page.mouse.up();
  await page.waitForTimeout(500);
  await capture(page, canvas, `${mode}-rotated`);

  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  for (let index = 0; index < 5; index += 1) await page.mouse.wheel(0, -300);
  await page.waitForTimeout(500);
  await capture(page, canvas, `${mode}-zoomed`);

  return {
    geometryOnlyRequested: geometryOnly,
    geometryOnlyChecked,
    rotation: { deltaX: 150, deltaY: -50, steps: 20 },
    zoom: { wheelEvents: 5, deltaYEach: -300 },
    canvasBox: box,
  };
}

(async () => {
  const browser = await chromium.launch({
    headless: true,
    args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-webgl", "--ignore-gpu-blocklist"],
  });
  runtime.browser = await browser.version();
  const context = await browser.newContext({ viewport: runtime.viewport });
  const page = await context.newPage();

  page.on("console", (message) => {
    runtime.console.push({ type: message.type(), text: message.text() });
  });
  page.on("pageerror", (error) => runtime.pageErrors.push(error.message));
  page.on("requestfailed", (request) => {
    runtime.failedRequests.push({ url: request.url(), error: request.failure()?.errorText || "unknown" });
  });
  page.on("response", async (response) => {
    if (!response.url().includes(".obj")) return;
    const record = { url: response.url(), status: response.status() };
    try {
      record.bodySha256 = crypto.createHash("sha256").update(await response.body()).digest("hex");
    } catch (error) {
      record.bodyHashError = error.message;
    }
    runtime.responses.push(record);
  });

  runtime.fullLighting = await interactAndCapture(page, "full-lighting", false);
  runtime.geometryOnly = await interactAndCapture(page, "geometry-only", true);
  await context.close();
  await browser.close();

  const hashes = Object.fromEntries(runtime.captures.map((capture) => [capture.name, capture.sha256]));
  runtime.assertions = {
    allObjResponsesHttp200: runtime.responses.length > 0 && runtime.responses.every((item) => item.status === 200),
    noFailedRequests: runtime.failedRequests.length === 0,
    noPageErrors: runtime.pageErrors.length === 0,
    fullLightingInteractionChangedPixels:
      new Set([hashes["full-lighting-initial"], hashes["full-lighting-rotated"], hashes["full-lighting-zoomed"]]).size === 3,
    geometryOnlyInteractionChangedPixels:
      new Set([hashes["geometry-only-initial"], hashes["geometry-only-rotated"], hashes["geometry-only-zoomed"]]).size === 3,
    geometryOnlyWasChecked: runtime.geometryOnly.geometryOnlyChecked,
  };
  fs.writeFileSync(path.join(outputDir, "browser-runtime.json"), `${JSON.stringify(runtime, null, 2)}\n`);
  if (Object.values(runtime.assertions).some((value) => !value)) process.exitCode = 1;
})().catch((error) => {
  runtime.driverFatal = error.stack || error.message;
  fs.writeFileSync(path.join(outputDir, "browser-runtime.json"), `${JSON.stringify(runtime, null, 2)}\n`);
  console.error(error);
  process.exit(1);
});
