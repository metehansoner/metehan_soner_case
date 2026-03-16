package utils;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.firefox.FirefoxDriver;
import org.openqa.selenium.firefox.FirefoxOptions;
import java.time.Duration;

public class Driver {
    private static ThreadLocal<WebDriver> driverPool = new ThreadLocal<>();

    private Driver() {
    }

    public static WebDriver getDriver() {
        if (driverPool.get() == null) {
            String browserParam = System.getProperty("browser") != null ? System.getProperty("browser")
                    : ConfigReader.get("browser");
            
            // Default to chrome if browser is null or empty
            if (browserParam == null || browserParam.trim().isEmpty()) {
                browserParam = "chrome";
            }
            
            switch (browserParam.toLowerCase()) {
                case "chrome":
                    ChromeOptions chromeOptions = new ChromeOptions();
                    chromeOptions.addArguments("--disable-notifications");
                    chromeOptions.addArguments("--start-maximized");
                    driverPool.set(new ChromeDriver(chromeOptions));
                    break;
                case "firefox":
                    FirefoxOptions firefoxOptions = new FirefoxOptions();
                    firefoxOptions.addArguments("--disable-notifications");
                    driverPool.set(new FirefoxDriver(firefoxOptions));
                    driverPool.get().manage().window().maximize();
                    break;
                default:
                    // Default to Chrome
                    ChromeOptions defaultChromeOptions = new ChromeOptions();
                    defaultChromeOptions.addArguments("--disable-notifications");
                    defaultChromeOptions.addArguments("--start-maximized");
                    driverPool.set(new ChromeDriver(defaultChromeOptions));
                    break;
            }
            driverPool.get().manage().timeouts().implicitlyWait(Duration.ofSeconds(10));
        }
        return driverPool.get();
    }

    public static void setDriver(String browser) {
        System.setProperty("browser", browser);
    }

    public static void closeDriver() {
        if (driverPool.get() != null) {
            driverPool.get().quit();
            driverPool.remove();
        }
    }
}
