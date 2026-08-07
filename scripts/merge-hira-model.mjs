import fs from "node:fs";
import path from "node:path";

function usage() {
  console.error(
    "Usage: node scripts/merge-hira-model.mjs <metal.obj> <diamond.obj> <output.obj> [--scale=1.0]"
  );
  process.exitCode = 1;
}

function offsetIndex(value, offset) {
  if (!value || value.startsWith("-")) {
    return value;
  }

  const index = Number(value);
  if (!Number.isInteger(index) || index < 1) {
    throw new Error(`Invalid positive OBJ index: ${value}`);
  }

  return String(index + offset);
}

function rewriteFace(face, offsets) {
  const [vertex, texture, normal] = face.split("/");
  const rewrittenVertex = offsetIndex(vertex, offsets.v);
  if (!normal) {
    return rewrittenVertex;
  }

  // The preserved loader's sample OBJ uses v//vn faces. Preserve normal
  // references but omit unused texture-coordinate indices for compatibility.
  return `${rewrittenVertex}//${offsetIndex(normal, offsets.vn)}`;
}

function mergeSource(sourcePath, label, offsets, scale) {
  const text = fs.readFileSync(sourcePath, "utf8");
  const lines = text.split(/\r?\n/);
  const output = [`# HIRA runtime adapter source: ${label} (${path.basename(sourcePath)})`];
  const counts = { v: 0, vt: 0, vn: 0, f: 0 };

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) {
      output.push(line);
      continue;
    }

    const [keyword, ...values] = trimmed.split(/\s+/);
    if (keyword === "v") {
      counts.v += 1;
      // Uniform position scale only (direction of vn is unaffected by a
      // uniform positive scale, so normals are passed through unscaled).
      const scaled = values.map((component) => {
        const num = Number(component);
        if (!Number.isFinite(num)) {
          throw new Error(`${sourcePath}: non-finite vertex component "${component}"`);
        }
        return (num * scale).toFixed(8);
      });
      output.push(`v ${scaled.join(" ")}`);
      continue;
    }
    if (keyword === "vt" || keyword === "vn") {
      counts[keyword] += 1;
      // The upstream loader does not consume texture coordinates. Keep source
      // counts for evidence but omit unused vt records from the adapter OBJ.
      if (keyword !== "vt") {
        output.push(line);
      }
      continue;
    }

    if (keyword === "f") {
      if (values.length < 3) {
        throw new Error(`${sourcePath}: face has fewer than three vertices`);
      }
      counts.f += 1;
      output.push(`f ${values.map((face) => rewriteFace(face, offsets)).join(" ")}`);
      continue;
    }

    // ObjModel.fromString only permits v, vn, f, comments, and blank lines.
    // Preserve source metadata as comments so this adapter remains auditable.
    output.push(`# source ${line}`);
  }

  return { text: output.join("\n"), counts };
}

const positional = [];
let scale = 1.0;
for (const arg of process.argv.slice(2)) {
  const scaleMatch = arg.match(/^--scale=(.+)$/);
  if (scaleMatch) {
    scale = Number(scaleMatch[1]);
    if (!Number.isFinite(scale) || scale <= 0) {
      throw new Error(`--scale must be a finite positive number, got "${scaleMatch[1]}"`);
    }
    continue;
  }
  positional.push(arg);
}

const [metalPath, diamondPath, outputPath] = positional;
if (!metalPath || !diamondPath || !outputPath) {
  usage();
} else {
  const inputs = [metalPath, diamondPath].map((file) => path.resolve(file));
  const output = path.resolve(outputPath);
  if (inputs.includes(output)) {
    throw new Error("Output path must differ from both source OBJ paths.");
  }

  const metal = mergeSource(inputs[0], "metal", { v: 0, vt: 0, vn: 0 }, scale);
  const diamond = mergeSource(inputs[1], "diamond", metal.counts, scale);
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, `${metal.text}\n${diamond.text}\n`, "utf8");

  console.log(JSON.stringify({
    output,
    scale,
    metal: metal.counts,
    diamond: diamond.counts,
  }, null, 2));
}
