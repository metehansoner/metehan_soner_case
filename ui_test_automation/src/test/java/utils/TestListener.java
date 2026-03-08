package utils;

import org.openqa.selenium.OutputType;
import org.openqa.selenium.TakesScreenshot;
import org.testng.ITestListener;
import org.testng.ITestResult;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

public class TestListener implements ITestListener {
    @Override
    public void onTestFailure(ITestResult result) {
        try {
            TakesScreenshot ts = (TakesScreenshot) Driver.getDriver();
            File source = ts.getScreenshotAs(OutputType.FILE);
            String timestamp = String.valueOf(System.currentTimeMillis());
            File target = new File("screenshots/" + result.getName() + "_" + timestamp + ".png");
            if (!target.getParentFile().exists()) {
                target.getParentFile().mkdirs();
            }
            Files.copy(source.toPath(), target.toPath());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
