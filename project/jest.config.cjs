module.exports = {

  testMatch: ["<rootDir>/**/*.test.js"],
  reporters: [
    '<rootDir>/jest-summary-reporter.cjs'
  ],
  testTimeout: 10000, // 10 seconds (in milliseconds)

};
