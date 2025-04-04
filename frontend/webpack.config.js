module.exports = {
    module: {
      rules: [
        {
          test: /\.js$/,
          enforce: "pre",
          use: ["source-map-loader"],
          exclude: /node_modules/, // Exclude source map warnings from node_modules
        },
      ],
    },
  };
  