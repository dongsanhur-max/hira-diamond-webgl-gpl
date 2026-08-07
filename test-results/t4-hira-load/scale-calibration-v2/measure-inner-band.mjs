import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

const [hiraPath, upstreamPath] = process.argv.slice(2);
if (!hiraPath || !upstreamPath) {
  console.error("Usage: node measure-inner-band.mjs <hira-metal.obj> <upstream.obj>");
  process.exit(1);
}

function parseObj(filePath) {
  const text = fs.readFileSync(filePath, "utf8");
  const vertices = [];
  const normals = [];
  const corners = [];

  for (const line of text.split(/\r?\n/)) {
    const [keyword, ...values] = line.trim().split(/\s+/);
    if (keyword === "v") vertices.push(values.map(Number));
    if (keyword === "vn") normals.push(values.map(Number));
    if (keyword === "f") {
      for (const value of values) {
        const [vertex, , normal] = value.split("/").map(Number);
        if (vertex > 0 && normal > 0) corners.push([vertex - 1, normal - 1]);
      }
    }
  }

  return {
    file: path.resolve(filePath),
    sha256: crypto.createHash("sha256").update(text).digest("hex"),
    vertices,
    normals,
    corners,
  };
}

function solve3(matrix, vector) {
  const rows = matrix.map((row, index) => [...row, vector[index]]);
  for (let column = 0; column < 3; column += 1) {
    let pivot = column;
    for (let row = column + 1; row < 3; row += 1) {
      if (Math.abs(rows[row][column]) > Math.abs(rows[pivot][column])) pivot = row;
    }
    [rows[column], rows[pivot]] = [rows[pivot], rows[column]];
    const divisor = rows[column][column];
    if (Math.abs(divisor) < 1e-12) throw new Error("Circle fit is singular.");
    for (let i = column; i < 4; i += 1) rows[column][i] /= divisor;
    for (let row = 0; row < 3; row += 1) {
      if (row === column) continue;
      const factor = rows[row][column];
      for (let i = column; i < 4; i += 1) rows[row][i] -= factor * rows[column][i];
    }
  }
  return rows.map((row) => row[3]);
}

function fitCircle(points) {
  const matrix = Array.from({ length: 3 }, () => [0, 0, 0]);
  const vector = [0, 0, 0];
  for (const [x, z] of points) {
    const row = [x, z, 1];
    const target = -(x * x + z * z);
    for (let i = 0; i < 3; i += 1) {
      vector[i] += row[i] * target;
      for (let j = 0; j < 3; j += 1) matrix[i][j] += row[i] * row[j];
    }
  }
  const [d, e, f] = solve3(matrix, vector);
  const centerX = -d / 2;
  const centerZ = -e / 2;
  const radius = Math.sqrt(centerX ** 2 + centerZ ** 2 - f);
  const residuals = points.map(([x, z]) => Math.hypot(x - centerX, z - centerZ) - radius);
  const rmse = Math.sqrt(residuals.reduce((sum, value) => sum + value ** 2, 0) / residuals.length);
  return { centerX, centerZ, radius, diameter: radius * 2, rmse };
}

function measureInnerBand(model) {
  const axes = [0, 1, 2].map((axis) => model.vertices.map((vertex) => vertex[axis]));
  const min = axes.map((values) => Math.min(...values));
  const max = axes.map((values) => Math.max(...values));
  const span = max.map((value, axis) => value - min[axis]);
  const preliminaryCenter = {
    x: (min[0] + max[0]) / 2,
    y: (min[1] + max[1]) / 2,
    z: min[2] + span[0] / 2,
  };
  const centerSliceTolerance = span[1] * 0.01;
  const selected = [];
  const selectedVertices = new Set();

  for (const [vertexIndex, normalIndex] of model.corners) {
    if (selectedVertices.has(vertexIndex)) continue;
    const vertex = model.vertices[vertexIndex];
    const normal = model.normals[normalIndex];
    if (!vertex || !normal || vertex[2] > preliminaryCenter.z) continue;
    if (Math.abs(vertex[1] - preliminaryCenter.y) > centerSliceTolerance) continue;
    const radialX = vertex[0] - preliminaryCenter.x;
    const radialZ = vertex[2] - preliminaryCenter.z;
    const radialLength = Math.hypot(radialX, radialZ);
    const normalLength = Math.hypot(normal[0], normal[2]);
    if (!radialLength || !normalLength) continue;
    const radialNormalDot =
      (normal[0] * radialX + normal[2] * radialZ) / (normalLength * radialLength);
    if (radialNormalDot < -0.7) {
      selectedVertices.add(vertexIndex);
      selected.push([vertex[0], vertex[2]]);
    }
  }

  if (selected.length < 12) throw new Error(`Too few inner-band points: ${selected.length}`);
  return {
    bounds: { min, max, span },
    preliminaryCenter,
    centerSliceTolerance,
    innerNormalDotThreshold: -0.7,
    selectedPointCount: selected.length,
    circleFit: fitCircle(selected),
  };
}

const knownHiraInnerDiameterMm = 15;
const hira = parseObj(hiraPath);
const upstream = parseObj(upstreamPath);
const hiraMeasurement = measureInnerBand(hira);
const upstreamMeasurement = measureInnerBand(upstream);
const scaleEngineUnitsPerMm = upstreamMeasurement.circleFit.diameter / knownHiraInnerDiameterMm;
const hiraDeviationPercent =
  ((hiraMeasurement.circleFit.diameter - knownHiraInnerDiameterMm) / knownHiraInnerDiameterMm) * 100;

console.log(JSON.stringify({
  method: "x-z lower-shank, center 1% y-slice, inward normal dot < -0.7, algebraic circle fit",
  knownHiraInnerDiameterMm,
  hiraCrossCheck: {
    file: hira.file,
    sha256: hira.sha256,
    ...hiraMeasurement,
    deviationFromKnownPercent: hiraDeviationPercent,
    withinOnePercent: Math.abs(hiraDeviationPercent) <= 1,
  },
  upstreamReference: {
    file: upstream.file,
    sha256: upstream.sha256,
    ...upstreamMeasurement,
  },
  conversion: {
    formula: "upstreamInnerDiameterEngineUnits / knownHiraInnerDiameterMm",
    scaleEngineUnitsPerMm,
    inverseMmPerEngineUnit: 1 / scaleEngineUnitsPerMm,
    predictedScaledHiraMeasuredDiameter:
      hiraMeasurement.circleFit.diameter * scaleEngineUnitsPerMm,
  },
}, null, 2));
