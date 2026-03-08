package tests;

import org.testng.Assert;
import org.testng.annotations.Test;
import pages.HomePage;
import pages.QACareersPage;
import utils.Driver;

public class InsiderTest extends BaseTest {

    @Test
    public void testInsiderOneCareersPage() throws InterruptedException {
        // Visit careers page
        Driver.getDriver().get("https://insiderone.com/careers/");
        
        // Verify page loaded
        Assert.assertTrue(Driver.getDriver().getCurrentUrl().contains("insiderone.com/careers"));
        Assert.assertTrue(Driver.getDriver().getTitle().contains("Insider One"));
        
        HomePage homePage = new HomePage();
        
        // Accept cookies
        homePage.acceptCookies();
        
        // Verify cookies accepted (banner should be hidden or removed)
        Assert.assertTrue(homePage.isCookieBannerHandled());
        
        // Click scroll to open roles button
        homePage.clickScrollToOpenRoles();
        
        // Verify URL
        Assert.assertEquals(Driver.getDriver().getCurrentUrl(), 
            "https://insiderone.com/careers/#open-roles");
        
        // Verify body classes
        Assert.assertTrue(homePage.hasBodyClasses("scrolled", "nav-active"));
        
        // Verify navigation is colored
        Assert.assertTrue(homePage.isNavigationColored());
        
        // Click see more button
        homePage.clickSeeMoreButton();
        
        // Verify see more div is open
        Assert.assertTrue(homePage.isSeeMoreDivOpen());
        
        // Verify see more button shows "See Less" and is expanded
        Assert.assertTrue(homePage.isSeeMoreButtonExpanded());
        
        // Click QA jobs link
        homePage.clickQAJobsLink();
        
        // Wait for navigation or new window
        Thread.sleep(2000);
        
        // Check if new window opened, if so switch to it
        String originalWindow = Driver.getDriver().getWindowHandle();
        if (Driver.getDriver().getWindowHandles().size() > 1) {
            for (String windowHandle : Driver.getDriver().getWindowHandles()) {
                if (!windowHandle.equals(originalWindow)) {
                    Driver.getDriver().switchTo().window(windowHandle);
                    break;
                }
            }
        }
        
        // Verify URL and title
        Assert.assertTrue(Driver.getDriver().getCurrentUrl().contains("jobs.lever.co/insiderone"),
            "Expected to be on Lever.co jobs page but was on: " + Driver.getDriver().getCurrentUrl());
        Assert.assertEquals(Driver.getDriver().getTitle(), "Insider One");
        
        QACareersPage qaCareersPage = new QACareersPage();
        
        // Accept cookies if present
        qaCareersPage.acceptCookiesIfPresent();
        
        // Click location filter
        qaCareersPage.clickLocationFilter();
        
        // Verify location filter is expanded
        Assert.assertTrue(qaCareersPage.isLocationFilterExpanded());
        Assert.assertTrue(qaCareersPage.isLocationFilterPopupVisible());
        
        // Select Istanbul location
        qaCareersPage.selectIstanbulLocation();
        
        // Wait for page to update
        Thread.sleep(2000);
        
        // Verify Istanbul location is selected
        String currentUrl = Driver.getDriver().getCurrentUrl();
        Assert.assertTrue(currentUrl.contains("jobs.lever.co/insiderone"), 
            "URL should contain jobs.lever.co/insiderone but was: " + currentUrl);
        Assert.assertTrue(currentUrl.contains("location=Istanbul%2C%20Turkiye"), 
            "URL should contain Istanbul location but was: " + currentUrl);
        Assert.assertTrue(qaCareersPage.isLocationFilterShowingIstanbul());
        
        // Close team filter if open (deselect Quality Assurance filter)
        qaCareersPage.closeTeamFilterIfOpen();
        
        // Wait for filter to close
        Thread.sleep(1000);
        
        // Get job postings count and iterate through them
        int jobCount = qaCareersPage.getJobPostingsCount();
        
        // Verify there are job postings
        Assert.assertTrue(jobCount > 0, "No job postings found for QA in Istanbul");
        
        for (int i = 0; i < jobCount; i++) {
            // Click job posting
            qaCareersPage.clickJobPosting(i);
            
            // Verify URL contains lever.co
            Assert.assertTrue(qaCareersPage.isUrlContaining("lever.co"));
            
            // Verify location
            Assert.assertTrue(qaCareersPage.isLocationCorrect("Istanbul, Turkiye"));
            
            // Verify department
            Assert.assertTrue(qaCareersPage.isDepartmentCorrect("Quality Assurance /"));
            
            // Verify workplace type
            Assert.assertTrue(qaCareersPage.isWorkplaceTypeCorrect("Remote"));
            
            // Go back
            Driver.getDriver().navigate().back();
            Thread.sleep(1000);
            
            // Verify returned to job listings page
            Assert.assertTrue(Driver.getDriver().getCurrentUrl().contains("jobs.lever.co/insiderone"), 
                "Failed to return to job listings page");
        }
    }
}
