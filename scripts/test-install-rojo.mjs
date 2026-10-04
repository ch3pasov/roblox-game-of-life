import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, statSync, rmSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const installer = fileURLToPath(new URL("./install-rojo.sh", import.meta.url));
const digest = "00feb4fa0829a1dd72b49df2639da519a352bfe13cadcd83969e2ba2bb5693c4";
const url = "https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-linux-x86_64.zip";

function execute(mode) {
  const root = mkdtempSync(path.join(os.tmpdir(), "rojo installer test "));
  try {
    const bin = path.join(root, "bin"), runner = path.join(root, "runner");
    const githubPath = path.join(root, "github-path"), trace = path.join(root, "trace");
    mkdirSync(bin); mkdirSync(runner);
    writeFileSync(githubPath, "/existing/tool\n");
    const stub = `#!${process.execPath}
      const fs = require('node:fs'), path = require('node:path');
      const name = path.basename(process.argv[1]), args = process.argv.slice(2);
      const input = name === 'sha256sum' ? fs.readFileSync(0, 'utf8') : null;
      fs.appendFileSync(process.env.TEST_TRACE, JSON.stringify({name, args, input}) + '\\n');
      if (name === 'curl') {
        if (process.env.TEST_MODE === 'download-error') process.exit(22);
        fs.writeFileSync(args[args.indexOf('--output') + 1], 'synthetic archive bytes');
      } else if (name === 'unzip') {
        if (process.env.TEST_MODE === 'extract-error') process.exit(9);
        if (process.env.TEST_MODE !== 'missing-binary') {
          fs.writeFileSync(path.join(args[args.indexOf('-d') + 1], 'rojo'), 'not an executable fixture');
        }
      }
    `;
    for (const command of ["curl", "unzip", ...(mode === "checksum-mismatch" ? [] : ["sha256sum"])]) {
      writeFileSync(path.join(bin, command), stub, { mode: 0o755 });
    }
    const env = {
      PATH: bin + ":/usr/bin:/bin", RUNNER_TEMP: runner, GITHUB_PATH: githubPath,
      TEST_TRACE: trace, TEST_MODE: mode,
    };
    if (mode === "missing-runner") delete env.RUNNER_TEMP;
    if (mode === "missing-path") delete env.GITHUB_PATH;
    const result = spawnSync("/bin/bash", [installer], { cwd: root, env, encoding: "utf8", timeout: 5000 });
    const calls = existsSync(trace) ? readFileSync(trace, "utf8").trim().split("\n").map(JSON.parse) : [];
    const contents = readFileSync(githubPath, "utf8");
    const installed = contents.trim().split("\n")[1];
    const executable = installed && existsSync(path.join(installed, "rojo")) &&
      Boolean(statSync(path.join(installed, "rojo")).mode & 0o111);
    return { result, calls, contents, executable, installed };
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

test("downloads the pinned asset, checks its digest before extraction, then appends the usable path", () => {
  const { result, calls, contents, executable, installed } = execute("success");
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(calls.map(call => call.name), ["curl", "sha256sum", "unzip"]);
  assert(calls[0].args.includes(url));
  assert(calls[0].args.includes("--fail"));
  const archive = calls[0].args[calls[0].args.indexOf("--output") + 1];
  assert.deepEqual(calls[1].args, ["--check", "--status"]);
  assert.equal(calls[1].input, digest + "  " + archive + "\n");
  assert(calls[2].args.includes(archive));
  assert.equal(contents, "/existing/tool\n" + installed + "\n");
  assert.equal(executable, true);
});

test("an HTTP/download error stops before checksum, extraction, or path updates", () => {
  const { result, calls, contents } = execute("download-error");
  assert.equal(result.status, 22);
  assert.deepEqual(calls.map(call => call.name), ["curl"]);
  assert.equal(contents, "/existing/tool\n");
});

test("the real checksum tool rejects tampered bytes before unzip and leaves PATH untouched", () => {
  const { result, calls, contents } = execute("checksum-mismatch");
  assert.equal(result.status, 1, result.stderr);
  assert.match(result.stderr, /failed SHA-256 verification/);
  assert.deepEqual(calls.map(call => call.name), ["curl"]);
  assert.equal(contents, "/existing/tool\n");
});

for (const mode of ["extract-error", "missing-binary"]) {
  test(`${mode} fails without publishing an unusable runner path`, () => {
    const { result, calls, contents } = execute(mode);
    assert.notEqual(result.status, 0);
    assert.deepEqual(calls.map(call => call.name), ["curl", "sha256sum", "unzip"]);
    assert.equal(contents, "/existing/tool\n");
  });
}

for (const mode of ["missing-runner", "missing-path"]) {
  test(`${mode} fails before any download or extraction`, () => {
    const { result, calls, contents } = execute(mode);
    assert.notEqual(result.status, 0);
    assert.deepEqual(calls, []);
    assert.equal(contents, "/existing/tool\n");
  });
}
