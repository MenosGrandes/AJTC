class SummaryReporter {
  onRunComplete(_, results) {
    console.log(`\nSummary | ${results.numPassedTests} | ${results.numFailedTests}`);
  }
}

module.exports = SummaryReporter;

