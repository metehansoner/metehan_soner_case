package tests;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import utils.Driver;

public class BaseTest {

    @Parameters("browser")
    @BeforeMethod
    public void setUp(@Optional("chrome") String browser) {
        Driver.setDriver(browser);
        Driver.getDriver();
    }

    @AfterMethod
    public void tearDown() {
        Driver.closeDriver();
    }
}
