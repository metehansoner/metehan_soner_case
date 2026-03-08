package pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.FindBy;
import java.util.List;

public class QACareersPage extends BasePage {

    @FindBy(css = "div.cc-desktop button.button")
    private WebElement cookieAcceptButton;

    @FindBy(css = "div[aria-label='Filter by Location: All'] div.filter-button")
    private WebElement locationFilterButton;

    @FindBy(css = "div[aria-label='Filter by Location: All']")
    private WebElement locationFilterContainer;

    @FindBy(css = "div[aria-label='Filter by Location: All'] div.filter-popup")
    private WebElement locationFilterPopup;

    @FindBy(css = "a[href='?team=Quality%20Assurance&location=Istanbul%2C%20Turkiye']")
    private WebElement istanbulLocationLink;

    @FindBy(css = "div[aria-label='Filter by Location: Istanbul, Turkiye'] div.filter-button")
    private WebElement selectedLocationButton;

    @FindBy(css = "div[aria-label='Filter by Team: Quality Assurance'] div.filter-button svg.icon")
    private WebElement teamFilterIcon;

    @FindBy(css = "div[aria-label='Filter by Team: Quality Assurance']")
    private WebElement teamFilterContainer;

    @FindBy(css = "li:nth-child(11) a.selected")
    private WebElement selectedTeamLink;

    @FindBy(css = "div[aria-label='Filter by Team: Quality Assurance'] div.filter-popup")
    private WebElement teamFilterPopup;

    @FindBy(css = ".posting")
    private List<WebElement> jobPostings;

    @FindBy(css = ".posting-title")
    private List<WebElement> jobTitles;

    public void acceptCookiesIfPresent() {
        try {
            if (cookieAcceptButton.isDisplayed()) {
                click(cookieAcceptButton);
                Thread.sleep(500);
            }
        } catch (Exception e) {
            // Cookie banner may not appear
        }
    }

    public void clickLocationFilter() throws InterruptedException {
        waitForClickability(locationFilterButton);
        click(locationFilterButton);
        Thread.sleep(500);
    }

    public boolean isLocationFilterExpanded() {
        return "true".equals(locationFilterContainer.getAttribute("aria-expanded"));
    }

    public boolean isLocationFilterPopupVisible() {
        return locationFilterPopup.isDisplayed();
    }

    public void selectIstanbulLocation() throws InterruptedException {
        waitForClickability(istanbulLocationLink);
        click(istanbulLocationLink);
        Thread.sleep(1000);
    }

    public boolean isUrlCorrect(String expectedUrl) {
        return driver.getCurrentUrl().equals(expectedUrl);
    }

    public boolean isLocationFilterShowingIstanbul() {
        return selectedLocationButton.getText().contains("Istanbul, Turkiye");
    }

    public String getLocationFilterText() {
        try {
            return selectedLocationButton.getText();
        } catch (Exception e) {
            return "Element not found: " + e.getMessage();
        }
    }

    public void closeTeamFilterIfOpen() {
        try {
            // Check if team filter is expanded
            if ("true".equals(teamFilterContainer.getAttribute("aria-expanded"))) {
                // Click filter button to close it
                click(teamFilterIcon);
                Thread.sleep(500);
            }
        } catch (Exception e) {
            // Team filter may not be present or already closed, continue
        }
    }

    public int getJobPostingsCount() {
        return jobPostings.size();
    }

    public void clickJobPosting(int index) throws InterruptedException {
        WebElement jobTitle = jobTitles.get(index);
        waitForClickability(jobTitle);
        click(jobTitle);
        Thread.sleep(1000);
    }

    public boolean isUrlContaining(String urlPart) {
        return driver.getCurrentUrl().contains(urlPart);
    }

    public boolean isLocationCorrect(String expectedLocation) {
        try {
            WebElement location = driver.findElement(By.cssSelector("div.location"));
            return location.getText().contains(expectedLocation);
        } catch (Exception e) {
            return false;
        }
    }

    public boolean isDepartmentCorrect(String expectedDepartment) {
        try {
            WebElement department = driver.findElement(By.cssSelector("div.department"));
            return department.getText().contains(expectedDepartment);
        } catch (Exception e) {
            return false;
        }
    }

    public boolean isWorkplaceTypeCorrect(String expectedType) {
        try {
            WebElement workplaceType = driver.findElement(By.cssSelector("div.workplaceTypes"));
            return workplaceType.getText().contains(expectedType);
        } catch (Exception e) {
            return false;
        }
    }

    public boolean isTeamFilterExpanded() {
        try {
            return "true".equals(teamFilterContainer.getAttribute("aria-expanded"));
        } catch (Exception e) {
            return false;
        }
    }
}
