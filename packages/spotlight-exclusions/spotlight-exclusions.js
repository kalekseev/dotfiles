// Use the private API used by System Settings. Verify changes so macOS API
// changes fail visibly.
ObjC.import("CoreServices");
ObjC.bindFunction("_MDCopyExclusionList", ["id", []]);
ObjC.bindFunction("_MDSetExclusion", ["int", ["id", "unsigned char"]]);

function exclusions() {
  const paths = ObjC.deepUnwrap($._MDCopyExclusionList());
  if (!Array.isArray(paths)) {
    throw new Error("Could not read Spotlight Search Privacy exclusions");
  }
  return paths;
}

function run(paths) {
  for (const path of paths) {
    if (exclusions().includes(path)) continue;

    const status = $._MDSetExclusion($(path), 1);
    if (status !== 0) {
      throw new Error("Could not exclude " + path + " from Spotlight: " + status);
    }
    if (!exclusions().includes(path)) {
      throw new Error("Spotlight did not retain the exclusion for " + path);
    }
    console.log("Excluded from Spotlight: " + path);
  }
}
