const puppeteer = require('puppeteer');
(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.goto('https://exchange.sundaeswap.finance', {waitUntil: 'networkidle0'}); // Wait until page is fully loaded
  console.log(await page.content()); // out the content
  await browser.close();
})();