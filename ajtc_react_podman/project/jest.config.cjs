module.exports = {
  testEnvironment: "jsdom",
  transform: {
    "^.+\\.[jt]sx?$": ["@swc/jest"]
  },
  moduleFileExtensions: ["js", "jsx"],
  setupFilesAfterEnv: ["@testing-library/jest-dom"],
  testMatch: ["<rootDir>/tests/**/*.test.jsx"],
  reporters: [
    'default',
    '<rootDir>/jest-summary-reporter.cjs'
  ],
  testTimeout: 10000, // 10 seconds (in milliseconds)

};
