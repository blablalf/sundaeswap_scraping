const puppeteer = require('puppeteer');
(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.setViewport({ width: 1400, height: 1080}); // We want a big page to be able to see every assets
  await page.goto('https://exchange.sundaeswap.finance'); // Wait until page is fully loaded
  await page.evaluate(() => {
    
  });
  await page.evaluate(scrollBottom);
  await page.evaluate(scrollBottom);
  await page.evaluate(scrollBottom);
  await page.evaluate(scrollBottom);
  await page.evaluate(scrollBottom);
  await page.evaluate(scrollBottom);


  await page.waitForTimeout(5000);


  console.log(await page.content()); // out the content
  await browser.close();
})();

function scrollBottom() {
  window.scrollTo(0, window.document.body.scrollHeight);
}