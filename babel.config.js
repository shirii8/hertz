module.exports = function (api) {
  api.cache(true);
  return {
    presets: [
      ["babel-preset-expo", { jjsxImportSource: "nativewind" }],
      "nativewind/babel",
    ],
  };
};
