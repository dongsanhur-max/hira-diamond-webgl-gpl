import { cpSync, existsSync, rmSync } from "node:fs";
import { resolve } from "node:path";

const projectRoot = resolve(import.meta.dirname, "..");
const sourceDirectory = resolve(projectRoot, "docs");
const outputDirectory = resolve(projectRoot, "dist");

if (!existsSync(sourceDirectory)) {
  throw new Error(`Missing source directory: ${sourceDirectory}`);
}

rmSync(outputDirectory, { recursive: true, force: true });
cpSync(sourceDirectory, outputDirectory, { recursive: true });

console.log(`Static site copied to ${outputDirectory}`);
