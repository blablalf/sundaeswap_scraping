const puppeteer = require('puppeteer');
(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.evaluateOnNewDocument(() => {
    Object.defineProperty(navigator, "language", {
        get: function() {
            return "en-US";
        }
    });
    Object.defineProperty(navigator, "languages", {
        get: function() {
            return ["en-US", "en"];
        }
    });
  });
  await page.setViewport({ width: 1400, height: 1080}); // We want a big page to be able to see the most assets as possible
  await page.goto('https://exchange.sundaeswap.finance', {waitUntil: 'networkidle0'}); // Wait until page is fully loaded
  for (let i = 0; i < 4; i++) {
    await page.evaluate(scrollToBottom); // Scroll down to load more assets
    await page.waitForNetworkIdle(1); // Wait 1ms
  }
  await page.waitForNetworkIdle(1000); // Wait 1s (useful only to get the 24H volume)
  console.log(await page.content()); // out the content
  await browser.close();
})();

function scrollToBottom() {
  window.scrollTo(0, window.document.body.scrollHeight);
}