import { test, expect } from '@playwright/test';

// Helper to register a new unique user and log them in
async function registerAndLogin(page) {
  await page.click('text=Sign Up');
  const email = `user_${Date.now()}_${Math.floor(Math.random() * 1000)}@travel.com`;
  await page.getByPlaceholder('Enter your name').fill('QA Tester');
  await page.getByPlaceholder('name@example.com').fill(email);
  await page.getByPlaceholder('••••••••').fill('SecurePassword123!');
  await page.click('button[type="submit"]');
  
  // Set timeout to 90s to allow Render free tier backend to spin up
  await expect(page.locator('text=Plan a New Journey')).toBeVisible({ timeout: 90000 });
}

test.describe('Smart Travel Planner Web E2E Flows', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('TC-WEB-001 & TC-WEB-004: Should perform user registration and login successfully', async ({ page }) => {
    await registerAndLogin(page);

    // Test logout using specific button selector
    await page.click('button:has-text("Log Out")');
    
    // Assert redirect back to auth screen (either Login or Create Account page)
    await expect(page.locator('text=Create Account').or(page.locator('text=Welcome Back!'))).toBeVisible({ timeout: 10000 });
  });

  test('TC-WEB-002: Should verify form validation for empty fields', async ({ page }) => {
    // Submit empty fields
    await page.click('button[type="submit"]');
    
    // The browser native validations will trigger, preventing submission.
    // We should still be on the login page.
    await expect(page.locator('text=Welcome Back!')).toBeVisible();
  });

  test('TC-WEB-007: Should display dashboard statistics and structure', async ({ page }) => {
    await registerAndLogin(page);

    // Check dashboard elements
    await expect(page.locator('text=Plan a New Journey')).toBeVisible();
    await expect(page.locator('text=Popular Searches')).toBeVisible();
  });

  test('TC-WEB-011: Should allow trip planning and budget optimization', async ({ page }) => {
    await registerAndLogin(page);

    // Navigate to Planner tab
    await page.click('text=Trip Planner');

    // Select Destination and inputs
    await page.fill('input[type="date"] >> nth=0', '2026-06-01');
    await page.fill('input[type="date"] >> nth=1', '2026-06-05');
    await page.fill('input[type="number"] >> nth=0', '2'); // Travelers
    await page.fill('input[type="number"] >> nth=1', '35000'); // Budget

    // Submit optimization request
    await page.click('button[type="submit"]');

    // Verify recommendations show up (matching exact 'Optimisation Found' string in UI)
    await expect(page.locator('text=Optimisation Found')).toBeVisible({ timeout: 10000 });
  });
});
