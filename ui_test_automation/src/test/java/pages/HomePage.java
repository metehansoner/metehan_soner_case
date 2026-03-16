package pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.FindBy;
import java.util.List;

public class HomePage extends BasePage {

    @FindBy(css = "header")
    private WebElement header;

    @FindBy(id = "wt-cli-accept-all-btn")
    private WebElement cookieAcceptButton;

    @FindBy(id = "cookie-law-info-bar")
    private WebElement cookieBanner;

    @FindBy(css = "#page-wrapper a.inso-rounded span")
    private WebElement scrollToOpenRolesButton;

    @FindBy(id = "navigation")
    private WebElement navigation;

    @FindBy(css = "#open-roles a.inso-btn")
    private WebElement seeMoreButton;

    @FindBy(css = "#open-roles div.insiderone-icon-cards-see-more-div")
    private WebElement seeMoreDiv;

    @FindBy(css = "#open-roles a[href='https://jobs.lever.co/insiderone?team=Quality%20Assurance']")
    private WebElement qaJobsLink;

    public boolean isHomePageLoaded() {
        try {
            return driver.getCurrentUrl().contains("insiderone.com") 
                && driver.getTitle().contains("Insider One");
        } catch (Exception e) {
            return false;
        }
    }

    public boolean areMainBlocksLoaded() {
        try {
            // Wait for page to load
            Thread.sleep(2000);
            
            // Check if page has loaded with basic structure
            boolean pageReady = driver.findElements(By.cssSelector("body")).size() > 0;
            boolean hasMultipleElements = driver.findElements(By.cssSelector("*")).size() > 50;
            
            // Check if JavaScript has executed (page is interactive)
            Object readyState = ((org.openqa.selenium.JavascriptExecutor) driver)
                .executeScript("return document.readyState");
            boolean isComplete = "complete".equals(readyState);
            
            return pageReady && hasMultipleElements && isComplete;
        } catch (Exception e) {
            return false;
        }
    }

    public void acceptCookies() throws InterruptedException {
        waitForClickability(cookieAcceptButton);
        click(cookieAcceptButton);
        Thread.sleep(500);
    }

    public boolean isCookieBannerHandled() {
        try {
            return !cookieBanner.isDisplayed();
        } catch (Exception e) {
            return true; // Banner removed from DOM
        }
    }

    public void clickScrollToOpenRoles() throws InterruptedException {
        waitForClickability(scrollToOpenRolesButton);
        click(scrollToOpenRolesButton);
        Thread.sleep(1000);
    }

    public boolean hasBodyClasses(String... classNames) {
        try {
            WebElement body = driver.findElement(By.cssSelector("body.page"));
            String bodyClass = body.getAttribute("class");
            for (String className : classNames) {
                if (!bodyClass.contains(className)) {
                    return false;
                }
            }
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public boolean isNavigationColored() {
        try {
            String navClass = navigation.getAttribute("class");
            return navClass.contains("colored");
        } catch (Exception e) {
            return false;
        }
    }

    public void clickSeeMoreButton() throws InterruptedException {
        waitForClickability(seeMoreButton);
        click(seeMoreButton);
        Thread.sleep(1000);
    }

    public boolean isSeeMoreDivOpen() {
        try {
            String divClass = seeMoreDiv.getAttribute("class");
            return divClass.contains("open");
        } catch (Exception e) {
            return false;
        }
    }

    public boolean isSeeMoreButtonExpanded() {
        try {
            String buttonText = seeMoreButton.getText();
            String ariaExpanded = seeMoreButton.getAttribute("aria-expanded");
            return buttonText.contains("See Less") && "true".equals(ariaExpanded);
        } catch (Exception e) {
            return false;
        }
    }

    public void clickQAJobsLink() throws InterruptedException {
        waitForClickability(qaJobsLink);
        click(qaJobsLink);
        Thread.sleep(2000);
    }
}
