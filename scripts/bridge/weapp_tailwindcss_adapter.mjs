import fs from "node:fs";
import path from "node:path";
import postcss from "postcss";
import weappTailwindcssPostcssPlugin from "weapp-tailwindcss/postcss";
import { escape as escapeWeappClass } from "weapp-tailwindcss/escape";

const [rawCssFile, tailwindInput, sourceWxss, distDir, routesSource] = process.argv.slice(2);
if (!rawCssFile || !tailwindInput || !sourceWxss || !distDir || !routesSource) {
  throw new Error(
    "usage: adapter <raw-css> <tailwind-input> <source-wxss> <dist-dir> <routes-json>",
  );
}

function transformWxml(source) {
  return source.replace(/class="([^"]*)"/g, (_match, value) => {
    const classes = value.split(/\s+/).filter(Boolean).map(escapeWeappClass).join(" ");
    return `class="${classes}"`;
  });
}

const escapeContract = [
  ["min-h-[100vh]", "min-h-_b100vh_B"],
  ["hover:bg-red-500", "hover_cbg-red-500"],
  ["w-1/2", "w-1_f2"],
  ["text-[#fff]", "text-_b_hfff_B"],
  ["-mt-[1.5px]", "-mt-_b1_d5px_B"],
  ["2xl:flex", "_2xl_cflex"],
  ["中", "u_x4e2d_"],
];
for (const [raw, expected] of escapeContract) {
  if (escapeWeappClass(raw) !== expected) {
    throw new Error(`weapp-tailwindcss class escape contract changed for ${raw}`);
  }
}

const rawCss = fs.readFileSync(rawCssFile, "utf8");
const result = await postcss([
  weappTailwindcssPostcssPlugin({ version: 4, cssEntries: [tailwindInput] }),
]).process(rawCss, { from: rawCssFile });
const wxss = `${result.css.trim()}\n`;
fs.mkdirSync(path.dirname(sourceWxss), { recursive: true });
fs.writeFileSync(sourceWxss, wxss);
fs.writeFileSync(path.join(distDir, "app.wxss"), wxss);

for (const route of JSON.parse(routesSource)) {
  const base = path.join(distDir, route);
  const wxml = `${base}.wxml`;
  if (fs.existsSync(wxml)) {
    const transformed = transformWxml(fs.readFileSync(wxml, "utf8")).trimEnd();
    fs.writeFileSync(wxml, `${transformed}\n`);
  }
}
